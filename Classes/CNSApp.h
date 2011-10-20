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
  CNSConnectionHelper *connectionHelper;
  NSButton *cancelButton;
	NSButton *downloadButton;
  NSButton *notifyButton;
  NSButton *uploadButton;
  NSString *bundleIdentifier;
  NSString *bundleShortVersion;
  NSString *bundleVersion;
  NSMatrix *notesTypeMatrix;
  NSPopUpButton *fileTypeMenu;
  NSProgressIndicator *progressIndicator;
  NSTextField *bundleIdentifierLabel;
  NSTextField *bundleVersionLabel;
  NSTextField *bundleShortVersionLabel;
  NSTextField *errorLabel;
  NSTextField *statusLabel;
  NSTextView *releaseNotesField;
  NSWindow *uploadSheet;
  NSWindow *window;
}

@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSButton *downloadButton;
@property (assign) IBOutlet NSButton *notifyButton;
@property (assign) IBOutlet NSButton *uploadButton;
@property (assign) IBOutlet NSTextField *bundleIdentifierLabel;
@property (assign) IBOutlet NSTextField *bundleShortVersionLabel;
@property (assign) IBOutlet NSTextField *bundleVersionLabel;
@property (assign) IBOutlet NSTextField *errorLabel;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSTextView *releaseNotesField;
@property (assign) IBOutlet NSPopUpButton *fileTypeMenu;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSMatrix *notesTypeMatrix;
@property (assign) IBOutlet NSWindow *uploadSheet;
@property (assign) IBOutlet NSWindow *window;

@property (retain) CNSConnectionHelper *connectionHelper;

@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *bundleShortVersion;
@property (nonatomic, copy) NSString *bundleVersion;

- (IBAction)cancelButtonWasClicked:(id)sender;
- (IBAction)downloadButtonWasClicked:(id)sender;
- (IBAction)fileTypeMenuWasChanged:(id)sender;
- (IBAction)uploadButtonWasClicked:(id)sender;

- (NSMutableData *)createPostBodyWithURL:(NSURL *)ipaURL boundary:(NSString *)boundary platform:(NSString *)platform;

- (void)postMultiPartRequestWithBundleIdentifier:(NSString *)bundleIdentifier;

@end
