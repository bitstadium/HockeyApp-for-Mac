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

#import "CNSArchive.h"
#import "CNSConnectionHelper.h"
#import "CNSConstants.h"
#import "CNSPreferencesViewController.h"
#import "NSFileHandle+CNSAvailableData.h"
#import "NSString+CNSStringAdditions.h"

@interface CNSArchive ()

- (BOOL)isMacApp:(NSDictionary *)info;

- (NSData *)zipFilesAtPath:(NSString *)sourcePath source:(NSString *)source toFilename:(NSString *)filename;

- (NSString *)createIPAFromFileWrapper:(NSFileWrapper *)fileWrapper;

- (void)createDSYMFromFileWrapper:(NSFileWrapper *)fileWrapper withAppKey:(NSString *)appKey;

@end

@implementation CNSArchive

@synthesize dsymCreated;
@synthesize dsymPath;
@synthesize info;
@synthesize ipaCreated;
@synthesize ipaPath;

#pragma mark - Initialization Methods

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];
  
  [self.fileTypeMenu setEnabled:(self.dsymCreated || self.ipaCreated)];
  [[self.fileTypeMenu itemAtIndex:0] setEnabled:(self.dsymCreated && self.ipaCreated)];
  [[self.fileTypeMenu itemAtIndex:1] setEnabled:self.ipaCreated];
  [[self.fileTypeMenu itemAtIndex:2] setEnabled:self.dsymCreated];
  [self.fileTypeMenu selectItemAtIndex:(self.dsymCreated && !self.ipaCreated ? 2 : (self.ipaCreated && !self.dsymCreated ? 1 : 0))];
  
  if (([[[NSProcessInfo processInfo] arguments] containsObject:@"onlyIPA"]) && (self.ipaCreated)) {
    [self.fileTypeMenu selectItemAtIndex:1];
  }
  else if (([[[NSProcessInfo processInfo] arguments] containsObject:@"onlyDSYM"]) && (self.dsymCreated)) {
    [self.fileTypeMenu selectItemAtIndex:2];
  }
  
  if ([self isMacApp:self.info]) {
    [[self.fileTypeMenu itemAtIndex:0] setTitle:@".app.zip & dSYM.zip"];
    [[self.fileTypeMenu itemAtIndex:1] setTitle:@"Only .app.zip"];
  }

  [self fileTypeMenuWasChanged:self.fileTypeMenu];
}

#pragma mark - NSDocument Methods

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError {
  self.info = nil;
  self.dsymCreated = NO;
  self.ipaCreated = NO;
  
  NSString *appKey = [self createIPAFromFileWrapper:fileWrapper];
  [self createDSYMFromFileWrapper:fileWrapper withAppKey:appKey];

  return (self.info != nil);
}

#pragma mark - NSWindowDelegate Methods

- (void)windowWillClose:(NSNotification *)notification {
  // Cleanup temp directories
  if (tempDirectoryPaths) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *tempDirectoryPath in tempDirectoryPaths) {
      [fileManager removeItemAtPath:tempDirectoryPath error:NULL];
    }
    
    [tempDirectoryPaths release], tempDirectoryPaths = nil;
  }
}

#pragma mark - Private Helper Methods

- (NSString *)bundleIdentifier {
  return [self.info valueForKey:@"CFBundleIdentifier"];
}

- (NSString *)bundleShortVersion {
  return [self.info valueForKey:@"CFBundleShortVersionString"];
}

- (NSString *)bundleVersion {
  return [self.info valueForKey:@"CFBundleVersion"];
}

- (NSData *)zipFilesAtPath:(NSString *)sourcePath source:(NSString *)source toFilename:(NSString *)filename {
  NSTask *zip = [[[NSTask alloc] init] autorelease];
  NSPipe *aPipe = [NSPipe pipe];
  [zip setStandardOutput:aPipe];
  [zip setCurrentDirectoryPath:sourcePath];
  [zip setLaunchPath:@"/usr/bin/zip"];
  [zip setArguments:[NSArray arrayWithObjects:@"-r", @"-y", filename, source, nil]];
  [zip launch];
  
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

- (NSString *)tempDirectoryPath {
  NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HockeyAppMac.XXXXXX"];
  const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
  char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
  strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);

  char *result = mkdtemp(tempDirectoryNameCString);
  if (!result) {
    return NO;
  }
  
  NSString *tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
  free(tempDirectoryNameCString);

  if (!tempDirectoryPaths) {
    tempDirectoryPaths = [[NSMutableArray alloc] init];
  }
  [tempDirectoryPaths addObject:tempDirectoryPath];
  
  return tempDirectoryPath;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier publicID:(NSString *)publicID {
  NSString *boundary = @"HOCKEYAPP1234567890";

  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps/%@/app_versions", baseURL, publicID]]];
  [request setHTTPMethod:@"POST"];
  [request setTimeoutInterval:300];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];

  NSString *platform = nil;
  if ([self.fileTypeMenu indexOfSelectedItem] == 2) {
    platform = (([self isMacApp:self.info]) ? @"Mac OS" : @"iOS");
  }

  NSURL *ipaURL = [NSURL fileURLWithPath:self.ipaPath];
  NSMutableData *body = [self createPostBodyWithURL:([self.fileTypeMenu indexOfSelectedItem] < 2 ? ipaURL : nil) boundary:boundary platform:platform];
  
  if ((self.dsymCreated) && ([self.fileTypeMenu indexOfSelectedItem] != 1)) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"dsym\"; filename=\"%@\"\r\n", [self.dsymPath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.dsymPath]]];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:body];
  
  self.connectionHelper = [[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:nil token:self.apiToken] autorelease];
  [self.progressIndicator setHidden:NO];
  [self.errorLabel setHidden:YES];
  [self.statusLabel setHidden:NO];
}

- (void)loadInfoWithFileWrapper:(NSFileWrapper *)fileWrapper {
  NSDictionary *appContents = [fileWrapper fileWrappers];
  
  if ([appContents valueForKey:@"Info.plist"]) {
    NSFileWrapper *infoWrapper = [appContents valueForKey:@"Info.plist"];
    self.info = [NSPropertyListSerialization propertyListFromData:[infoWrapper regularFileContents] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
  }
  else {
    if ([appContents valueForKey:@"Contents"]) {
      NSFileWrapper *contentWrapper = [appContents valueForKey:@"Contents"];
      NSDictionary *contentContents = [contentWrapper fileWrappers];
      
      if ([contentContents valueForKey:@"Info.plist"]) {
        NSFileWrapper *infoWrapper = [contentContents valueForKey:@"Info.plist"];
        self.info = [NSPropertyListSerialization propertyListFromData:[infoWrapper regularFileContents] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
      }
    }
  }
}

- (BOOL)copyAndZipPayloadForKey:(NSString *)appKey {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  NSString *tempDirectoryPath = [self tempDirectoryPath];
  NSString *urlEncodedKey = [appKey URLEncodedString];
  NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@Products/Applications/%@", [[self fileURL] absoluteURL], urlEncodedKey]];

  if ([self isMacApp:self.info]) {
    [fileManager createDirectoryAtPath:tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSURL *targetURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", tempDirectoryPath, appKey]];
    
    NSError *error = nil;
    [fileManager copyItemAtURL:sourceURL toURL:targetURL error:&error];
    if (error) {
      return NO;
    }
    
    self.ipaPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, [appKey stringByReplacingOccurrencesOfString:@".app" withString:@".app.zip"]];
    self.ipaCreated = ([self zipFilesAtPath:tempDirectoryPath source:appKey toFilename:self.ipaPath] != nil);
  }
  else {
    NSString *payloadPath = [NSString stringWithFormat:@"%@/Payload", tempDirectoryPath];
    [fileManager createDirectoryAtPath:payloadPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSURL *targetURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", payloadPath, appKey]];
    
    NSError *error = nil;
    [fileManager copyItemAtURL:sourceURL toURL:targetURL error:&error];
    if (error) {
      return NO;
    }
    
    NSString *filename = [[appKey stringByReplacingOccurrencesOfString:@".app" withString:@".ipa"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.ipaPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, filename];
    self.ipaCreated = ([self zipFilesAtPath:tempDirectoryPath source:@"Payload" toFilename:self.ipaPath] != nil);
  }
  
  return YES;
}

- (NSString *)createIPAFromFileWrapper:(NSFileWrapper *)fileWrapper {
  NSString *appKey = nil;
  
  NSDictionary *contents = [fileWrapper fileWrappers];
  if ([contents valueForKey:@"Products"]) {
    NSFileWrapper *productWrapper = [contents valueForKey:@"Products"];
    NSDictionary *productContents = [productWrapper fileWrappers];
    
    if ([productContents valueForKey:@"Applications"]) {
      NSFileWrapper *applicationWrapper = [productContents valueForKey:@"Applications"];
      NSDictionary *applicationContents = [applicationWrapper fileWrappers];
      
      for (NSString *key in applicationContents) {
        // We take the first thing which ends in .app
        if ([key hasSuffix:@".app"]) {
          appKey = key;
          break;
        }
      }
      
      if (appKey) {
        NSFileWrapper *appWrapper = [applicationContents valueForKey:appKey];
        [self loadInfoWithFileWrapper:appWrapper];
        
        if ((!self.info) || (![self copyAndZipPayloadForKey:appKey])) {
          appKey = nil;
        }
      }
    }
  }
  
  return appKey;
}

- (void)copyAndZipDSYMForKey:(NSString *)dsymKey {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  NSString *tempDirectoryPath = [self tempDirectoryPath];
  NSString *targetPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, dsymKey];

  NSString *urlEncodedKey = [dsymKey URLEncodedString];
  NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@dSYMs/%@", [[self fileURL] absoluteURL], urlEncodedKey]];
  NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
  
  NSError *error = nil;
  [fileManager copyItemAtURL:sourceURL toURL:targetURL error:&error];
  if (error) {
    return;
  }

  NSString *filename = [[dsymKey stringByReplacingOccurrencesOfString:@".app.dSYM" withString:@".dSYM.zip"] stringByReplacingOccurrencesOfString:@" " withString:@""];
  self.dsymPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, filename];
  self.dsymCreated = ([self zipFilesAtPath:tempDirectoryPath source:dsymKey toFilename:self.dsymPath] != nil);
}

- (void)createDSYMFromFileWrapper:(NSFileWrapper *)fileWrapper withAppKey:(NSString *)appKey {
  NSDictionary *contents = [fileWrapper fileWrappers];
  if ([contents valueForKey:@"dSYMs"]) {
    NSString *dsymKey = nil;
    NSFileWrapper *dsymWrapper = [contents valueForKey:@"dSYMs"];
    NSDictionary *dsymContents = [dsymWrapper fileWrappers];
    
    for (NSString *key in dsymContents) {
      // We either search for the appKey + ".dSYM" or for the first entry
      if (((!appKey) && ([key hasSuffix:@".dSYM"])) || ((appKey) && ([key hasSuffix:[NSString stringWithFormat:@"%@.dSYM", appKey]]))) {
        dsymKey = key;
        break;
      }
    }
    
    if (dsymKey) {
      [self copyAndZipDSYMForKey:dsymKey];
    }
  }
}

- (BOOL)isMacApp:(NSDictionary *)infos {
  BOOL requiresIPhoneOS = [[infos valueForKey:@"LSRequiresIPhoneOS"] boolValue];
  NSString *minimumSystemVersion = [infos valueForKey:@"LSMinimumSystemVersion"];
  NSString *pricipalClass = [infos valueForKey:@"NSPrincipalClass"];
  return (!requiresIPhoneOS) && (minimumSystemVersion || pricipalClass);
}

#pragma mark - Memory Management Mehtods

- (void)dealloc {
  self.dsymPath = nil;
  self.info = nil;
  self.ipaPath = nil;
  
  [tempDirectoryPaths release], tempDirectoryPaths = nil;
  
  [super dealloc];
}

@end
