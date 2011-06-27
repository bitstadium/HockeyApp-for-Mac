#import "CNSPreferencesViewController.h"
#import "EMKeychainItem.h"

@implementation CNSPreferencesViewController

NSString *const CNSUserDefaultsHost = @"CNSUserDefaultsHost";
NSString *const CNSUserDefaultsToken = @"CNSUserDefaultsToken";

#pragma mark NSControl Action Methods

- (IBAction)hostFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[hostField stringValue] forKey:CNSUserDefaultsHost];
}	

- (IBAction)tokenFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[tokenField stringValue] forKey:CNSUserDefaultsToken];
}	

#pragma mark Helper Methods

- (NSString *)stringForUserDefaultKey:(NSString *)key ifEmpty:(NSString *)fallback {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *value = [userDefaults valueForKey:key];
	if ([value length] == 0) {
		return fallback;
	}
	else {
		return value;
	}
}

- (NSString *)stringForUserDefaultKey:(NSString *)key {
	return [self stringForUserDefaultKey:key ifEmpty:@""];
}	

- (void)showWindow:(id)sender {
	[NSBundle loadNibNamed:@"CNSPreferencesView" owner:self];
	
	[tokenField setStringValue:[self stringForUserDefaultKey:CNSUserDefaultsToken]];
	[hostField setStringValue:[self stringForUserDefaultKey:CNSUserDefaultsHost ifEmpty:@"https://beta.hockeyapp.net"]];
}

@end
