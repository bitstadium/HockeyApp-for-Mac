#import "CNSApplicationDelegate.h"
#import "CNSPreferencesViewController.h"

@implementation CNSApplicationDelegate

- (id)init {
  self = [super init];
  if (self) {
  }
  
  return self;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return NO;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:CNSUserDefaultsToken] length] == 0) {
		[self showPreferencesView:self];
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
  return YES;
}

- (IBAction)showPreferencesView:(id)sender {
	if (!preferencesViewController) {
		preferencesViewController = [[CNSPreferencesViewController alloc] init];
	}
	[preferencesViewController showWindow:self];
}

- (void)dealloc {
	[preferencesViewController release];
  [super dealloc];
}

@end
