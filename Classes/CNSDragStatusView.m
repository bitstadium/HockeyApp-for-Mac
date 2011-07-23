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

#import "CNSDragStatusView.h"
#import "CNSClassUtils.h"

@implementation CNSDragStatusView

@synthesize delegate;
@synthesize highlight;

#pragma mark - Initialization Methods

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
  }
  
  return self;
}

#pragma mark - Memory Management Methods

- (void)dealloc {
  self.delegate = nil;
  
  [highlightedImage release], highlightedImage = nil;
  [normalImage release], normalImage = nil;
  
  [super dealloc];
}

#pragma mark - Helper Methods

- (void)setNormalImage:(NSImage *)newNormalImage highlightedImage:(NSImage *)newHighlightedImage {
  [newNormalImage retain];
  [normalImage release];
  normalImage = newNormalImage;
  
  [newHighlightedImage retain];
  [highlightedImage release];
  highlightedImage = newHighlightedImage;
  
  [self setNeedsDisplay:YES];
}

#pragma mark NSView Methods

- (void)mouseDown:(NSEvent *)event {
  [CNSClassUtils checkDelegate:delegate performSelector:@selector(dragStatusViewWasClicked:) withObject:self];
}

- (void)drawRect:(NSRect)dirtyRect {
  if (highlight) {
    [[NSColor selectedMenuItemColor] setFill];
    NSRectFill([self bounds]);
  }
  
  if (highlight) {
    [highlightedImage drawAtPoint:NSMakePoint(5, 4) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
  }
  else {
    [normalImage drawAtPoint:NSMakePoint(5, 4) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
  }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
  return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];
  
  BOOL fileAccepted = NO;
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
    
    for (NSString *filename in filenames) {
      if (([filename hasSuffix:@".ipa"]) || ([filename hasSuffix:@".xcarchive"])) {
        fileAccepted = YES;

        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
      }
    }
  }
  
  return fileAccepted;
}

@end
