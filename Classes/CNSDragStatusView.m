#import "CNSDragStatusView.h"
#import "CNSClassUtils.h"

@implementation CNSDragStatusView

@synthesize delegate;
@synthesize highlight;

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
  }
  
  return self;
}

- (void)dealloc {
  self.delegate = nil;
  
  [highlightedImage release], highlightedImage = nil;
  [normalImage release], normalImage = nil;
  
  [super dealloc];
}

- (void)mouseDown:(NSEvent *)event {
  [CNSClassUtils checkDelegate:delegate performSelector:@selector(dragStatusViewWasClicked:) withObject:self];
}

- (void)setNormalImage:(NSImage *)newNormalImage highlightedImage:(NSImage *)newHighlightedImage {
  [newNormalImage retain];
  [normalImage release];
  normalImage = newNormalImage;
  
  [newHighlightedImage retain];
  [highlightedImage release];
  highlightedImage = newHighlightedImage;
  
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  if (highlight) {
    [[NSColor selectedMenuItemColor] setFill];
    NSRectFill([self bounds]);
  }
  
  if (highlight) {
    [highlightedImage drawAtPoint:CGPointMake(4, 3) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
  }
  else {
    [normalImage drawAtPoint:CGPointMake(4, 3) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
  }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
  return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
  NSPasteboard *pboard;
  NSDragOperation sourceDragMask;
  
  sourceDragMask = [sender draggingSourceOperationMask];
  pboard = [sender draggingPasteboard];
  
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
