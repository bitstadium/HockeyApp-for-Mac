//
//  BOMProtocol.h
//  HockeyMac
//
//  Created by Oliver Michalak on 05.06.13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
	BOMProtocolPNGtoJPG = 0,
	BOMProtocolOptimizedPNG,
	BOMProtocolOptimizedJPG
} BOMProtocolType;

@interface BOMProtocol : NSObject

@property (strong) NSURL *file;
@property (assign) BOMProtocolType type;
@property (strong) NSNumber *size;
@property (strong) NSNumber *savedSize;
@property (strong) NSData *optimizedData;

+ (BOMProtocol*) protocolWithFile:(NSURL*) file ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data;
- (id) initWithFile:(NSURL*) file ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data;

@end
