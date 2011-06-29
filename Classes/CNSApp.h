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
  NSButton *uploadButton;
  NSMatrix *notesTypeMatrix;
  NSProgressIndicator *progressIndicator;
  NSTextField *statusLabel;
  NSTextView *releaseNotesField;
  NSWindow *uploadSheet;
  NSWindow *window;
}

@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSButton *downloadButton;
@property (assign) IBOutlet NSButton *uploadButton;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSTextView *releaseNotesField;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSMatrix *notesTypeMatrix;
@property (assign) IBOutlet NSWindow *uploadSheet;
@property (assign) IBOutlet NSWindow *window;

@property (retain) CNSConnectionHelper *connectionHelper;

- (IBAction)uploadButtonWasClicked:(id)sender;
- (IBAction)cancelButtonWasClicked:(id)sender;

- (NSMutableData *)createPostBodyWithURL:(NSURL *)ipaURL boundary:(NSString *)boundary;

@end
