@interface CNSPreferencesViewController : NSWindowController {
	IBOutlet NSTextField *hostField;
	IBOutlet NSTextField *tokenField;
}

extern NSString *const CNSUserDefaultsHost;
extern NSString *const CNSUserDefaultsToken;

- (IBAction)hostFieldWasChanged:(id)sender;
- (IBAction)tokenFieldWasChanged:(id)sender;

@end
