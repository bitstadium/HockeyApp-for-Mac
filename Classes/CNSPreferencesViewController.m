#import "CNSPreferencesViewController.h"
#import "CNSClassUtils.h"
#import "EMKeychainItem.h"

@interface CNSPreferencesViewController ()

- (void)loadDefaults;

@end

@implementation CNSPreferencesViewController

NSString *const CNSUserDefaultsHost = @"CNSUserDefaultsHost";
NSString *const CNSUserDefaultsIcon = @"CNSUserDefaultsIcon";
NSString *const CNSUserDefaultsToken = @"CNSUserDefaultsToken";

@synthesize delegate;

#pragma mark - Initialization Methods

- (id)init {
	if ([super initWithWindowNibName:@"CNSPreferencesView"]) {
    [self loadDefaults];
    isVisible = NO;
	}
  
	return self;
}

#pragma mark NSControl Action Methods

- (IBAction)hostFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[hostField stringValue] forKey:CNSUserDefaultsHost];
  [[NSUserDefaults standardUserDefaults] synchronize];
}	

- (IBAction)iconMenuWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[iconMenu titleOfSelectedItem] forKey:CNSUserDefaultsIcon];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [CNSClassUtils checkDelegate:self.delegate performSelector:@selector(setIconStyle) withObject:nil];
}

- (IBAction)tokenFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[tokenField stringValue] forKey:CNSUserDefaultsToken];
  [[NSUserDefaults standardUserDefaults] synchronize];
}	

#pragma mark - Helper Methods

+ (NSString *)stringForUserDefaultKey:(NSString *)key ifEmpty:(NSString *)fallback {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *value = [userDefaults valueForKey:key];
	if ([value length] == 0) {
		return fallback;
	}
	else {
		return value;
	}
}

+ (NSString *)stringForUserDefaultKey:(NSString *)key {
	return [self stringForUserDefaultKey:key ifEmpty:@""];
}	

- (void)loadDefaults {
	[tokenField setStringValue:[[self class] stringForUserDefaultKey:CNSUserDefaultsToken]];
	[hostField setStringValue:[[self class] stringForUserDefaultKey:CNSUserDefaultsHost ifEmpty:@"https://beta.hockeyapp.net"]];
  [iconMenu selectItemWithTitle:[[self class] stringForUserDefaultKey:CNSUserDefaultsIcon ifEmpty:@"Only Menu"]];
}

- (void)showWindow:(id)sender {
  if (!isVisible) {
    [NSBundle loadNibNamed:@"CNSPreferencesView" owner:self];
    isVisible = YES;
  }
  
  self.window.delegate = self;
  [self loadDefaults];
}

- (BOOL)windowShouldClose:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[hostField stringValue] forKey:CNSUserDefaultsHost];
	[[NSUserDefaults standardUserDefaults] setValue:[iconMenu titleOfSelectedItem] forKey:CNSUserDefaultsIcon];
	[[NSUserDefaults standardUserDefaults] setValue:[tokenField stringValue] forKey:CNSUserDefaultsToken];
  [[NSUserDefaults standardUserDefaults] synchronize];

	isVisible = NO;

  return YES;
}

#pragma mark - Memory Management Methods

- (void)dealloc {
  self.delegate = nil;
  
  [super dealloc];
}

@end
