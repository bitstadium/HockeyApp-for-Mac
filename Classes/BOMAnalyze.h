//
//  BOMAnalyze.h
//  HockeyMac
//
//  Created by Oliver Michalak on 05.06.13.
//
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
