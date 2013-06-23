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
#import <Sparkle/Sparkle.h>
#import "CNSConstants.h"
#import "CNSDragStatusView.h"
#import "CNSPreferencesViewController.h"
#import <HockeySDK/HockeySDK.h>

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
  sparkleUpdater.feedURL = [NSURL URLWithString:@"https://rink.hockeyapp.net/api/2/apps/67503a7926431872c4b6c1549f5bd6b1"];
  [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"67503a7926431872c4b6c1549f5bd6b1" companyName:@"Bit Stadium GmbH" crashReportManagerDelegate:self];
  [[BITHockeyManager sharedHockeyManager] setExceptionInterceptionEnabled:YES];
  [[BITHockeyManager sharedHockeyManager] setAskUserDetails:YES];
  [[BITHockeyManager sharedHockeyManager] startManager];
#endif
#if defined (CONFIGURATION_Alpha)
  sparkleUpdater.feedURL = [NSURL URLWithString:@"https://rink.hockeyapp.net/api/2/apps/806ccd5cdb077a58460c28c90fdce846"];
  [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"806ccd5cdb077a58460c28c90fdce846" companyName:@"Bit Stadium GmbH" crashReportManagerDelegate:self];
  [[BITHockeyManager sharedHockeyManager] setExceptionInterceptionEnabled:YES];
  [[BITHockeyManager sharedHockeyManager] setAskUserDetails:YES];
  [[BITHockeyManager sharedHockeyManager] startManager];
#endif

  [self registerFileEvents];
}

- (void)registerFileEvents {
  self.events = [[CDEvents alloc] initWithURLs:@[[NSURL URLWithString:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Developer/Xcode/Archives"]]]
                                         block:^(CDEvents *watcher, CDEvent *event) {
                                           NSString *path = [event.URL absoluteString];
                                           if ([[path pathExtension] isEqualToString:@"xcarchive"]) {
                                             [self showUserNotificationForFileEvent:event];
                                           }
                                         }];
}

- (void)showUserNotificationForFileEvent:(CDEvent *)event {
  NSString *path = [event.URL absoluteString];
  
  NSUserNotification *notification = [[NSUserNotification alloc] init];
  notification.title = @"Xcode Archive found";
  notification.informativeText = [[path lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  notification.actionButtonTitle = @"Upload";
  notification.hasActionButton = YES;
  notification.userInfo = @{ @"fileURL" : [event.URL absoluteString] };
  
  [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
  [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  [center removeDeliveredNotification:notification];
  
  NSDictionary *userInfo = notification.userInfo;
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL URLWithString:[userInfo valueForKey:@"fileURL"]] display:YES error:NULL];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  self.events = nil;
  [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
  return YES;
}

#pragma mark - BITCrashReportManagerDelegate Methods

- (void)showMainApplicationWindow {
}

#pragma mark - Private Helper Methods

- (void)checkForUpdates:(id)sender {
  [sparkleUpdater checkForUpdates:sender];
}

- (void)createStatusItem {
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setHighlightMode:YES];

  NSMenu *menu = [[NSMenu alloc] init];
  menu.delegate = self;
  
  NSMenuItem *preferencesItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(showPreferencesView:) keyEquivalent:@""];
  [preferencesItem setTarget:self];
  [preferencesItem setEnabled:YES];
  [menu addItem:preferencesItem];
  
  NSMenuItem *sparkleItem = [[NSMenuItem alloc] initWithTitle:@"Check for Updates..." action:@selector(checkForUpdates:) keyEquivalent:@""];
  [sparkleItem setTarget:self];
  [sparkleItem setEnabled:YES];
  [menu addItem:sparkleItem];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quitApplication:) keyEquivalent:@""];
  [quitItem setTarget:self];
  [quitItem setEnabled:YES];
  [menu addItem:quitItem];
  
  
  [statusItem setMenu:menu];
  
  dragStatusView = [[CNSDragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 25, 20)];
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
    
    if (statusItem) {
      [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
      statusItem = nil;
    }
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
  dragStatusView = nil;  
	preferencesViewController = nil;
}

@end
