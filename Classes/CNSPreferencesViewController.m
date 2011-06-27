#import "CNSPreferencesViewController.h"
#import "EMKeychainItem.h"

@implementation CNSPreferencesViewController

NSString *const CNSUserDefaultsHost = @"CNSUserDefaultsHost";
NSString *const CNSUserDefaultsToken = @"CNSUserDefaultsToken";

//- (IBAction)keychainButtonWasClicked:(id)sender {
//	NSString *email = [emailField stringValue];
//	NSString *host = [[hostField stringValue] stringByReplacingOccurrencesOfString:@"https://" withString:@""];
//	
//	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer:host withUsername:email path:nil port:0 protocol:kSecProtocolTypeAny];
//	[passwordField setStringValue:keychainItem.password];	
//	[[NSUserDefaults standardUserDefaults] setValue:keychainItem.password forKey:CNSUserDefaultsPassword];
//}

- (IBAction)hostFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[hostField stringValue] forKey:CNSUserDefaultsHost];
}	

- (IBAction)tokenFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[tokenField stringValue] forKey:CNSUserDefaultsToken];
}	

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
