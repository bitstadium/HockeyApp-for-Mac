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
#import "SBJSON.h"
#import "NSFileHandle+CNSAvailableData.h"

enum CNSHockeyAppReleaseType {
  CNSHockeyAppReleaseTypeBeta,
  CNSHockeyAppReleaseTypeLive,
  CNSHockeyAppReleaseTypeAlpha,
  CNSHockeyAppReleaseTypeAuto = 0x100
};

@interface CNSApp ()
@property(nonatomic) NSMutableDictionary *appsByReleaseType;

- (NSData *)unzipFileAtPath:(NSString *)sourcePath extractFilename:(NSString *)extractFilename;
- (NSString *)bundleIdentifier;
- (void)readAfterUploadSelection;
- (void)readNotesType;
- (void)readProcessArguments;
- (void)storeNotesType;
- (void)storeAfterUploadSelection;
- (void)fetchAppNames;
- (NSInteger)currentSelectedReleaseType;
- (NSDictionary *)appForTitle:(NSString *)aTitle releaseType:(NSInteger)aReleaseType;
- (NSDictionary *)currentSelectedApp;
- (NSString *)titleForReleaseType:(NSInteger)releaseType;

@end

@implementation CNSApp

@synthesize afterUploadMenu;
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
@synthesize releaseTypeMenu;
@synthesize appNameMenu;
@synthesize statusLabel;
@synthesize uploadButton;
@synthesize uploadSheet;
@synthesize window;
@synthesize appsByReleaseType;
@synthesize apiToken;

#pragma mark - Initialization Methods

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
  if ((self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError])) {
      [self readProcessArguments];
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
  
  [self readNotesType];
  [self readAfterUploadSelection];

  [self.window setTitle:[self.fileURL lastPathComponent]];

  [self readProcessArguments];
  [self fetchAppNames];
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

- (IBAction)releaseTypeMenuWasChanged:(id)sender {
  if ([self.releaseTypeMenu indexOfSelectedItem] > 0) {
    NSInteger selectedReleaseType = [self currentSelectedReleaseType];
    NSArray *appsForReleaseType = [self.appsByReleaseType objectForKey:[NSNumber numberWithInteger:selectedReleaseType]];
    if ([appsForReleaseType count] > 0) {
      [self.appNameMenu selectItemWithTitle:[[appsForReleaseType objectAtIndex:0] valueForKey:@"title"]];
    }
    else {
      [self.appNameMenu selectItemAtIndex:-1];
      self.appNameMenu.enabled = NO;
    }
    if (selectedReleaseType == CNSHockeyAppReleaseTypeLive) {
      [self.fileTypeMenu selectItemAtIndex:2];
    }
  }
  else {
    self.appNameMenu.enabled = YES;
  }
}

- (IBAction)appNameMenuWasChanged:(id)sender {
  if ([self.appNameMenu indexOfSelectedItem] >= 0) {
    NSString *title = [self.appNameMenu selectedItem].title;
    NSDictionary *appDictionary = [self appForTitle:title releaseType:[self currentSelectedReleaseType]];
    if (!appDictionary) {
      appDictionary = [self appForTitle:title releaseType:CNSHockeyAppReleaseTypeAuto];
    }
    if (appDictionary) {
      [self.releaseTypeMenu selectItemWithTitle:[self titleForReleaseType:[[appDictionary valueForKey:@"release_type"] integerValue]]];
    }
  }
}

- (IBAction)uploadButtonWasClicked:(id)sender {
  self.statusLabel.stringValue = @"Initializing...";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];
  
  [self storeNotesType];
  [self storeAfterUploadSelection];

  [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  
  NSString *publicID = nil;
  NSInteger releaseType = [self currentSelectedReleaseType];
  if (([self.appNameMenu indexOfSelectedItem] > -1) && (releaseType != CNSHockeyAppReleaseTypeAuto)) {
    NSDictionary *appDictionary = [self appForTitle:[self.appNameMenu selectedItem].title releaseType:[self currentSelectedReleaseType]];
    publicID = [appDictionary valueForKey:@"public_identifier"];
  }

  if (self.bundleIdentifier) {
    [self postMultiPartRequestWithBundleIdentifier:self.bundleIdentifier publicID:publicID];
  }
  else {
    self.statusLabel.stringValue = @"Couldn't read bundle identifier!";
  }
}

#pragma mark - Private Helper Methods

- (NSDictionary *)appForTitle:(NSString *)aTitle releaseType:(NSInteger)aReleaseType {
  for (NSNumber *releaseType in self.appsByReleaseType) {
    NSArray *appDictionaries = [self.appsByReleaseType objectForKey:releaseType];
    for (NSDictionary *appDictionary in appDictionaries) {
      if (([[appDictionary valueForKey:@"title"] isEqualToString:aTitle]) && 
          (([releaseType integerValue] == aReleaseType) || (aReleaseType == CNSHockeyAppReleaseTypeAuto))) { // if releaseType auto return first app with matching name
        return appDictionary;
      }
    }
  }
  return nil;
}

- (NSDictionary *)currentSelectedApp {
  if ([self.appNameMenu indexOfSelectedItem] > -1) {
    return nil;
  }
  return [self appForTitle:[self.appNameMenu selectedItem].title releaseType:[self currentSelectedReleaseType]];
}

- (NSInteger)currentSelectedReleaseType {
  NSInteger selectedReleaseType = 0;
  switch ([self.releaseTypeMenu indexOfSelectedItem]) { 
    case 0:
      return CNSHockeyAppReleaseTypeAuto;
    case 1:
      return CNSHockeyAppReleaseTypeAlpha;
    case 2:
      return CNSHockeyAppReleaseTypeBeta;
    case 3:
      return CNSHockeyAppReleaseTypeLive;
  }
  return selectedReleaseType;
}

- (NSString *)titleForReleaseType:(NSInteger)releaseType {
  switch (releaseType) {
    case CNSHockeyAppReleaseTypeAuto:
      return @"Auto Detect";
    case CNSHockeyAppReleaseTypeAlpha:
      return @"Alpha";
    case CNSHockeyAppReleaseTypeBeta:
      return @"Beta";
    case CNSHockeyAppReleaseTypeLive:
      return @"Live";
  }
  return nil;
}

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
  NSTask *unzip = [[NSTask alloc] init];
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
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d\r\n", (downloadOn ? 2 : 1)] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  BOOL notifyOn = ([self.notifyButton state] == NSOnState);
  if ([self.notifyButton isEnabled]) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notify\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d\r\n", ((downloadOn && notifyOn) ? 1 : 0)] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notes\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@\r\n", [self.releaseNotesField string]] dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSArray *cellArray = [self.notesTypeMatrix cells];
  NSString *notesType = ([[cellArray objectAtIndex:0] intValue] == 1 ? @"0" : @"1");
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"notes_type\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@\r\n", notesType] dataUsingEncoding:NSUTF8StringEncoding]];

  if (platform) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"platform\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", platform] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  if ([self currentSelectedReleaseType] != CNSHockeyAppReleaseTypeAuto) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"release_type\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d\r\n", [self currentSelectedReleaseType]] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  if (ipaURL) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"ipa\"; filename=\"%@\"\r\n", [ipaURL lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithContentsOfURL:ipaURL]];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  }

  return body;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier publicID:(NSString *)publicID {
  NSString *boundary = @"HOCKEYAPP1234567890";

  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
  NSString *uploadURL = nil;
  if (publicID) {
    uploadURL = [NSString stringWithFormat:@"%@/api/2/apps/%@/app_versions", baseURL, publicID];
  }
  else {
    uploadURL = [NSString stringWithFormat:@"%@/api/2/apps/upload", baseURL];
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:uploadURL]];
  [request setHTTPMethod:@"POST"];
  [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
  [request setTimeoutInterval:300];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *body = [self createPostBodyWithURL:self.fileURL boundary:boundary platform:nil];
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:body];
  
  self.connectionHelper = [[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:nil token:self.apiToken];
  [self.progressIndicator setHidden:NO];
  [self.errorLabel setHidden:YES];
  [self.statusLabel setHidden:NO];
}

- (void)readNotesType {
  NSUInteger selected = [[NSUserDefaults standardUserDefaults] integerForKey:CNSUserDefaultsNotesType];
  if (selected < [self.notesTypeMatrix numberOfColumns]) {
    [self.notesTypeMatrix selectCellAtRow:0 column:selected];
  }
}

- (void)storeNotesType {
  NSArray *cellArray = [self.notesTypeMatrix cells];
  NSInteger notesType = ([[cellArray objectAtIndex:0] intValue] == 1 ? 0 : 1);
  [[NSUserDefaults standardUserDefaults] setInteger:notesType forKey:CNSUserDefaultsNotesType];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)readAfterUploadSelection {
  NSUInteger selected = [[NSUserDefaults standardUserDefaults] integerForKey:CNSUserDefaultsAfterUploadSelection];
  if (selected < [self.afterUploadMenu numberOfItems]) {
    [self.afterUploadMenu selectItemAtIndex:selected];
  }
}

- (void)storeAfterUploadSelection {
  [[NSUserDefaults standardUserDefaults] setInteger:[self.afterUploadMenu indexOfSelectedItem] forKey:CNSUserDefaultsAfterUploadSelection];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadReleaseNotesFile:(NSString *)filename {
  NSError *error = nil;
  NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
  if (!error) {
    [self.releaseNotesField setString:contents];
  }
}

- (void)fetchAppNames {
  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps", baseURL]]];
  [request setHTTPMethod:@"GET"];
  [request setTimeoutInterval:300];

  self.connectionHelper = [[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseAppListResponse:) identifier:nil token:self.apiToken];
}

- (void)readProcessArguments {
  NSArray *arguments = [[NSProcessInfo processInfo] arguments];
  for (NSString *argument in arguments) {
    if ([argument isEqualToString:@"notifyOn"]) {
      self.notifyButton.state = NSOnState;
    }
    else if ([argument isEqualToString:@"downloadOff"]) {
      self.downloadButton.state = NSOffState;
      [self.notifyButton setEnabled:NO];
    }
    else if ([argument isEqualToString:@"autoSubmit"]) {
      [self uploadButtonWasClicked:nil];
    }
    else if ([argument isEqualToString:@"setBeta"]) {
        [self.releaseTypeMenu selectItemAtIndex:2];
    }
    else if ([argument isEqualToString:@"setAlpha"]) {
        [self.releaseTypeMenu selectItemAtIndex:1];
    }
    else if ([argument isEqualToString:@"setLive"]) {
        [self.releaseTypeMenu selectItemAtIndex:3];
    }
    else if ([argument isEqualToString:@"openNoPage"]) {
      [self.afterUploadMenu selectItemAtIndex:0];
    }
    else if ([argument isEqualToString:@"openDownloadPage"]) {
      [self.afterUploadMenu selectItemAtIndex:1];
    }
    else if ([argument isEqualToString:@"openVersionPage"]) {
      [self.afterUploadMenu selectItemAtIndex:2];
    }
    else if (([argument hasPrefix:@"notes="]) && (!ignoreNotesFile)) {
      [self loadReleaseNotesFile:[[argument componentsSeparatedByString:@"="] lastObject]];
      ignoreNotesFile = YES;
    }
    else if ([argument hasPrefix:@"token="]) {
        self.apiToken = [[argument componentsSeparatedByString:@"="] lastObject];
    }
  }
}

#pragma mark - CNSConnectionHelper Delegate Methods

- (void)connectionHelperDidFail:(CNSConnectionHelper *)aConnectionHelper {
  @autoreleasepool {
  
    NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];
    
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
  
  
  }
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

- (void)parseAppListResponse:(CNSConnectionHelper *)aConnectionHelper {
  if (aConnectionHelper.statusCode != 200) {
    [self connectionHelperDidFail:aConnectionHelper];
  }
  else {
    NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];
    NSDictionary *json = [result JSONValue];
    self.appsByReleaseType = [NSMutableDictionary dictionary];
		
    // Include only those apps which have the selected Bundle ID
    for (NSDictionary *appDict in [json objectForKey:@"apps"]) {
      if(![[appDict objectForKey:@"bundle_identifier"] isEqualToString:self.bundleIdentifier])
        continue;
			
      NSString *appName = [appDict objectForKey:@"title"];
      NSString *publicID = [appDict objectForKey:@"public_identifier"];
      NSNumber *releaseType = [appDict objectForKey:@"release_type"];

      if([appName length] > 0 && [publicID length] > 0) {
        if (!([self.appsByReleaseType objectForKey:releaseType])) {
          [self.appsByReleaseType setObject:[NSMutableArray arrayWithCapacity:0] forKey:releaseType];
        }
        [[self.appsByReleaseType objectForKey:releaseType] addObject:appDict];
      }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.appNameMenu removeAllItems];
      [self.appsByReleaseType enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *apps, BOOL *stop) {
        [apps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          [self.appNameMenu addItemWithTitle:[obj objectForKey:@"title"]];
        }];
      }];
      
      [self.appNameMenu selectItemAtIndex:0];
      [self appNameMenuWasChanged:nil];
      [self readProcessArguments];
      [self releaseTypeMenuWasChanged:nil];
    });
  }
}

- (void)parseVersionResponse:(CNSConnectionHelper *)aConnectionHelper {
  @autoreleasepool {
  
    if (aConnectionHelper.statusCode != 201) {
      [self connectionHelperDidFail:aConnectionHelper];
    }
    else {
      NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];
      NSDictionary *json = [result JSONValue];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.stringValue = @"Successful!";
        self.progressIndicator.doubleValue = 0;
        [self.uploadButton setEnabled:YES];
        [self.uploadSheet orderOut:self];
        [NSApp endSheet:self.uploadSheet];
        [self.window performClose:self];
        [self close];

        if (([self.afterUploadMenu indexOfSelectedItem] == 1) && ([json valueForKey:@"public_url"])) {
          NSURL *publicURL = [NSURL URLWithString:[json valueForKey:@"public_url"]];
          [[NSWorkspace sharedWorkspace] openURL:publicURL];
        }
        
        if (([self.afterUploadMenu indexOfSelectedItem] == 2) && ([json valueForKey:@"config_url"])) {
          NSURL *configURL = [NSURL URLWithString:[json valueForKey:@"config_url"]];
          [[NSWorkspace sharedWorkspace] openURL:configURL];
        }
        
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"autoSubmit"]) {
          [NSApp terminate:nil];
        }
      });
    }
  
  }
}

#pragma mark - NSApp Delegate Methods

- (void)didEndUploadSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  [sheet orderOut:self];
  [NSApp endSheet:self.uploadSheet];
}

#pragma mark - Memory Management Mehtods

- (void)dealloc {
  self.afterUploadMenu = nil;
  self.bundleIdentifierLabel = nil;
  self.bundleVersionLabel = nil;
  self.bundleShortVersionLabel = nil;
  self.cancelButton = nil;
  self.downloadButton = nil;
  self.errorLabel = nil;
  self.fileTypeMenu = nil;
  self.notesTypeMatrix = nil;
  self.progressIndicator = nil;
  self.releaseNotesField = nil;
  self.releaseTypeMenu = nil;
  self.appNameMenu = nil;
  self.statusLabel = nil;
  self.uploadButton = nil;
  self.uploadSheet = nil;
  self.window = nil;
  
}

@end
