#import "CNSArchive.h"
#import "CNSConnectionHelper.h"
#import "CNSPreferencesViewController.h"
#import "NSFileHandle+CNSAvailableData.h"

@interface CNSArchive ()

- (BOOL)isMacApp:(NSDictionary *)info;

- (NSData *)zipFilesAtPath:(NSString *)sourcePath source:(NSString *)source toFilename:(NSString *)filename;

@end

@implementation CNSArchive

@synthesize dsymCreated;
@synthesize dsymPath;
@synthesize info;
@synthesize ipaCreated;
@synthesize ipaPath;

#pragma mark - NSDocument

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  return YES;
}

#pragma mark - Private Helper Methods

- (NSString *)bundleIdentifier {
  return [self.info valueForKey:@"CFBundleIdentifier"];
}

- (NSData *)zipFilesAtPath:(NSString *)sourcePath source:(NSString *)source toFilename:(NSString *)filename {
  NSTask *zip = [[[NSTask alloc] init] autorelease];
  NSPipe *aPipe = [NSPipe pipe];
  [zip setStandardOutput:aPipe];
  [zip setCurrentDirectoryPath:sourcePath];
  [zip setLaunchPath:@"/usr/bin/zip"];
  [zip setArguments:[NSArray arrayWithObjects:@"-r", filename, source, nil]];
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

  return tempDirectoryPath;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier {
  NSString *boundary = @"HOCKEYAPP1234567890";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps", [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost]]]];
  [request setHTTPMethod:@"POST"];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *body = [self createPostBodyWithURL:[NSURL fileURLWithPath:self.ipaPath] boundary:boundary];
  
  if (self.dsymCreated) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"dsym\"; filename=\%@\"\r\n", [self.dsymPath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.dsymPath]]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:body];
  
  self.connectionHelper = [[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:nil];
}

- (NSString *)createIPAFromFileWrapper:(NSFileWrapper *)fileWrapper {
  NSFileManager *fileManager = [NSFileManager defaultManager];
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
          appKey = 	key;
          break;
        }
      }
      
      if (appKey) {
        NSFileWrapper *appWrapper = [applicationContents valueForKey:appKey];
        NSDictionary *appContents = [appWrapper fileWrappers];
        
        // Read the info plist
        // TODO: Refactor into method
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
        
        // TODO: Refactor into method
        if (self.info) {
          NSString *tempDirectoryPath = [self tempDirectoryPath];
          NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@Products/Applications/%@", [[self fileURL] absoluteURL], appKey]];
          
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
            
            self.ipaPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, [appKey stringByReplacingOccurrencesOfString:@".app" withString:@".ipa"]];
            self.ipaCreated = ([self zipFilesAtPath:tempDirectoryPath source:@"Payload" toFilename:self.ipaPath] != nil);
          }
        }
      }
    }
  }
  
  return appKey;
}

- (void)createDSYMFromFileWrapper:(NSFileWrapper *)fileWrapper withAppKey:(NSString *)appKey {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
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
    
    // TODO: Refactor into method
    if (dsymKey) {
      NSString *tempDirectoryPath = [self tempDirectoryPath];
      NSString *targetPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, dsymKey];
      NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@dSYMs/%@", [[self fileURL] absoluteURL], dsymKey]];
      NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
      
      NSError *error = nil;
      [fileManager copyItemAtURL:sourceURL toURL:targetURL error:&error];
      if (error) {
        return;
      }
      
      self.dsymPath = [NSString stringWithFormat:@"%@/%@", tempDirectoryPath, [dsymKey stringByReplacingOccurrencesOfString:@".app.dSYM" withString:@".dSYM.zip"]];
      self.dsymCreated = ([self zipFilesAtPath:tempDirectoryPath source:dsymKey toFilename:self.dsymPath] != nil);
    }
  }
}

- (BOOL)isMacApp:(NSDictionary *)infos {
  return ([infos valueForKey:@"LSMinimumSystemVersion"]) || ([infos valueForKey:@"NSPrincipalClass"]);
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError {
  self.info = nil;
  self.dsymCreated = NO;
  self.ipaCreated = NO;
  
  NSString *appKey = [self createIPAFromFileWrapper:fileWrapper];
  [self createDSYMFromFileWrapper:fileWrapper withAppKey:appKey];

  return (self.info != nil);
}

#pragma mark - Memory Management Mehtods

- (void)dealloc {
  self.dsymPath = nil;
  self.info = nil;
  self.ipaPath = nil;
  [super dealloc];
}

@end
