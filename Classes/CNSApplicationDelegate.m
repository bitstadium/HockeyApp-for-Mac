#import "CNSApplicationDelegate.h"
#import "CNSDragStatusView.h"
#import "CNSPreferencesViewController.h"

@interface CNSApplicationDelegate ()

- (void)setIconStyle;

@end

@implementation CNSApplicationDelegate

#pragma mark - Initialization Methods

- (id)init {
  self = [super init];
  if (self) {
  }
  
  return self;
}

#pragma mark - NSApplicationDelegate Methods

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return NO;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
  [self setIconStyle];
  
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:CNSUserDefaultsToken] length] == 0) {
		[self showPreferencesView:self];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
  return YES;
}

#pragma mark - Private Helper Methods

- (void)createStatusItem {
  statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
  [statusItem setHighlightMode:YES];

  NSMenu *menu = [[NSMenu alloc] init];
  menu.delegate = self;
  
  NSMenuItem *preferencesItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(showPreferencesView:) keyEquivalent:@""];
  [preferencesItem setTarget:self];
  [preferencesItem setEnabled:YES];
  [menu addItem:preferencesItem];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quitApplication:) keyEquivalent:@""];
  [quitItem setTarget:self];
  [quitItem setEnabled:YES];
  [menu addItem:quitItem];
  
  [quitItem release];
  
  [statusItem setMenu:menu];
  [menu release];
  
  dragStatusView = [[CNSDragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 24, 20)];
  [dragStatusView setDelegate:self];
  [dragStatusView setNormalImage:[NSImage imageNamed:@"MenuIconNormal"] highlightedImage:[NSImage imageNamed:@"MenuIconHighlighted"]];
  [statusItem setView:dragStatusView];
}

- (void)setIconStyle {
  NSString *style = [CNSPreferencesViewController stringForUserDefaultKey:CNSUserDefaultsIcon ifEmpty:@"Only Menu"];
  
  if ([style isEqualToString:@"Only Menu"]) {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    
    if (!statusItem) {
      [self createStatusItem];
    }
  }
  else if ([style isEqualToString:@"Only Dock"]) {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [statusItem release], statusItem = nil;
  }
  else {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    if (!statusItem) {
      [self createStatusItem];
    }
  }
}

#pragma mark - Action Methods

- (void)dragStatusViewWasClicked:(id)dragView {
  [statusItem popUpStatusItemMenu:[statusItem menu]];
}

- (void)quitApplication:(id)sender {
  exit(1);
}

- (IBAction)showPreferencesView:(id)sender {
	if (!preferencesViewController) {
		preferencesViewController = [[CNSPreferencesViewController alloc] init];
    preferencesViewController.delegate = self;
	}
	[preferencesViewController showWindow:self];
  [preferencesViewController.window makeKeyAndOrderFront:self];
}

#pragma mark - NSMenuDelegate Methods

- (void)menuWillOpen:(NSMenu *)menu {
  [statusItem drawStatusBarBackgroundInRect:dragStatusView.bounds withHighlight:YES];
  dragStatusView.highlight = YES;
  [dragStatusView setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
  [statusItem drawStatusBarBackgroundInRect:dragStatusView.bounds withHighlight:NO];
  dragStatusView.highlight = NO;
  [dragStatusView setNeedsDisplay:YES];
}

#pragma mark - Memory Management Methods

- (void)dealloc {
  [dragStatusView release], dragStatusView = nil;  
	[preferencesViewController release], preferencesViewController = nil;
  [super dealloc];
}

@end
