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

#import "CNSApplicationDelegate.h"
#import "CNSConstants.h"
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

#if defined (CONFIGURATION_Release)
  [[BWQuincyManager sharedQuincyManager] setAppIdentifier:@"67503a7926431872c4b6c1549f5bd6b1"];
  [[BWQuincyManager sharedQuincyManager] setCompanyName:@"Codenauts UG"];
  [[BWQuincyManager sharedQuincyManager] setDelegate:self];  
#endif
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
  return YES;
}

#pragma mark - BWQuincyManagerDelegate Methods

- (void)showMainApplicationWindow {
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
  NSString *style = [CNSPreferencesViewController stringForUserDefaultKey:CNSUserDefaultsIcon ifEmpty:@"Only Dock"];
  
  if ([style isEqualToString:@"Only Menu"]) {
    if (CNS_LION_OR_GREATER) {
      ProcessSerialNumber psn = { 0, kCurrentProcess };
      TransformProcessType(&psn, 4); // kProcessTransformToUIElementApplication
    }
    
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
