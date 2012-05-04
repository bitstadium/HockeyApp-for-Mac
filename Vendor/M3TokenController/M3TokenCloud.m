/*****************************************************************
 M3TokenCloud.m
 
 Created by Martin Pilkington on 08/01/2009.
 
 Copyright (c) 2006-2009 M Cubed Software
 Parts of M3TokenButtonCell adapted from BWTokenAttachmentCell created by Brandon Walkin (www.brandonwalkin.com)
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 *****************************************************************/

#import "M3TokenCloud.h"


@implementation M3TokenCloud

@synthesize controller;
@synthesize preferredHeight;
@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		tokens = [[NSMutableSet alloc] init];
		tokenButtons = [[NSMutableDictionary alloc] init];
		prevRect = NSZeroRect;
		preferredHeight = -1;
    }
    return self;
}

- (NSSet *)tokens {
	return [tokens copy];
}

- (void)setTokens:(NSSet *)set {
	//Find the tokens that aren't in the new set and remove them from the view
	[tokens minusSet:set];
	for (NSString *title in [tokens allObjects]) {
		[[tokenButtons objectForKey:title] removeFromSuperview];
		[tokenButtons removeObjectForKey:title];
	}
	
	tokens = [set mutableCopy];
	
	//Create new buttons
	for (NSString *title in [tokens allObjects]) {
		if (![tokenButtons objectForKey:title] && [title length]) {
			M3TokenButton *button = [[M3TokenButton alloc] initWithFrame:NSMakeRect(0, 0, 50, 20)];
			[button setTitle:title];
			[button setTarget:self];
			[button setAction:@selector(buttonClicked:)];
			[tokenButtons setObject:button forKey:title];
		}
	}
}


- (void)drawRect:(NSRect)rect {
	[self recalculateButtonLocations];
}

- (void)recalculateButtonLocations {
	//Get all our buttons sorted alphabetically by their title
	NSArray *buttons = [[tokenButtons allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
	int index = 0;
	
	NSMutableArray *rowsArray = [NSMutableArray array];
	//Loop through buttons assigning them to rows
	while (index < [buttons count]) {
		float x = 0;
		float rowWidth = 0;
		NSMutableArray *row = [NSMutableArray array];
		while (x < [self bounds].size.width) {
			M3TokenButton *button = [buttons objectAtIndex:index];
			x += [button boundingRect].size.width + 4;
			rowWidth += [button boundingRect].size.width;
			//If this button puts us over the width of the view then break and move to the next line, if the button's bounding rect is greater than the size of the view then draw anyway and trim.
			if (x > [self bounds].size.width && [button boundingRect].size.width + 4 < [self bounds].size.width) {
				rowWidth -= [button boundingRect].size.width;
				break;
			}
			[row addObject:button];
			index++;
			if (index >= [buttons count])
				break;
		}
		[rowsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:row, @"row", [NSNumber numberWithFloat:rowWidth], @"rowWidth", nil]];
	}
	
	//Now position the bloody things
	float y = [self bounds].size.height - 20;
	for (NSDictionary *row in rowsArray) {
		float x = 0;
		
		float rowWidth = [[row objectForKey:@"rowWidth"] floatValue];
		NSArray *rowArray = [row objectForKey:@"row"];
		float spacing = ([self bounds].size.width - rowWidth) / ([rowArray count] - 1);
		
		for (M3TokenButton *button in rowArray) {
			[button setFrameOrigin:NSMakePoint(x, y)];
			if ([rowsArray count] > 1) {
				x += [button boundingRect].size.width + spacing;
			} else {
				x += [button boundingRect].size.width + 4;
			}
			if (![button superview])
				[self addSubview:button];
		}
		y -= 24;
	}
	//Send the new preferred height to the delegate
	float newPreferredHeight = 24 * [rowsArray count];
	if (newPreferredHeight != preferredHeight && setup) {
		if ([[self delegate] respondsToSelector:@selector(tokenCloud:didChangePreferredHeightTo:)]) {
			[[self delegate] tokenCloud:self didChangePreferredHeightTo:newPreferredHeight];
		}
		preferredHeight = newPreferredHeight;
	}
	//Works around to make sure the delegate method isn't sent when the view is setup
	if (!setup)
		setup = YES;
}

- (BOOL)addTokenWithString:(NSString *)token {
	BOOL returnValue = NO;
	if (![token length]) {
		return NO;
	}
	
	if (![tokens containsObject:token]) {
		M3TokenButton *button = [[M3TokenButton alloc] initWithFrame:NSMakeRect(0, 0, 50, 20)];
		[button setTitle:token];
		[button setTarget:self];
		[button setAction:@selector(buttonClicked:)];
		[tokenButtons setObject:button forKey:token];
		[self recalculateButtonLocations];
		returnValue = YES;
	}
	
	[tokens addObject:token];
	return returnValue;
}

- (void)removeTokenWithString:(NSString *)token {
	if ([tokens containsObject:token]) {
		[[tokenButtons objectForKey:token] removeFromSuperview];
		[tokenButtons removeObjectForKey:token];
		[self recalculateButtonLocations];
	}
	[tokens removeObject:token];
}

- (void)tokensToHighlight:(NSArray *)tokensArray {
	for (NSButton *button in [tokenButtons allValues]) {
		[button setState:[tokensArray containsObject:[button title]]];
	}
}

- (void)buttonClicked:(id)sender {
	if ([[self controller] respondsToSelector:@selector(tokenCloud:didClickToken:enabled:)]) {
		[[self controller] tokenCloud:self didClickToken:[sender title] enabled:[sender state]];
	}
}

@end








@implementation M3TokenButton

+ (Class)cellClass {
	return [M3TokenButtonCell class];
}

- (void)drawRect:(NSRect)rect {
	[self setFrame:[self boundingRect]]; //Can't remember why I need to do this, but I do
	[super drawRect:[self boundingRect]];
}

- (NSRect)boundingRect {
	NSRect boundingRect = [[self attributedTitle] boundingRectWithSize:NSMakeSize(1000, [self frame].size.height) options:0];
	boundingRect.size.width += 20;
	boundingRect.size.height = [self frame].size.height;
	boundingRect.origin = [self frame].origin;
	return boundingRect;
}

@end



static NSGradient *blueStrokeGradient;
static NSGradient *blueInsetGradient;
static NSGradient *blueGradient;
static NSGradient *highlightedBlueStrokeGradient;
static NSGradient *highlightedBlueInsetGradient;
static NSGradient *highlightedBlueGradient;
static NSGradient *hoverBlueGradient;
static NSGradient *hoverBlueInsetGradient;



/*
 Yeah, most of this is borrowed from BWToolkit. Brandon Walkin++
 */
@implementation M3TokenButtonCell

/*
 Change this to play with the colours of the tokens
 */
+ (void)initialize
{
	
	NSColor *blueTopColor = [NSColor colorWithCalibratedRed:217.0/255.0 green:228.0/255.0 blue:254.0/255.0 alpha:1];
	NSColor *blueBottomColor = [NSColor colorWithCalibratedRed:195.0/255.0 green:212.0/255.0 blue:250.0/255.0 alpha:1];	
	blueGradient = [[NSGradient alloc] initWithStartingColor:blueTopColor endingColor:blueBottomColor];
	
	NSColor *blueStrokeTopColor = [NSColor colorWithCalibratedRed:164.0/255.0 green:184.0/255.0 blue:230.0/255.0 alpha:1];
	NSColor *blueStrokeBottomColor = [NSColor colorWithCalibratedRed:122.0/255.0 green:128.0/255.0 blue:199.0/255.0 alpha:1];
	blueStrokeGradient = [[NSGradient alloc] initWithStartingColor:blueStrokeTopColor endingColor:blueStrokeBottomColor];
	
	NSColor *blueInsetTopColor = [NSColor colorWithCalibratedRed:226.0/255.0 green:234.0/255.0 blue:254.0/255.0 alpha:1];
	NSColor *blueInsetBottomColor = [NSColor colorWithCalibratedRed:206.0/255.0 green:221.0/255.0 blue:250.0/255.0 alpha:1];
	blueInsetGradient = [[NSGradient alloc] initWithStartingColor:blueInsetTopColor endingColor:blueInsetBottomColor];
	
	NSColor *highlightedBlueTopColor = [NSColor colorWithCalibratedRed:80.0/255.0 green:127.0/255.0 blue:251.0/255.0 alpha:1];
	NSColor *highlightedBlueBottomColor = [NSColor colorWithCalibratedRed:65.0/255.0 green:107.0/255.0 blue:236.0/255.0 alpha:1];	
	highlightedBlueGradient = [[NSGradient alloc] initWithStartingColor:highlightedBlueTopColor endingColor:highlightedBlueBottomColor];	
	
	NSColor *highlightedBlueStrokeTopColor = [NSColor colorWithCalibratedRed:51.0/255.0 green:95.0/255.0 blue:248.0/255.0 alpha:1];
	NSColor *highlightedBlueStrokeBottomColor = [NSColor colorWithCalibratedRed:42.0/255.0 green:47.0/255.0 blue:233.0/255.0 alpha:1];
	highlightedBlueStrokeGradient = [[NSGradient alloc] initWithStartingColor:highlightedBlueStrokeTopColor endingColor:highlightedBlueStrokeBottomColor];
	
	NSColor *highlightedBlueInsetTopColor = [NSColor colorWithCalibratedRed:92.0/255.0 green:137.0/255.0 blue:251.0/255.0 alpha:1];
	NSColor *highlightedBlueInsetBottomColor = [NSColor colorWithCalibratedRed:76.0/255.0 green:116.0/255.0 blue:236.0/255.0 alpha:1];
	highlightedBlueInsetGradient = [[NSGradient alloc] initWithStartingColor:highlightedBlueInsetTopColor endingColor:highlightedBlueInsetBottomColor];
	
	NSColor *hoverBlueTopColor = [NSColor colorWithCalibratedRed:195.0/255.0 green:207.0/255.0 blue:243.0/255.0 alpha:1];
	NSColor *hoverBlueBottomColor = [NSColor colorWithCalibratedRed:176.0/255.0 green:193.0/255.0 blue:239.0/255.0 alpha:1];	
	hoverBlueGradient = [[NSGradient alloc] initWithStartingColor:hoverBlueTopColor endingColor:hoverBlueBottomColor];
	
	NSColor *hoverBlueInsetTopColor = [NSColor colorWithCalibratedRed:204.0/255.0 green:2137.0/255.0 blue:243.0/255.0 alpha:1];
	NSColor *hoverBlueInsetBottomColor = [NSColor colorWithCalibratedRed:186.0/255.0 green:201.0/255.0 blue:239.0/255.0 alpha:1];	
	hoverBlueInsetGradient = [[NSGradient alloc] initWithStartingColor:hoverBlueInsetTopColor endingColor:hoverBlueInsetBottomColor];
}


- (BOOL)allowsMixedState {
	return NO;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	float scaleFactor = [[NSScreen mainScreen] userSpaceScaleFactor];
	
	NSRect drawingRect = [self drawingRectForBounds:cellFrame];
	NSRect insetRect = NSInsetRect(drawingRect, 1 / scaleFactor, 1 / scaleFactor);
	NSRect insetRect2 = NSInsetRect(insetRect, 1 / scaleFactor, 1 / scaleFactor);
	
	if (scaleFactor < 0.99 || scaleFactor > 1.01)
	{
		drawingRect = [controlView centerScanRect:drawingRect];
		insetRect = [controlView centerScanRect:insetRect];
		insetRect2 = [controlView centerScanRect:insetRect2];		
	}
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRoundedRect:drawingRect xRadius:0.5*drawingRect.size.height yRadius:0.5*drawingRect.size.height];
	NSBezierPath *insetPath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:0.5*insetRect.size.height yRadius:0.5*insetRect.size.height];
	NSBezierPath *insetPath2 = [NSBezierPath bezierPathWithRoundedRect:insetRect2 xRadius:0.5*insetRect2.size.height yRadius:0.5*insetRect2.size.height];
	
	NSMutableAttributedString *str = [[self attributedTitle] mutableCopy];
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setAlignment:NSCenterTextAlignment];
	[str setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName, [NSFont systemFontOfSize:12], NSFontAttributeName, style, NSParagraphStyleAttributeName, nil] range:NSMakeRange(0, [str length])];
	if ([self isHighlighted]) {
		[blueStrokeGradient drawInBezierPath:drawingPath angle:90];
		[hoverBlueInsetGradient drawInBezierPath:insetPath angle:90];
		[hoverBlueGradient drawInBezierPath:insetPath2 angle:90];
	} else if ([self state] == NSOffState) {
		[blueStrokeGradient drawInBezierPath:drawingPath angle:90];
		[blueInsetGradient drawInBezierPath:insetPath angle:90];
		[blueGradient drawInBezierPath:insetPath2 angle:90];
	} else {
		[str setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [NSFont systemFontOfSize:12], NSFontAttributeName, style, NSParagraphStyleAttributeName, nil] range:NSMakeRange(0, [str length])];
		
		[highlightedBlueStrokeGradient drawInBezierPath:drawingPath angle:90];
		[highlightedBlueInsetGradient drawInBezierPath:insetPath angle:90];
		[highlightedBlueGradient drawInBezierPath:insetPath2 angle:90];
	} 
	
	NSRect textRect = drawingRect;
	
	textRect.size.height = 16;
	textRect.origin.y = (drawingRect.size.height - 14) / 2;
	
	[str drawInRect:textRect];
}

- (NSRect)drawingRectForBounds:(NSRect)bounds {
	return NSMakeRect(1, 1, bounds.size.width - 3, bounds.size.height - 3);
}

@end


