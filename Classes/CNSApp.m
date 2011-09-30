// Copyright 2011 Codenauts UG. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CNSApp.h"
#import "CNSConnectionHelper.h"
#import "CNSPreferencesViewController.h"
#import "JSON.h"
#import "NSFileHandle+CNSAvailableData.h"

@interface CNSApp ()

- (NSData *)unzipFileAtPath:(NSString *)sourcePath extractFilename:(NSString *)extractFilename;
- (NSString *)bundleIdentifier;

@end

@implementation CNSApp

@synthesize bundleIdentifier;
@synthesize bundleIdentifierLabel;
@synthesize bundleShortVersion;
@synthesize bundleShortVersionLabel;
@synthesize bundleVersion;
@synthesize bundleVersionLabel;
@synthesize cancelButton;
@synthesize connectionHelper;
@synthesize downloadButton;
@synthesize errorLabel;
@synthesize fileTypeMenu;
@synthesize notesTypeMatrix;
@synthesize notifyButton;
@synthesize progressIndicator;
@synthesize releaseNotesField;
@synthesize statusLabel;
@synthesize uploadButton;
@synthesize uploadSheet;
@synthesize window;

#pragma mark - Initialization Methods

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
  
  self.bundleIdentifierLabel.stringValue = (self.bundleIdentifier ?: @"unknown");
  self.bundleShortVersionLabel.stringValue = (self.bundleShortVersion ?: @"not set");
  self.bundleVersionLabel.stringValue = (self.bundleVersion ?: @"invalid");
  
  self.statusLabel.stringValue = @"";

  [self.fileTypeMenu selectItemAtIndex:1];
  [self.fileTypeMenu setEnabled:NO];

  [self.window setTitle:[self.fileURL lastPathComponent]];
  
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"notifyOn"]) {
    self.notifyButton.state = NSOnState;
  }
  
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"downloadOff"]) {
    self.downloadButton.state = NSOffState;
    [self.notifyButton setEnabled:NO];
  }
  
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"autoSubmit"]) {
    [self uploadButtonWasClicked:nil];
  }
}

#pragma mark - NSWindowDelegate Methods

- (BOOL)windowShouldClose:(id)sender {
  [self close];
  return YES;
}

#pragma mark - NSDocument Methods

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
  
  [self bundleIdentifier];
  
  return YES;
}

#pragma mark - NSControl Action Methods

- (IBAction)cancelButtonWasClicked:(id)sender {
  [self.connectionHelper cancelConnection];
  [self.uploadButton setEnabled:YES];
  [self.uploadSheet orderOut:self];
  [NSApp endSheet:self.uploadSheet];
}

- (IBAction)downloadButtonWasClicked:(id)sender {
  [self.notifyButton setEnabled:(self.downloadButton.state == NSOnState)];
}

- (IBAction)fileTypeMenuWasChanged:(id)sender {
  switch ([self.fileTypeMenu indexOfSelectedItem]) {
    case 0:
    case 1:
      [self.downloadButton setEnabled:YES];
      [self.notifyButton setEnabled:YES];
      break;
    case 2:
      [self.downloadButton setEnabled:NO];
      [self.notifyButton setEnabled:NO];
    default:
      break;
  }
}

- (IBAction)uploadButtonWasClicked:(id)sender {
  self.statusLabel.stringValue = @"Initializing...";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];

  [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  
  if (self.bundleIdentifier) {
    [self postMultiPartRequestWithBundleIdentifier:self.bundleIdentifier];
  }
  else {
    self.statusLabel.stringValue = @"Couldn't read bundle identifier!";
  }
}

#pragma mark - Private Helper Methods

- (NSString *)bundleIdentifier {
  if (bundleIdentifier) {
    return bundleIdentifier;
  }
  
  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
  
  NSString *targetFilename = [tempPath stringByAppendingPathComponent:[self.fileURL lastPathComponent]];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilename];
  [[NSFileManager defaultManager] copyItemAtURL:self.fileURL toURL:targetURL error:NULL];
  
  NSData *data = [self unzipFileAtPath:targetFilename extractFilename:[NSString stringWithFormat:@"Payload/*.app/Info.plist"]];
  NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
  
  self.bundleIdentifier = [info valueForKey:@"CFBundleIdentifier"];
  self.bundleVersion = [info valueForKey:@"CFBundleVersion"];
  self.bundleShortVersion = [info valueForKey:@"CFBundleShortVersionString"];
  
  return bundleIdentifier;
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

- (NSMutableData *)createPostBodyWithURL:(NSURL *)ipaURL boundary:(NSString *)boundary platform:(NSString *)platform {
  NSMutableData *body = [NSMutableData dataWithCapacity:0];
  
  BOOL downloadOn = ([self.downloadButton state] == NSOnState);
  if ([self.downloadButton isEnabled]) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d\r\n", (downloadOn ? 2 : 1)] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  BOOL notifyOn = ([self.notifyButton state] == NSOnState);
  if ([self.notifyButton isEnabled]) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notify\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d\r\n", ((downloadOn && notifyOn) ? 1 : 0)] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
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

  if (platform) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"platform\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", platform] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  if (ipaURL) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"ipa\"; filename=\"%@\"\r\n", [ipaURL lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithContentsOfURL:ipaURL]];
  }

  return body;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier {
  NSString *boundary = @"HOCKEYAPP1234567890";

  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps", baseURL]]];
  [request setHTTPMethod:@"POST"];
  [request setTimeoutInterval:300];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *body = [self createPostBodyWithURL:self.fileURL boundary:boundary platform:nil];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:body];
  
  self.connectionHelper = [[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:nil] autorelease];
  [self.progressIndicator setHidden:NO];
  [self.errorLabel setHidden:YES];
  [self.statusLabel setHidden:NO];
}

#pragma mark - CNSConnectionHelper Delegate Methods

- (void)connectionHelperDidFail:(CNSConnectionHelper *)aConnectionHelper {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *result = [[[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding] autorelease];
  
  NSString *errorMessage = nil;
  if ([result length] == 0) {
    errorMessage = @"Failed: Server did not respond. Please check your network connection.";
  }
  else {
    NSDictionary *json = [result JSONValue];
    NSMutableString *serverMessage = [NSMutableString stringWithCapacity:0];
    NSDictionary *errors = [json valueForKey:@"errors"];
    for (NSString *attribute in errors) {
      [serverMessage appendFormat:@"%@ - %@. ", attribute, [[errors valueForKey:attribute] componentsJoinedByString:@" and "]];
    }
    if ([[serverMessage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
      [serverMessage setString:@"No reason specified."];
    }
    errorMessage = [NSString stringWithFormat:@"Failed. Status code: %d. Server response: %@", aConnectionHelper.statusCode, serverMessage];
  }
  
  [self.errorLabel setHidden:NO];
  self.errorLabel.stringValue = errorMessage;
  
  [self.statusLabel setHidden:YES];
  
  self.progressIndicator.doubleValue = 0;
  [self.progressIndicator setHidden:YES];
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
      
      if ([[[NSProcessInfo processInfo] arguments] containsObject:@"autoSubmit"]) {
        [NSApp terminate:nil];
      }
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
  self.bundleIdentifier = nil;
  self.bundleIdentifierLabel = nil;
  self.bundleVersion = nil;
  self.bundleVersionLabel = nil;
  self.bundleShortVersion = nil;
  self.bundleShortVersionLabel = nil;
  self.cancelButton = nil;
  self.connectionHelper = nil;
	self.downloadButton = nil;
  self.errorLabel = nil;
  self.fileTypeMenu = nil;
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
