/*****************************************************************
 M3TokenController.m
 
 Created by Martin Pilkington on 08/01/2009.
 
 Copyright (c) 2006-2009 M Cubed Software
 
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

#import "M3TokenController.h"

#import "M3TokenCloud.h"

@implementation M3TokenController

@synthesize delegate;

- (NSTokenField *)tokenField {
	return tokenField;
}

- (void)setTokenField:(NSTokenField *)field {
	if (field != tokenField) {
		//Remove the notifications from the old token field
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSControlTextDidChangeNotification" object:tokenField];
		tokenField = field;
		//And then add them to the new token field
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenFieldChanged:) name:@"NSControlTextDidChangeNotification" object:tokenField];
	}
}

- (M3TokenCloud *)tokenCloud {
	return tokenCloud;
}

- (void)setTokenCloud:(M3TokenCloud *)cloud {
	if (cloud != tokenCloud) {
		tokenCloud = cloud;
	}
}


/*
 Add the token to the token cloud. If it wasn't a duplicate then tell the delegate to add a new token
 */
- (NSArray *)tokenField:(NSTokenField *)tokField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index {
	for (NSString *token in tokens) {
		if ([tokenCloud addTokenWithString:token]) {
			if ([[self delegate] respondsToSelector:@selector(tokenController:didAddNewToken:)]) {
				[[self delegate] tokenController:self didAddNewToken:token];
			}
		}
	}
	return tokens;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	[self tokenField:tokenField shouldAddObjects:[[tokenField stringValue] componentsSeparatedByCharactersInSet:[tokenField tokenizingCharacterSet]] atIndex:0];
	[tokenCloud tokensToHighlight:[[tokenField stringValue] componentsSeparatedByCharactersInSet:[tokenField tokenizingCharacterSet]]];
}

/*
 Update the tokens that need highlighting in the token cloud
 */
- (void)tokenFieldChanged:(NSNotification *)note {
	[tokenCloud tokensToHighlight:[[tokenField stringValue] componentsSeparatedByCharactersInSet:[tokenField tokenizingCharacterSet]]];
}

/*
 If the token field exists then set the string value
 */
- (void)tokenCloud:(M3TokenCloud *)cloud didClickToken:(NSString *)str enabled:(BOOL)flag {
	if (tokenField) {
		NSMutableArray *tokens = [[[tokenField stringValue] componentsSeparatedByCharactersInSet:[tokenField tokenizingCharacterSet]] mutableCopy];
		if ([tokens containsObject:str] && !flag) {
			[tokens removeObject:str];
		} else if (![tokens containsObject:str] && flag) {
			[tokens addObject:str];
		}
		//Yeah, I only support comma as the separator for now. I'll fix this at some point
		[tokenField setStringValue:[tokens componentsJoinedByString:@","]];
		
	}
}

- (void)reloadTokens {
	if ([[self delegate] respondsToSelector:@selector(tagsForTokenController:)]) {
		NSSet *tokens = [[self delegate] tagsForTokenController:self];
		if (!tokens) {
			tokens = [NSMutableSet set];
		}
		[tokenCloud setTokens:tokens];
		[self controlTextDidEndEditing:nil];
		[tokenCloud recalculateButtonLocations];
		[tokenCloud tokensToHighlight:[[tokenField stringValue] componentsSeparatedByCharactersInSet:[tokenField tokenizingCharacterSet]]];
	}
}

/******************************
 Deal with tags auto complete
 ******************************/
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
	NSPredicate *filterPred = [NSPredicate predicateWithFormat:@"description BEGINSWITH[cd] %@", substring];
	return [[[tokenCloud tokens] filteredSetUsingPredicate:filterPred] allObjects];
}

@end
