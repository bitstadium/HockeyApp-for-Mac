/*****************************************************************
 M3TokenCloud.h
 
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
#import <Cocoa/Cocoa.h>

@class M3TokenController;
@interface M3TokenCloud : NSView{
	NSMutableSet *tokens;
	NSMutableDictionary *tokenButtons;
	NSRect prevRect;
	IBOutlet id controller;
	id delegate;
	float preferredHeight;
	BOOL setup;
}

@property  id controller;
@property  id delegate;
@property  NSSet *tokens;
- (BOOL)addTokenWithString:(NSString *)token;
- (void)removeTokenWithString:(NSString *)token;
- (void)tokensToHighlight:(NSArray *)tokensArray;
- (void)recalculateButtonLocations;
@property (readonly) float preferredHeight;

@end

@interface M3TokenCloud (DelegateMethods)

- (void)tokenCloud:(M3TokenCloud *)cloud didChangePreferredHeightTo:(float)newHeight;

@end


/**Ignore stuff below here**/

@interface M3TokenCloud (ControllerMethods)

- (void)tokenCloud:(M3TokenCloud *)cloud didClickToken:(NSString *)str enabled:(BOOL)flag;

@end

@interface M3TokenButton : NSButton
{
	
}

- (NSRect)boundingRect;

@end



@interface M3TokenButtonCell : NSButtonCell
{
	
}

@end
