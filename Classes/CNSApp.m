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
#import "M3TokenController.h"
#import "CNSConstants.h"
#import "NSString+CNSStringAdditions.h"

static NSString *CNSReleaseTypeMismatchSheet = @"CNSReleaseTypeMismatchSheet";
static NSString *CNSExistingVersionSheet = @"CNSExistingVersionSheet";

@interface CNSApp ()
@property (nonatomic) NSMutableDictionary *appsByReleaseType;
@property (nonatomic) NSMutableDictionary *tagsForAppID;
@property (nonatomic) NSMutableDictionary *appVersionsForAppID;
@property (nonatomic) NSArray *selectedTags;
@property (nonatomic) BOOL skipUniqueVersionCheck;
@property (nonatomic) BOOL skipReleaseTypeCheck;

- (NSData *)unzipFileAtPath:(NSString *)sourcePath extractFilename:(NSString *)extractFilename;
- (NSString *)bundleIdentifier;
- (void)readAfterUploadSelection;
- (void)readNotesType;
- (void)readProcessArguments;
- (void)storeNotesType;
- (void)storeAfterUploadSelection;
- (void)fetchAppNames;
- (CNSHockeyAppReleaseType)currentSelectedReleaseType;
- (NSDictionary *)appForTitle:(NSString *)aTitle releaseType:(CNSHockeyAppReleaseType)aReleaseType;
- (NSDictionary *)currentSelectedApp;
- (NSArray *)tagsForCurrentSelectedApp;
- (NSString *)titleForReleaseType:(NSInteger)releaseType;
- (void)reloadTagsMenu;
- (NSSet *)tagsForTokenController:(M3TokenController *)controller;

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
@synthesize connectionHelpers;
@synthesize downloadButton;
@synthesize errorLabel;
@synthesize fileTypeMenu;
@synthesize notesTypeMatrix;
@synthesize notifyButton;
@synthesize mandatoryButton;
@synthesize progressIndicator;
@synthesize releaseNotesField;
@synthesize analyzeContainer;
@synthesize analyzeBar;
@synthesize analyzeFixedSizeBar;
@synthesize analyzeImageSizeBar;
@synthesize analyzeSavedSizeBar;
@synthesize analyzeSpinner;
@synthesize analyzeButton;
@synthesize analyzeInfo;
@synthesize releaseTypeMenu;
@synthesize appNameMenu;
@synthesize statusLabel;
@synthesize uploadButton;
@synthesize uploadSheet;
@synthesize window;
@synthesize appsByReleaseType;
@synthesize tagsForAppID;
@synthesize apiToken;
@synthesize restrictDownloadButton;
@synthesize tagSheet;
@synthesize cancelTagSheetButton;
@synthesize saveTagSheetButton;
@synthesize tokenController;
@synthesize selectedTags;
@synthesize publicIdentifier;
@synthesize appVersionsForAppID;
@synthesize appStoreBuild;
@synthesize infoLabel;
@synthesize infoSheet;
@synthesize skipReleaseTypeCheck;
@synthesize skipUniqueVersionCheck;
@synthesize continueButton;
@synthesize didClickContinueInInfoSheet;
@synthesize ignoreExistingVersion;
@synthesize analyzer;

#pragma mark - Initialization Methods

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
  if ((self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError])) {
    self.connectionHelpers = [NSMutableArray arrayWithCapacity:1];
    [self readProcessArguments];
  }
  return self;
}

- (NSString *)windowNibName {
  return @"CNSApp";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];

  [self setupViews];
  
  if (autoSubmit && self.publicIdentifier) { // Can't upload right now if publicIdentifier is not set, need to fetch apps first
    [self uploadButtonWasClicked:nil];
  }
}

#pragma mark - NSWindowDelegate Methods

- (BOOL) windowShouldClose:(id)sender {
  [self cancelConnections];
	if (self.analyzer) {
		[self.analyzer stop];
		while (self.analyzer.isRunning)
			;
		self.analyzer.delegate = nil;
		self.analyzer = nil;
	}
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
  if (sender == self.cancelButton) {
    [self cancelConnections];
    [self.uploadButton setEnabled:YES];
    [self.uploadSheet orderOut:self];
    [NSApp endSheet:self.uploadSheet];
  }
  else if (sender == self.cancelTagSheetButton) {
    [self.tagSheet orderOut:self];
    [NSApp endSheet:self.tagSheet];
  }
}

- (IBAction)saveTagSheetButtonWasClicked:(id)sender {
  self.selectedTags = self.tokenController.tokenField.objectValue;
  [self.tagSheet orderOut:self];
  [NSApp endSheet:self.tagSheet];
}

- (IBAction)downloadButtonWasClicked:(id)sender {
  [self.notifyButton setEnabled:(self.downloadButton.state == NSOnState)];
  [self.mandatoryButton setEnabled:(self.downloadButton.state == NSOnState)];
    
  [self.restrictDownloadButton setEnabled:(self.downloadButton.state == NSOnState)];
}

- (IBAction)fileTypeMenuWasChanged:(id)sender {
  switch ([self.fileTypeMenu indexOfSelectedItem]) {
    case 0:
    case 1:
      [self.notifyButton setEnabled:YES];
      [self.mandatoryButton setEnabled:YES];
      [self.restrictDownloadButton setEnabled:YES];
      break;
    case 2:
      [self.notifyButton setEnabled:NO];
      [self.mandatoryButton setEnabled:NO];
      [self.restrictDownloadButton setEnabled:NO];
    default:
      break;
  }
}

- (IBAction)releaseTypeMenuWasChanged:(id)sender {
    if ([self.releaseTypeMenu indexOfSelectedItem] > 0) {
        NSInteger selectedReleaseType = [self currentSelectedReleaseType];
        
        if (selectedReleaseType == CNSHockeyAppReleaseTypeLive) {
            [self.notifyButton setEnabled:NO];
            [self.mandatoryButton setEnabled:NO];
            [self.restrictDownloadButton setEnabled:NO];
            [self.fileTypeMenu selectItemAtIndex:2];
            self.downloadButton.title = @"Available in Store";
            self.downloadButton.state = NSOffState;
        }
        else {
            [self.notifyButton setEnabled:YES];
            [self.mandatoryButton setEnabled:YES];
            [self.restrictDownloadButton setEnabled:YES];
            [self.fileTypeMenu selectItemAtIndex:0];
            self.downloadButton.title = @"Download Allowed";
        }
        
        
        NSArray *appsForReleaseType = [self.appsByReleaseType objectForKey:[NSNumber numberWithInteger:selectedReleaseType]];
        if ([appsForReleaseType count] > 0) {
            [self.appNameMenu selectItemWithTitle:[[appsForReleaseType objectAtIndex:0] valueForKey:@"title"]];
            [self reloadTagsMenu];
        }
        else {
            [self.restrictDownloadButton setEnabled:NO];
            [self.appNameMenu selectItemAtIndex:-1];
            self.appNameMenu.enabled = NO;
        }
    }
    else {
        self.appNameMenu.enabled = YES;
        [self.restrictDownloadButton setEnabled:NO];
        self.downloadButton.state = NSOffState;
        [self.notifyButton setEnabled:YES];
        [self.mandatoryButton setEnabled:YES];
        self.downloadButton.title = @"Download Allowed / Available in Store";
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
    [self reloadTagsMenu];
  }
}

- (IBAction)uploadButtonWasClicked:(id)sender {
  self.errorLabel.hidden = YES;
  self.remainingTimeLabel.stringValue = @"";
  self.statusLabel.hidden = NO;
  self.statusLabel.stringValue = @"Doing preflight check...";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];
    
  [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  
  [self preUploadCheck];
}

- (IBAction)restrictDownloadsWasClicked:(id)sender {
  if (self.restrictDownloadButton.state == NSOnState) {
    tokenController.tokenField.objectValue = [self.selectedTags copy];
    [tokenController reloadTokens];
    [NSApp beginSheet:self.tagSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndTagSheet:returnCode:contextInfo:) contextInfo:nil];
  }
}

- (IBAction)cancelInfoSheetButtonWasClicked:(id)sender {
  self.didClickContinueInInfoSheet = NO;
  [self hideInfoSheet];
}

- (IBAction)continueInfoSheetButtonWasClicked:(id)sender {
  self.didClickContinueInInfoSheet = YES;
  [self hideInfoSheet];
}

#pragma mark - Analyzer

- (IBAction) analyzeButtonWasClicked:(id) sender {
	if (!self.analyzer) {
		analyzer = [[BOMAnalyze alloc] initWithFile: self.fileURL];
		analyzer.delegate = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[analyzer start];
		});
	}
	else if (analyzer.isRunning)
		[analyzer stop];
	else if (self.analyzer.protocol.count) {
		NSSavePanel *panel = [NSSavePanel savePanel];
		panel.canCreateDirectories = YES;
		panel.nameFieldLabel = @"Save Protocol as:";
		panel.nameFieldStringValue = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
		[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				NSFileManager *fm = [NSFileManager defaultManager];
				[fm removeItemAtPath: panel.URL.path error:nil];
				[fm createDirectoryAtPath: panel.URL.path withIntermediateDirectories:YES attributes:nil error:nil];
				NSString *output = [NSString stringWithFormat:@"%@;;;\n%@", [@[@"File name", @"Action", @"Original Size (readable)", @"Original Size", @"Optimized Size (readable)", @"Optimized Size", @"Wasted"] componentsJoinedByString:@";"], [self.analyzer.protocol componentsJoinedByString:@"\n"]];
				[output writeToFile: [panel.URL.path stringByAppendingPathComponent: [panel.nameFieldStringValue stringByAppendingPathExtension:@"csv"]] atomically:NO encoding:NSUTF8StringEncoding error:nil];
				for (BOMProtocol *entry in self.analyzer.protocol) {
					NSString *filename = [entry.file.path substringFromIndex: entry.rootFolder.path.length+1];
					// prevent bundling
					filename = [filename stringByReplacingOccurrencesOfString:@".app" withString:@".app~"];
					if (entry.type == BOMProtocolPNGtoJPG)
						filename = [filename stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"];
					filename = [panel.URL.path stringByAppendingPathComponent: filename];
					[fm removeItemAtPath: filename error:nil];
					NSArray *folderList = filename.pathComponents;
					NSString *folderName = [[folderList subarrayWithRange:NSMakeRange(0, folderList.count-1)] componentsJoinedByString:@"/"];
					[fm createDirectoryAtPath: folderName withIntermediateDirectories:YES attributes:nil error:nil];
					[entry.optimizedData writeToFile: filename atomically:NO];
				}
			}
		}];
	}
}

- (void) analyzeStarted {
	self.analyzeInfo.stringValue = @"";
	self.analyzeButton.title = @"Stop";
	self.analyzeBar.hidden = self.analyzeSpinner.hidden = NO;
	self.analyzeFixedSizeBar.hidden = self.analyzeImageSizeBar.hidden = self.analyzeSavedSizeBar.hidden = YES;
	[self.analyzeSpinner startAnimation:nil];
}

- (void) analyzeChanged:(NSString*) title {
	self.analyzeInfo.stringValue = title;
	if (self.analyzer.fixedSize.longValue || self.analyzer.imageSize.longValue) {
		self.analyzeFixedSizeBar.hidden = self.analyzeImageSizeBar.hidden = self.analyzeSavedSizeBar.hidden = NO;
		CGFloat totalSize = (float)self.analyzer.fixedSize.longValue + (float)self.analyzer.imageSize.longValue;

		CGFloat imageSize = (float)self.analyzer.imageSize.longValue / totalSize;
		CGFloat imageOffset = round(self.analyzeFixedSizeBar.frame.size.width * imageSize);
		self.analyzeImageSizeBar.frame = NSRectFromCGRect(CGRectMake(self.analyzeFixedSizeBar.frame.size.width - imageOffset, 0, imageOffset, self.analyzeFixedSizeBar.frame.size.height));

		CGFloat savedSize = (float)self.analyzer.savedImageSize.longValue / totalSize;
		CGFloat savedOffset = round(self.analyzeFixedSizeBar.frame.size.width * savedSize);
		self.analyzeSavedSizeBar.frame = NSRectFromCGRect(CGRectMake(self.analyzeFixedSizeBar.frame.size.width - savedOffset, 0, savedOffset, self.analyzeFixedSizeBar.frame.size.height));
	}
	else
		self.analyzeFixedSizeBar.hidden = self.analyzeImageSizeBar.hidden = self.analyzeSavedSizeBar.hidden = YES;
}

- (void) analyzeFinished:(BOOL) complete {
	self.analyzeInfo.stringValue = @"";
	if (complete) {
		self.analyzeButton.title = @"Export";
		NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
		formatter.allowsNonnumericFormatting = NO;
		self.analyzeInfo.stringValue = [NSString stringWithFormat:@"Wasted: %.0f%% (%@)", (100.0 * self.analyzer.savedImageSize.floatValue) / (self.analyzer.fixedSize.floatValue + self.analyzer.imageSize.floatValue), [formatter stringForObjectValue: self.analyzer.savedImageSize]];
	}
	else {
		self.analyzeButton.title = @"Start";
		self.analyzeBar.hidden = YES;
		self.analyzer = nil;
	}
	self.analyzeSpinner.hidden = YES;
	[self.analyzeSpinner stopAnimation:nil];
}

#pragma mark - Private Helper Methods

- (void)cancelConnections {
  for (CNSConnectionHelper *connectionHelper in self.connectionHelpers) {
    [connectionHelper cancelConnection];
  }
  [self.connectionHelpers removeAllObjects];
}

- (void)showExistingVersionInfoSheet {
  [NSApp endSheet:self.uploadSheet];
  self.infoLabel.stringValue = [NSString stringWithFormat:@"The BundleVersion %@ has already been taken.", self.bundleVersion];
  [NSApp beginSheet:self.infoSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndInfoSheet:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)CNSExistingVersionSheet];
}

- (void)showReleaseTypeMismatchInfoSheet {
  [NSApp endSheet:self.uploadSheet];
  self.infoLabel.stringValue = [NSString stringWithFormat:@"The build is signed with a store certificate but you set the release type to %@. Are you sure?", ([self currentSelectedReleaseType] == CNSHockeyAppReleaseTypeAlpha ? @"alpha" : @"beta")];
  [NSApp beginSheet:self.infoSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndInfoSheet:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)CNSReleaseTypeMismatchSheet];
}

- (void)preUploadCheck {
  if ([self doesReleaseTypeMatch]) {
    if (self.bundleIdentifier) {
      if (self.publicIdentifier == nil) {
        self.publicIdentifier = [self publicIdentifierForSelectedApp];
      }
      if (self.publicIdentifier) {
        if (self.ignoreExistingVersion) {
          [self startUploadWithPublicIdentifier:self.publicIdentifier];
        }
        else {
          [self checkBundleVersion:self.bundleVersion forAppID:self.publicIdentifier];
        }
      }
      else {
        [self startUploadWithPublicIdentifier:nil];
      }
    }
  }
  else {
    [self showReleaseTypeMismatchInfoSheet];
  }
}

- (void)startUploadWithPublicIdentifier:(NSString *)publicID {
  self.skipReleaseTypeCheck = NO;
  self.skipUniqueVersionCheck = NO;
  
  self.errorLabel.hidden = YES;
  self.remainingTimeLabel.stringValue = @"";
  self.statusLabel.hidden = NO;
  self.statusLabel.stringValue = @"Initializing...";
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];

  self.progressIndicator.hidden = NO;
  self.progressIndicator.doubleValue = 0;
  
  if (!self.uploadSheet.isKeyWindow) {
    [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  }

  [self storeNotesType];
  [self storeAfterUploadSelection];
  
  
  if (self.bundleIdentifier) {
    [self postMultiPartRequestWithBundleIdentifier:self.bundleIdentifier publicID:publicID];
  }
  else {
    self.statusLabel.stringValue = @"Couldn't read bundle identifier!";
  }
}

- (NSString *)publicIdentifierForSelectedApp {
  NSString *publicID = nil;
  NSInteger releaseType = [self currentSelectedReleaseType];
  if (([self.appNameMenu indexOfSelectedItem] > -1) && (releaseType != CNSHockeyAppReleaseTypeAuto)) {
    NSDictionary *appDictionary = [self appForTitle:[self.appNameMenu selectedItem].title releaseType:[self currentSelectedReleaseType]];
    publicID = [appDictionary valueForKey:@"public_identifier"];
  }
  return publicID;
}

- (BOOL)doesReleaseTypeMatch {
  if (!(self.skipReleaseTypeCheck)) {
    CNSHockeyAppReleaseType releaseType = [self currentSelectedReleaseType];
    if ((self.appStoreBuild == CNSHockeyBuildReleaseTypeStore) && ((releaseType == CNSHockeyAppReleaseTypeAlpha) || (releaseType == CNSHockeyAppReleaseTypeBeta))) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)isValidBuild {
  return [self doesReleaseTypeMatch];
}

- (void)reloadTagsMenu {
  NSArray *tagsForCurrentApp = [self tagsForCurrentSelectedApp];
  if ([tagsForCurrentApp count] == 0) {
    self.restrictDownloadButton.state = NSOffState;
    self.restrictDownloadButton.enabled = NO;
  }
  else {
    self.restrictDownloadButton.enabled = YES;
  }
  if (!tagsForCurrentApp) {
    [self fetchTagsForAppID:[[self currentSelectedApp] valueForKey:@"public_identifier"]];
  }
}

- (NSDictionary *)appForTitle:(NSString *)aTitle releaseType:(CNSHockeyAppReleaseType)aReleaseType {
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
    return [self appForTitle:[self.appNameMenu selectedItem].title releaseType:[self currentSelectedReleaseType]];
  }
  return nil;
}

- (NSArray *)tagsForCurrentSelectedApp {
  NSDictionary *appDictionary = [self currentSelectedApp];
  if (appDictionary) {
    return [self.tagsForAppID valueForKey:[appDictionary valueForKey:@"public_identifier"]];
  }
  else {
    return nil;
  }
}

- (CNSHockeyAppReleaseType)currentSelectedReleaseType {
  CNSHockeyAppReleaseType selectedReleaseType = CNSHockeyAppReleaseTypeAuto;
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

- (NSDictionary *)appForPublicIdentifier:(NSString *)identifier {
  for (NSNumber *releaseType in self.appsByReleaseType) {
    NSArray *appDictionaries = [self.appsByReleaseType objectForKey:releaseType];
    for (NSDictionary *appDictionary in appDictionaries) {
      if ([[appDictionary valueForKey:@"public_identifier"] isEqualToString:identifier]) {
        return appDictionary;
      }
    }
  }
  return nil;
}

- (void)selectAppForPublicIdentifier:(NSString *)identifier {
  NSDictionary *appDictionary = [self appForPublicIdentifier:identifier];
  if (appDictionary) {
    [self.releaseTypeMenu selectItemWithTitle:[self titleForReleaseType:[[appDictionary valueForKey:@"release_type"] integerValue]]];
    [self.appNameMenu selectItemAtIndex:[[self.appsByReleaseType objectForKey:[appDictionary valueForKey:@"release_type"]] indexOfObject:appDictionary]];
    [self reloadTagsMenu];
  }
}

- (void)setupViews {
  self.bundleIdentifierLabel.stringValue = (self.bundleIdentifier ?: @"unknown");
  self.bundleShortVersionLabel.stringValue = (self.bundleShortVersion ?: @"not set");
  self.bundleVersionLabel.stringValue = (self.bundleVersion ?: @"invalid");

  self.statusLabel.stringValue = @"";

  [self.fileTypeMenu selectItemAtIndex:(self.dsymPath ? 0 : 1)];
  [self.fileTypeMenu setEnabled:NO];

  [self readNotesType];
  [self readAfterUploadSelection];

  [self.window setTitle:[self.fileURL lastPathComponent]];

  [self readProcessArguments];
  [self fetchAppNames];

	self.analyzeBar.hidden = self.analyzeSpinner.hidden = YES;
	self.analyzeInfo.stringValue = @"";
}

- (void)hideInfoSheet {
  [self.infoSheet orderOut:self];
  [NSApp endSheet:self.infoSheet];
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
  self.bundleVersion = [NSString stringWithFormat:@"%@",[info valueForKey:@"CFBundleVersion"]];
  self.bundleShortVersion = [info valueForKey:@"CFBundleShortVersionString"];
  
  self.appStoreBuild = [self hasProvisionedDevicesInIPAAtPath:targetFilename];

  return bundleIdentifier;
}

- (BOOL)ignorePlatform:(NSString *)platform {
  return ((![platform isEqualToString:@"iOS"]) && (![platform isEqualToString:@"Mac OS"]));
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

- (CNSHockeyBuildReleaseType)hasProvisionedDevicesInIPAAtPath:(NSString *)sourcePath {
  NSTask *unzip = [[NSTask alloc] init];
  NSPipe *outPipe = [NSPipe pipe];
  NSPipe *grepPipe = [NSPipe pipe];
  [unzip setStandardOutput:grepPipe];
  [unzip setLaunchPath:@"/usr/bin/unzip"];
  [unzip setArguments:[NSArray arrayWithObjects:@"-p", sourcePath, @"Payload/*.app/embedded.mobileprovision", nil]];
  [unzip launch];

  NSTask *grep = [[NSTask alloc] init];
  [grep setStandardInput:grepPipe];
  [grep setStandardOutput:outPipe];
  [grep setLaunchPath:@"/usr/bin/egrep"];
  [grep setArguments:[NSArray arrayWithObjects:@"-a",@"-e",@"<key>ProvisionedDevices</key>|<key>ProvisionsAllDevices</key>", nil]];
  [grep launch];

  NSMutableData *result = [NSMutableData data];
  NSData *dataIn = nil;
  NSException *error = nil;

  while ((dataIn = [[outPipe fileHandleForReading] availableDataOrError:&error]) && [dataIn length] && error == nil) {
    [result appendData:dataIn];
  }

  if ([result length] > 0 && error == nil) {
    return CNSHockeyBuildReleaseTypeBeta;
  }
  if (error) {
    return CNSHockeyBuildReleaseTypeUnknown;
  }
  return CNSHockeyBuildReleaseTypeStore;
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
    
    BOOL mandatoryOn = ([self.mandatoryButton state] == NSOnState);
    if ([self.mandatoryButton isEnabled]) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"mandatory\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%d\r\n", ((mandatoryOn) ? 1 : 0)] dataUsingEncoding:NSUTF8StringEncoding]];
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
  
  if ((self.restrictDownloadButton.state == NSOnState) && ([self.selectedTags count] > 0)) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [self.selectedTags componentsJoinedByString:@","]] dataUsingEncoding:NSUTF8StringEncoding]];
  }

  return body;
}

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier publicID:(NSString *)publicID {
  NSString *boundary = @"HOCKEYAPP1234567890";

  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
  NSString *uploadURL = nil;
  if (publicID) {
    uploadURL = [NSString stringWithFormat:@"%@/api/2/apps/%@/app_versions/upload", baseURL, publicID];
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
  
  if ((self.dsymPath) && ([self.fileTypeMenu indexOfSelectedItem] != 1)) {
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"dsym\"; filename=\"%@\"\r\n", [self.dsymPath lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.dsymPath]]];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  [request setHTTPBody:body];

  [self.connectionHelpers addObject:[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseVersionResponse:) identifier:kHockeyUploadConnectionIdentifier token:self.apiToken]];
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
  if (!(error) && (self.releaseNotesField)) {
    ignoreNotesFile = YES;
    [self.releaseNotesField setString:contents];
  }
  else {
    ignoreNotesFile = NO;
  }
}

- (void)fetchAppNames {
  NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps", baseURL]]];
  [request setHTTPMethod:@"GET"];
  [request setTimeoutInterval:300];

  [self.connectionHelpers addObject:[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseAppListResponse:) identifier:nil token:self.apiToken]];
}

- (void)fetchTagsForAppID:(NSString *)appID {
  if (appID) {
    NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps/%@/tags", baseURL, appID]]];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:300];

    [self.connectionHelpers addObject:[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseAppTagsResponse:) identifier:appID token:self.apiToken]];
  }
}

- (void)checkBundleVersion:(NSString *)aBundleVersion forAppID:(NSString *)appID {
  if (aBundleVersion) {
    NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:CNSUserDefaultsHost];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/2/apps/%@/app_versions/check?bundle_version=%@", baseURL, appID, [aBundleVersion URLEncodedString]]]];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:300];

    [self.connectionHelpers addObject:[[CNSConnectionHelper alloc] initWithRequest:request delegate:self selector:@selector(parseCheckBundleVersionResponse:) identifier:appID token:self.apiToken]];
  }
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
    else if ([argument isEqualToString:@"mandatoryOn"]) {
        self.mandatoryButton.state = NSOnState;
    }
    else if ([argument isEqualToString:@"autoSubmit"]) {
      autoSubmit = YES;
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
    }
    else if ([argument hasPrefix:@"token="]) {
      self.apiToken = [[argument componentsSeparatedByString:@"="] lastObject];
    }
    else if ([argument hasPrefix:@"identifier="]) {
      self.publicIdentifier = [[argument componentsSeparatedByString:@"="] lastObject];
    }
    else if ([argument hasPrefix:@"tags="]) {
      self.selectedTags = [[[argument componentsSeparatedByString:@"="] lastObject] componentsSeparatedByString:@","];
    }
    else if ([argument hasPrefix:@"dsymPath="]) {
      self.dsymPath = [[argument componentsSeparatedByString:@"="] lastObject];
    }
    else if ([argument hasPrefix:@"ignoreExistingVersion"]) {
      self.ignoreExistingVersion = YES;
    }
  }
}

#pragma mark - CNSConnectionHelper Delegate Methods

- (void)connectionHelperDidFail:(CNSConnectionHelper *)aConnectionHelper {
  if ([aConnectionHelper.identifier isEqualToString:kHockeyUploadConnectionIdentifier]) {
    @autoreleasepool {
      NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];

      NSString *errorMessage = nil;
      if ([result length] == 0) {
        errorMessage = @"Failed: Server did not respond. Please check your network connection.";
      }
      else {
        NSDictionary *json = [result JSONValue];
        NSMutableString *serverMessage = [NSMutableString stringWithCapacity:0];

        if ([json valueForKey:@"errors"]) {
          NSDictionary *errors = [json valueForKey:@"errors"];
          for (NSString *attribute in errors) {
            [serverMessage appendFormat:@"%@ - %@. ", attribute, [[errors valueForKey:attribute] componentsJoinedByString:@" and "]];
          }
        }
        else if ([json valueForKey:@"message"]) {
          [serverMessage appendString:[json valueForKey:@"message"]];
        }

        if ([[serverMessage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
          [serverMessage setString:@"No reason specified."];
        }
        errorMessage = [NSString stringWithFormat:@"Failed. Status code: %ld. Server response: %@", aConnectionHelper.statusCode, serverMessage];
      }

      [self.errorLabel setHidden:NO];
      self.errorLabel.stringValue = errorMessage;

      self.remainingTimeLabel.stringValue = @"";
      [self.statusLabel setHidden:YES];

      self.progressIndicator.doubleValue = 0;
      [self.progressIndicator setHidden:YES];
      [self.cancelButton setTitle:@"Done"];
    }
  }
  
  [self.connectionHelpers removeObject:aConnectionHelper];
}

- (void)connectionHelper:(CNSConnectionHelper *)aConnectionHelper didProgress:(NSNumber *)progress {
  if ([aConnectionHelper.identifier isEqualToString:kHockeyUploadConnectionIdentifier]) {
    double currentProgress = self.progressIndicator.doubleValue;
    if ([progress floatValue] == 1.0) {
      self.remainingTimeLabel.stringValue = @"";
      self.statusLabel.stringValue = @"Processing...";
      self.progressIndicator.doubleValue = 100.0;
    }
    else {
      self.statusLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", [progress floatValue] * 100];
      self.progressIndicator.doubleValue = MAX([progress floatValue] * 100, currentProgress);
    }
  }
}

- (void)connectionHelper:(CNSConnectionHelper *)aConnectionHelper didEstimateRemainingTime:(NSNumber *)remainingTime {
  if ([aConnectionHelper.identifier isEqualToString:kHockeyUploadConnectionIdentifier]) {
    long timestamp = [remainingTime longValue];
    long hours = timestamp / 60 / 60;
    long minutes = timestamp / 60;
    long seconds = timestamp - hours * 60 * 60 - minutes * 60;
    
    if ((hours < 24) && (timestamp > 0)) {
      self.remainingTimeLabel.stringValue = [NSString stringWithFormat:@"Finished in %02ld:%02ld:%02ld", hours, minutes, seconds];
    }
    else {
      self.remainingTimeLabel.stringValue = @"";
    }
  }
}

- (void)parseAppListResponse:(CNSConnectionHelper *)aConnectionHelper {
  if (aConnectionHelper.statusCode == 200) {
    NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];
    NSDictionary *json = [result JSONValue];
    self.appsByReleaseType = [NSMutableDictionary dictionary];
		
    // Include only those apps which have the selected Bundle ID
    for (NSDictionary *appDict in [json objectForKey:@"apps"]) {
      if ((![[appDict objectForKey:@"bundle_identifier"] isEqualToString:self.bundleIdentifier]) ||
          ([self ignorePlatform:[appDict objectForKey:@"platform"]])) {
        continue;
      }
			
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
      
      if (self.publicIdentifier) {
        [self selectAppForPublicIdentifier:self.publicIdentifier];
      }
      else {
        [self.appNameMenu selectItemAtIndex:0];
        [self appNameMenuWasChanged:nil];
        [self readProcessArguments];
        [self releaseTypeMenuWasChanged:nil];
      }
    });
  }
  
  [self.connectionHelpers removeObject:aConnectionHelper];
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
  
  [self.connectionHelpers removeObject:aConnectionHelper];
}

- (void)parseAppTagsResponse:(CNSConnectionHelper *)aConnectionHelper {
  if (aConnectionHelper.statusCode == 200) {
    NSString *result = [[NSString alloc] initWithData:aConnectionHelper.data encoding:NSUTF8StringEncoding];
    NSDictionary *json = [result JSONValue];
		
    if (!self.tagsForAppID) {
      self.tagsForAppID = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    
    [self.tagsForAppID setValue:[json objectForKey:@"tags"] forKey:aConnectionHelper.identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self reloadTagsMenu];
    });
  }  
}

- (void)parseCheckBundleVersionResponse:(CNSConnectionHelper *)aConnectionHelper {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (aConnectionHelper.statusCode == 200) {
      [self showExistingVersionInfoSheet];
    }
    else if (aConnectionHelper.statusCode == 404) {
      // Upload
      [self startUploadWithPublicIdentifier:aConnectionHelper.identifier];
    }
    else {
      [self connectionHelperDidFail:aConnectionHelper];
    }
  });
  
  [self.connectionHelpers removeObject:aConnectionHelper];
}

#pragma mark - NSApp Delegate Methods

- (void)didEndUploadSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  [sheet orderOut:self];
  [NSApp endSheet:self.uploadSheet];
}

- (void)didEndTagSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  [NSApp endSheet:self.tagSheet];  
}

- (void)didEndInfoSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  [self hideInfoSheet];
  if (self.didClickContinueInInfoSheet) {
    NSString *sheetType = (__bridge_transfer NSString *)contextInfo;
    if ([sheetType isEqualToString:CNSExistingVersionSheet]) {
      self.skipUniqueVersionCheck = YES;
      [self startUploadWithPublicIdentifier:self.publicIdentifier];
    }
    else if ([sheetType isEqualToString:CNSReleaseTypeMismatchSheet]) {
      self.skipReleaseTypeCheck = YES;
      [self preUploadCheck];
    }
  }
  else {
    [self.uploadButton setEnabled:YES];
  }
}

#pragma mark - M3TokenController Delegate Mehtods

- (NSSet *)tagsForTokenController:(M3TokenController *)controller {
  return [NSSet setWithArray:[self tagsForCurrentSelectedApp]];
}

#pragma mark - Memory Management Mehtods

- (void) dealloc {
  [self cancelConnections];
  self.connectionHelpers = nil;
  self.afterUploadMenu = nil;
  self.bundleIdentifierLabel = nil;
  self.bundleVersionLabel = nil;
  self.bundleShortVersionLabel = nil;
  self.cancelButton = nil;
  self.cancelTagSheetButton = nil;
  self.saveTagSheetButton = nil;
  self.downloadButton = nil;
  self.errorLabel = nil;
  self.fileTypeMenu = nil;
  self.notesTypeMatrix = nil;
  self.progressIndicator = nil;
  self.releaseNotesField = nil;
	self.analyzeContainer = nil;
	self.analyzeBar = nil;
	self.analyzeFixedSizeBar = nil;
	self.analyzeImageSizeBar = nil;
	self.analyzeSavedSizeBar = nil;
	self.analyzeInfo = nil;
	self.analyzeSpinner = nil;
	self.analyzeButton = nil;
  self.releaseTypeMenu = nil;
  self.appNameMenu = nil;
  self.statusLabel = nil;
  self.uploadButton = nil;
  self.uploadSheet = nil;
  self.tagSheet = nil;
  self.tagsForAppID = nil;
  self.window = nil;
  self.tokenController = nil;
  self.continueButton = nil;
}

@end
