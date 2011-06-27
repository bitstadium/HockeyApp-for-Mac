#import "CNSApp.h"
#import "CNSConnectionHelper.h"
#import "CNSPreferencesViewController.h"
#import "NSFileHandle+CNSAvailableData.h"

@interface CNSApp ()

- (NSData *)unzipFileAtPath:(NSString *)sourcePath extractFilename:(NSString *)extractFilename;
- (NSString *)bundleIdentifier;

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier;

@end

@implementation CNSApp

@synthesize cancelButton;
@synthesize connectionHelper;
@synthesize downloadButton;
@synthesize notesTypeMatrix;
@synthesize progressIndicator;
@synthesize releaseNotesField;
@synthesize statusLabel;
@synthesize uploadButton;
@synthesize uploadSheet;
@synthesize window;

#pragma mark - Initialization

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
  if ((self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError])) {
  }
  return self;
}


- (NSString *)windowNibName {
  return @"CNSApp";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];
  
  self.statusLabel.stringValue = @"";
  [self.window setTitle:[self.fileURL lastPathComponent]];
}

#pragma mark - NSDocument

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  if (outError) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  if (outError) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return YES;
}

#pragma mark - NSControl Action Methods

- (IBAction)uploadButtonWasClicked:(id)sender {
  self.statusLabel.stringValue = @"Initializing...";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];

  [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  
  NSString *bundleIdentifier = [self bundleIdentifier];
  if (bundleIdentifier) {
    [self postMultiPartRequestWithBundleIdentifier:[self bundleIdentifier]];
  }
  else {
    self.statusLabel.stringValue = @"Couldn't read bundle identifier!";
  }
}

- (IBAction)cancelButtonWasClicked:(id)sender {
  [self.connectionHelper cancelConnection];
  [self.uploadButton setEnabled:YES];
  [self.uploadSheet orderOut:self];
  [NSApp endSheet:self.uploadSheet];
}

#pragma mark - Private Helper Methods

- (NSString *)bundleIdentifier {
  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
  
  NSString *targetFilename = [tempPath stringByAppendingPathComponent:[self.fileURL lastPathComponent]];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilename];
  [[NSFileManager defaultManager] copyItemAtURL:self.fileURL toURL:targetURL error:NULL];
  
  NSData *data = [self unzipFileAtPath:targetFilename extractFilename:[NSString stringWithFormat:@"Payload/*/Info.plist"]];
  NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
  return [info valueForKey:@"CFBundleIdentifier"];
}

- (NSData *)unzipFileAtPath:(NSString *)sourcePath extractFilename:(NSString *)extractFilename {
  NSTask *unzip = [[[NSTask alloc] init] autorelease];
  NSPipe *aPipe = [NSPipe pipe];
  [unzip setStandardOutput:aPipe];
  [unzip setLaunchPath:@"/usr/bin/unzip"];
  [unzip setArguments:[NSArray arrayWithObjects:@"-p", sourcePath, extractFilename, nil]];
  [unzip launch];
  
  NSMutableData *dataOut = [NSMutableData data];
  NSData *dataIn = nil;
  NSException *error = nil;
  
  while ((dataIn = [[aPipe fileHandleForReading] availableDataOrError:&error]) && [dataIn length] && error == nil){
    [dataOut appendData:dataIn];
  }
  
  if ([dataOut length] && error == nil) {
    return dataOut;
  }
  
  return nil;
}

- (NSMutableData *)createPostBodyWithURL:(NSURL *)ipaURL boundary:(NSString *)boundary {
  NSMutableData *body = [NSMutableData dataWithCapacity:0];
  
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%d\r\n", ([self.downloadButton state] == NSOnState ? 2 : 1)] dataUsingEncoding:NSUTF8StringEncoding]];
  
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notes\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@\r\n", [self.releaseNotesField string]] dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSArray *cellArray = [self.notesTypeMatrix cells];
  NSString *notesType = ([[cellArray objectAtIndex:0] intValue] == 1 ? @"0" : @"1");
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notes_type\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@\r\n", notesType] dataUsingEncoding:NSUTF8StringEncoding]];
  
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"ipa\"; filename=\%@\"\r\n", [ipaURL lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[NSData dataWithContentsOfURL:ipaURL]];

  return body;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier {
  NSString *boundary = @"HOCKEYAPP1234567890";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps", [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost]]]];
  [request setHTTPMethod:@"POST"];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *body = [self createPostBodyWithURL:self.fileURL boundary:boundary];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:body];
  
  self.connectionHelper = [[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:nil];
}

#pragma mark - CNSConnectionHelper Delegate Methods

- (void)connectionHelperDidFail:(CNSConnectionHelper *)aConnectionHelper {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *result = [[[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding] autorelease];
  NSLog(@"%@", result);
  
  self.statusLabel.stringValue = @"Failed!";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Done"];
  
  [pool drain];
}

- (void)connectionHelper:(CNSConnectionHelper *)aConnectionHelper didProgress:(NSNumber*)progress {
  double currentProgress = self.progressIndicator.doubleValue;
  if ([progress floatValue] == 1.0) {
    self.statusLabel.stringValue = @"Processing...";
    self.progressIndicator.doubleValue = 100.0;
  }
  else {
    self.statusLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", [progress floatValue] * 100];
    self.progressIndicator.doubleValue = MAX([progress floatValue] * 100, currentProgress);
  }
}

- (void)parseVersionResponse:(CNSConnectionHelper *)aConnectionHelper {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // TODO: Do something with the result!
  NSString *result = [[[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding] autorelease];
  NSLog(@"%@", result);
  
  if (aConnectionHelper.statusCode != 201) {
    [self connectionHelperDidFail:aConnectionHelper];
  }
  else {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.statusLabel.stringValue = @"Successful!";
      self.progressIndicator.doubleValue = 0;
      [self.uploadButton setEnabled:YES];
      [self.uploadSheet orderOut:self];
      [NSApp endSheet:self.uploadSheet];
      [self.window performClose:self];
      [self close];
    });
  }
  
  [pool drain];
}

#pragma mark - NSApp Delegate Methods

- (void)didEndUploadSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  [sheet orderOut:self];
  [NSApp endSheet:self.uploadSheet];
}

#pragma mark - Memory Management Mehtods

- (void)dealloc {
  self.cancelButton = nil;
  self.connectionHelper = nil;
	self.downloadButton = nil;
  self.notesTypeMatrix = nil;
  self.progressIndicator = nil;
  self.releaseNotesField = nil;
  self.statusLabel = nil;
  self.uploadButton = nil;
  self.uploadSheet = nil;
  self.window = nil;
  
  [super dealloc];
}

@end
