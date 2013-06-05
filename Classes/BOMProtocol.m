//
//  BOMProtocol.m
//  HockeyMac
//
//  Created by Oliver Michalak on 05.06.13.
//
//

#import "BOMProtocol.h"

@implementation BOMProtocol

+ (BOMProtocol*) protocolWithFile:(NSURL*) file ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data {
	return [[BOMProtocol alloc] initWithFile:file ofType:type originalSize:size savedSize:savedSize data:data];
}

- (id) initWithFile:(NSURL*) file ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data {
	if ((self = [super init])) {
		self.file = file;
		self.type = type;
		self.size = size;
		self.savedSize = savedSize;
		self.optimizedData = data;
	}
	return self;
}

- (NSString*) description {
	NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
	formatter.allowsNonnumericFormatting = NO;
	NSString *typeString = @"convert opaque PNG to JPG";
	switch (self.type) {
		case BOMProtocolOptimizedPNG:
			typeString = @"re-quantify PNG";
			break;
		case BOMProtocolOptimizedJPG:
			typeString = @"re-compress JPG";
			break;
		default:;
	}
	return [NSString stringWithFormat:@"%@;%@;%@;%@;%@;%@;%d%%;;;", self.file.path.pathComponents.lastObject, typeString, [formatter stringForObjectValue:self.size], self.size, [formatter stringForObjectValue:self.savedSize], self.savedSize, (int)round((self.savedSize.longValue*100.0)/(float)self.size.longValue)];
}
@end
