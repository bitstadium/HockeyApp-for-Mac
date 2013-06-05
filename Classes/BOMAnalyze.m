//
//  BOMAnalyze.m
//  HockeyMac
//
//  Created by Oliver Michalak on 05.06.13.
//
//

#import "BOMAnalyze.h"

@interface BOMAnalyze ()
@property (strong) NSMutableArray *exceptionList;
@property (assign) BOOL isCompleting;

- (void) analyze:(NSURL*) file;
@end

@implementation BOMAnalyze

@synthesize fixedSize;
@synthesize imageSize;
@synthesize savedImageSize;
@synthesize protocol;
@synthesize delegate;
@synthesize isRunning;
@synthesize exceptionList;

- (id) initWithFile:(NSURL*) file {
	if ((self = [super init])) {
		self.file = file;
		self.fixedSize = [NSNumber numberWithLong :0];
		self.imageSize = [NSNumber numberWithLong: 0];
		self.savedImageSize = [NSNumber numberWithLong: 0];
		self.protocol = [[NSMutableArray alloc] init];
		self.exceptionList = [@[@"Default-Landscape.png", @"Default-Landscape~iPad.png",
													 @"Default-Portrait.png", @"Default-Portrait~iPad.png",
													 @"Default.png", @"Default-568h.png",
													 @"Icon-72.png", @"Icon-Small-50.png", @"Icon-Small.png", @"Icon.png", @"iTunesArtwork.png"] mutableCopy];
		for (long index=exceptionList.count-1; index >=0; index--)
			[exceptionList addObject:[exceptionList[index] stringByReplacingOccurrencesOfString:@".png" withString:@"@2x.png"]];
	}
	return self;
}

- (void) start {
	if ([self.delegate respondsToSelector:@selector(analyzeStarted)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate analyzeStarted];
		});
	}
	self.isRunning = self.isCompleting = YES;

	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *file = [self.file copy];
	if ([self.file.path hasSuffix:@".ipa"]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate analyzeChanged: @"Decompressing IPA..."];
		});
		NSString *fileName = file.path.pathComponents.lastObject;
		file = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, NSProcessInfo.processInfo.globallyUniqueString]]];
		[fm removeItemAtPath: file.path error:nil];
		[fm createDirectoryAtPath:file.path withIntermediateDirectories:YES attributes:nil error:nil];

		NSTask *task = [[NSTask alloc] init];
		task.launchPath = @"/usr/bin/unzip";
		task.currentDirectoryPath = file.path;
		task.arguments = @[@"-o", @"-qq", self.file.path];
		[task launch];
		[task waitUntilExit];	// we are alrady in background
	}

	// find Info.plist
	NSDirectoryEnumerator *infoFileEnumerator = [fm enumeratorAtPath: file.path];
	NSString *info = nil;
	while (info = [infoFileEnumerator nextObject]) {
    if ([info.pathExtension isEqualToString: @"app"])
			break;
	}
	if (info) {
		NSString *infoFileName = [file.path stringByAppendingPathComponent: info];
		if ([self.file.path hasSuffix:@".xcarchive"])
			infoFileName = [infoFileName stringByAppendingPathComponent:@"Contents"];
		infoFileName = [infoFileName stringByAppendingPathComponent: @"Info.plist"];
		NSData *infoData = [NSData dataWithContentsOfFile: infoFileName];
		if (infoData) {
			NSDictionary *infoDict = [NSPropertyListSerialization propertyListFromData:infoData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			NSArray *defaultIconNames = infoDict[@"CFBundleIconFiles"];
			if (defaultIconNames.count)
				[self.exceptionList addObjectsFromArray: defaultIconNames];
		}
	}

	NSArray *fileList = [fm contentsOfDirectoryAtPath:file.path error:nil];
	for (NSString *fileItem in fileList)
		[self analyze: [NSURL fileURLWithPath: [file.path stringByAppendingPathComponent:fileItem]]];

	if ([self.file.path hasSuffix:@".ipa"])
		[fm removeItemAtPath: file.path error:nil];

	self.isRunning = NO;
	if ([self.delegate respondsToSelector:@selector(analyzeFinished:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate analyzeFinished:self.isCompleting];
		});
	}
}

- (void) stop {
	self.isCompleting = NO;
}

- (void) analyze:(NSURL*) file {
	if (!self.isCompleting)
		return;
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if ([fm fileExistsAtPath:file.path isDirectory:&isDir] && isDir) {
		NSArray *fileList = [fm contentsOfDirectoryAtPath:file.path error:nil];
		for (NSString *fileItem in fileList)
			[self analyze: [NSURL fileURLWithPath: [file.path stringByAppendingPathComponent:fileItem]]];
	}
	else {
		@autoreleasepool {
			NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
			formatter.allowsNonnumericFormatting = NO;
			NSFileManager *fm = [NSFileManager defaultManager];
			NSArray *fileComponent = file.path.pathComponents;
			NSString *objectName = fileComponent.lastObject;
			NSDictionary *fileDict = [fm attributesOfItemAtPath:file.path error:nil];
			long objectSize = [fileDict[NSFileSize] longValue];
			if ([objectName hasSuffix:@".png"] || [objectName hasSuffix:@".jpg"])
				self.imageSize = [NSNumber numberWithLong: self.imageSize.longValue + objectSize];
			else
				self.fixedSize = [NSNumber numberWithLong: self.fixedSize.longValue + objectSize];
			// only PNGs above 1K
			if ([objectName hasSuffix:@".png"] && objectSize > 1024) {
				NSImage *image = [[NSImage alloc] initWithContentsOfFile:file.path];
				if (image) {
					NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithContentsOfFile: file.path];
					BOOL opaque = YES;
					for (int col=0; col<image.size.width; col++) {	// slow
						for (int row=0; row<image.size.height; row++) {
							NSColor *color = [imageRep colorAtX:col y:row];
							if (color.alphaComponent < 1.0) {
								opaque = NO;
								break;
							}
						}
					}
					if (opaque && ![self.exceptionList containsObject: objectName]) {	// try 90% JPG instead...
						NSData *jpgData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
						long diff = objectSize - jpgData.length;
						if (diff > 0) {
							self.savedImageSize = [NSNumber numberWithLong: self.savedImageSize.longValue + diff];
							[self.protocol addObject: [BOMProtocol protocolWithFile:file ofType:BOMProtocolPNGtoJPG originalSize:[NSNumber numberWithLong: objectSize] savedSize:[NSNumber numberWithLong: diff] data:jpgData]];
						}
					}
					else {	// requantisize PNG
						NSURL *tempFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:objectName]];
						[fm removeItemAtPath:tempFile.path error:nil];
						[fm copyItemAtPath:file.path toPath:tempFile.path error:nil];
						NSURL *tempOptimizedFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [objectName stringByReplacingOccurrencesOfString:@".png" withString:@"X.png"]]];
						[fm removeItemAtPath: tempOptimizedFile.path error:nil];

						NSTask *task = [[NSTask alloc] init];
						task.launchPath = [NSString stringWithFormat:@"%@/pngquant", [[NSBundle mainBundle] resourcePath]];
						task.currentDirectoryPath = NSTemporaryDirectory();
						task.arguments = @[@"--ext", @"X.png", @"--force", @"--quality", @"90-100", tempFile.path];
						[task launch];
						[task waitUntilExit];

						NSDictionary *fileDict = [fm attributesOfItemAtPath:tempOptimizedFile.path error:nil];
						NSNumber *optimizedSize = fileDict[NSFileSize];
						long diff = objectSize - optimizedSize.longValue;
						if (diff > 0 && optimizedSize.longValue > 0) {
							self.savedImageSize = [NSNumber numberWithLong: self.savedImageSize.longValue + diff];
							[self.protocol addObject: [BOMProtocol protocolWithFile:tempFile ofType:BOMProtocolOptimizedPNG originalSize:[NSNumber numberWithLong: objectSize] savedSize: [NSNumber numberWithLong: diff] data: [NSData dataWithContentsOfFile:tempOptimizedFile.path]]];
						}
						[fm removeItemAtPath:tempFile.path error:nil];
						[fm removeItemAtPath:tempOptimizedFile.path error:nil];
					}
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate analyzeChanged: objectName];
					});
				}
			}
			// JPG above 1K
			else if ([objectName hasSuffix:@".jpg"] && objectSize > 1024) {
				// try to recompress to 90%
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithContentsOfFile: file.path];
				NSData *jpgData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
				long diff = objectSize - jpgData.length;
				if (diff > 0) {
					self.savedImageSize = [NSNumber numberWithLong: self.savedImageSize.longValue + diff];
					[self.protocol addObject: [BOMProtocol protocolWithFile:file ofType:BOMProtocolOptimizedJPG	originalSize:[NSNumber numberWithLong: objectSize] savedSize: [NSNumber numberWithLong: diff] data: jpgData]];
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate analyzeChanged: objectName];
				});
			}
		}
	}
}

@end
