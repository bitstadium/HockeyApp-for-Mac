@interface CNSPreferencesViewController : NSWindowController <NSWindowDelegate> {
	IBOutlet NSPopUpButton *iconMenu;
	IBOutlet NSTextField *hostField;
	IBOutlet NSTextField *tokenField;
  
  BOOL isVisible;
  id delegate;
}

extern NSString *const CNSUserDefaultsHost;
extern NSString *const CNSUserDefaultsIcon;
extern NSString *const CNSUserDefaultsToken;

@property (assign) id delegate;

+ (NSString *)stringForUserDefaultKey:(NSString *)key;
+ (NSString *)stringForUserDefaultKey:(NSString *)key ifEmpty:(NSString *)fallback;

- (IBAction)iconMenuWasChanged:(id)sender;
- (IBAction)hostFieldWasChanged:(id)sender;
- (IBAction)tokenFieldWasChanged:(id)sender;

@end
