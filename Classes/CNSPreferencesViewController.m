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

#import "CNSPreferencesViewController.h"
#import "CNSClassUtils.h"
#import "CNSConstants.h"
#import "EMKeychainItem.h"

@interface CNSPreferencesViewController ()

- (void)loadDefaults;

@end

@implementation CNSPreferencesViewController

NSString *const CNSUserDefaultsHost = @"CNSUserDefaultsHost";
NSString *const CNSUserDefaultsIcon = @"CNSUserDefaultsIcon";
NSString *const CNSUserDefaultsToken = @"CNSUserDefaultsToken";
NSString *const CNSUserDefaultsAAPTPath = @"CNSUserDefaultsAAPTPath";
NSString *const CNSUserDefaultsNotesType = @"CNSUserDefaultsNotesType";
NSString *const CNSUserDefaultsAfterUploadSelection = @"CNSUserDefaultsAfterUploadSelection";

@synthesize delegate;

#pragma mark - Initialization Methods

- (id)init {
	if ((self = [super initWithWindowNibName:@"CNSPreferencesView"])) {
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

- (IBAction)aaptPathFieldWasChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[aaptPathField stringValue] forKey:CNSUserDefaultsAAPTPath];
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
  NSString *hostName = [[self class] stringForUserDefaultKey:CNSUserDefaultsHost];
  if ([hostName isEqualToString:kHockeyDefaultHost]) {
    [hostField setStringValue:@""];
  }
  else {
    [hostField setStringValue:hostName];
  }
	[aaptPathField setStringValue:[[self class] stringForUserDefaultKey:CNSUserDefaultsAAPTPath]];
  [iconMenu selectItemWithTitle:[[self class] stringForUserDefaultKey:CNSUserDefaultsIcon ifEmpty:@"Only Dock"]];
}

- (void)showWindow:(id)sender {
  if (!isVisible) {
    [NSBundle loadNibNamed:@"CNSPreferencesView" owner:self];
    isVisible = YES;
  }

  if (CNS_LION_OR_GREATER) {
    [menuLabel setHidden:YES];
  }
  
  self.window.delegate = self;
  
  NSToolbarItem *firstItem = [[[[self window] toolbar] items] objectAtIndex:0];
  [toolBar setSelectedItemIdentifier:[firstItem itemIdentifier]];
  
  advancedView.hidden = YES;
  generalView.hidden = NO;
  
  [self loadDefaults];
}

- (BOOL)windowShouldClose:(id)sender {
  if ([[[NSUserDefaults standardUserDefaults] valueForKey:CNSUserDefaultsHost] length] == 0) {
    [[NSUserDefaults standardUserDefaults] setValue:kHockeyDefaultHost forKey:CNSUserDefaultsHost];
  }
  
	[[NSUserDefaults standardUserDefaults] setValue:[iconMenu titleOfSelectedItem] forKey:CNSUserDefaultsIcon];
	[[NSUserDefaults standardUserDefaults] setValue:[tokenField stringValue] forKey:CNSUserDefaultsToken];
  [[NSUserDefaults standardUserDefaults] synchronize];

	isVisible = NO;

  return YES;
}

#pragma mark - NSToolbar Delegate

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  NSMutableArray * identifiers = [NSMutableArray array];
  for (NSToolbarItem * item in [toolbar items]) {
    [identifiers addObject:[item itemIdentifier]];
  }
  return identifiers;
}

- (IBAction)toolbarItemWasClicked:(NSToolbarItem *)sender {
  if (sender.tag == 0) {
    advancedView.hidden = YES;
    generalView.hidden = NO;
  }
  else {
    advancedView.hidden = NO;
    generalView.hidden = YES;
  }
}

#pragma mark - Memory Management Methods

- (void)dealloc {
  self.delegate = nil;
  
}

@end
