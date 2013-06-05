//
//  BOMAnalyze.h
//
//  Created by Oliver Michalak on 05.06.13.
//	(c) oliver@werk01.de
//	based on http://wasted.werk01.de
//	available under the MIT license:
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "BOMProtocol.h"

@protocol BOMAnalyzeDelegate;

@interface BOMAnalyze : NSObject

@property (strong) NSURL *file;
@property (strong) NSNumber *fixedSize;
@property (strong) NSNumber *imageSize;
@property (strong) NSNumber *savedImageSize;
@property (strong) NSMutableArray *protocol;	// list of BOMProtocol
@property (assign) id<BOMAnalyzeDelegate> delegate;
@property (assign) BOOL isRunning;

- (id) initWithFile:(NSURL*) file;
- (void) start;
- (void) stop;
@end

@protocol BOMAnalyzeDelegate <NSObject>
@optional
- (void) analyzeStarted;
- (void) analyzeChanged: (NSString*) text;
- (void) analyzeFinished:(BOOL) isComplete;
@end
