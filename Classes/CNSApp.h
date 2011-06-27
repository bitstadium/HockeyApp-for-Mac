#import <Cocoa/Cocoa.h>

@class CNSConnectionHelper;

@interface CNSApp : NSDocument {
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
