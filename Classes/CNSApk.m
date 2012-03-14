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

#import "CNSApk.h"

@implementation CNSApk

#pragma mark - NSDocument Methods

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  return YES;
}

- (NSString *)windowNibName {
  return @"CNSApk";
}

#pragma mark - NSControl Action Methods

- (IBAction)uploadButtonWasClicked:(id)sender {
  self.statusLabel.stringValue = @"Initializing...";
  self.progressIndicator.doubleValue = 0;
  [self.cancelButton setTitle:@"Cancel"];
  [self.uploadButton setEnabled:NO];
  
  [NSApp beginSheet:self.uploadSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndUploadSheet:returnCode:contextInfo:) contextInfo:nil];
  
  [self postMultiPartRequestWithBundleIdentifier:nil publicID:nil];
}

#pragma mark - Private Helper Methods

- (NSString *)bundleIdentifier {
  return nil;
}

@end
