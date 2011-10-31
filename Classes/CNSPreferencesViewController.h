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

@interface CNSPreferencesViewController : NSWindowController <NSWindowDelegate> {
	IBOutlet NSPopUpButton *iconMenu;
	IBOutlet NSTextField *hostField;
	IBOutlet NSTextField *menuLabel;
	IBOutlet NSTextField *tokenField;
  
  BOOL isVisible;
  id delegate;
}

extern NSString *const CNSUserDefaultsHost;
extern NSString *const CNSUserDefaultsIcon;
extern NSString *const CNSUserDefaultsToken;
extern NSString *const CNSUserDefaultsNotesType;
extern NSString *const CNSUserDefaultsAfterUploadSelection;

@property (assign) id delegate;

+ (NSString *)stringForUserDefaultKey:(NSString *)key;
+ (NSString *)stringForUserDefaultKey:(NSString *)key ifEmpty:(NSString *)fallback;

- (IBAction)iconMenuWasChanged:(id)sender;
- (IBAction)hostFieldWasChanged:(id)sender;
- (IBAction)tokenFieldWasChanged:(id)sender;

@end
