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

#import <Cocoa/Cocoa.h>

@class CNSConnectionHelper;

@interface CNSApp : NSDocument <NSWindowDelegate> {
@private
  BOOL ignoreNotesFile;
  CNSConnectionHelper *connectionHelper;
  NSButton *__unsafe_unretained cancelButton;
	NSButton *__unsafe_unretained downloadButton;
  NSButton *__unsafe_unretained notifyButton;
  NSButton *__unsafe_unretained uploadButton;
  NSString *bundleIdentifier;
  NSString *bundleShortVersion;
  NSString *bundleVersion;
  NSMatrix *__unsafe_unretained notesTypeMatrix;
  NSMutableDictionary *appIDsAndNames;
  NSPopUpButton *__unsafe_unretained afterUploadMenu;
  NSPopUpButton *__unsafe_unretained fileTypeMenu;
  NSPopUpButton *__unsafe_unretained releaseTypeMenu;
  NSPopUpButton *__unsafe_unretained appNameMenu;
  NSProgressIndicator *__unsafe_unretained progressIndicator;
  NSTextField *__unsafe_unretained bundleIdentifierLabel;
  NSTextField *__unsafe_unretained bundleVersionLabel;
  NSTextField *__unsafe_unretained bundleShortVersionLabel;
  NSTextField *__unsafe_unretained errorLabel;
  NSTextField *__unsafe_unretained statusLabel;
  NSTextView *__unsafe_unretained releaseNotesField;
  NSWindow *__unsafe_unretained uploadSheet;
  NSWindow *__unsafe_unretained window;

  NSString* apiToken;
}

@property (unsafe_unretained) IBOutlet NSButton *cancelButton;
@property (unsafe_unretained) IBOutlet NSButton *downloadButton;
@property (unsafe_unretained) IBOutlet NSButton *notifyButton;
@property (unsafe_unretained) IBOutlet NSButton *uploadButton;
@property (unsafe_unretained) IBOutlet NSTextField *bundleIdentifierLabel;
@property (unsafe_unretained) IBOutlet NSTextField *bundleShortVersionLabel;
@property (unsafe_unretained) IBOutlet NSTextField *bundleVersionLabel;
@property (unsafe_unretained) IBOutlet NSTextField *errorLabel;
@property (unsafe_unretained) IBOutlet NSTextField *statusLabel;
@property (unsafe_unretained) IBOutlet NSTextView *releaseNotesField;
@property (unsafe_unretained) IBOutlet NSPopUpButton *afterUploadMenu;
@property (unsafe_unretained) IBOutlet NSPopUpButton *fileTypeMenu;
@property (unsafe_unretained) IBOutlet NSPopUpButton *appNameMenu;
@property (unsafe_unretained) IBOutlet NSPopUpButton *releaseTypeMenu;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressIndicator;
@property (unsafe_unretained) IBOutlet NSMatrix *notesTypeMatrix;
@property (unsafe_unretained) IBOutlet NSWindow *uploadSheet;
@property (unsafe_unretained) IBOutlet NSWindow *window;

@property (strong) CNSConnectionHelper *connectionHelper;

@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *bundleShortVersion;
@property (nonatomic, copy) NSString *bundleVersion;
@property (nonatomic, copy) NSString* apiToken;

- (IBAction)cancelButtonWasClicked:(id)sender;
- (IBAction)downloadButtonWasClicked:(id)sender;
- (IBAction)fileTypeMenuWasChanged:(id)sender;
- (IBAction)uploadButtonWasClicked:(id)sender;

- (NSMutableData *)createPostBodyWithURL:(NSURL *)ipaURL boundary:(NSString *)boundary platform:(NSString *)platform;

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier publicID:(NSString *)publicID;

@end
