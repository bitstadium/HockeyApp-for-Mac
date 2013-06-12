//
//  BOMProtocol.m
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

#import "BOMProtocol.h"
#import "FileSizeNumberFormatter.h"

@implementation BOMProtocol

+ (BOMProtocol*) protocolWithFile:(NSURL*) file atFolder:(NSURL*) rootFolder ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data {
	return [[BOMProtocol alloc] initWithFile:file atFolder:(NSURL*) rootFolder ofType:type originalSize:size savedSize:savedSize data:data];
}

- (id) initWithFile:(NSURL*) file atFolder:(NSURL*) rootFolder ofType:(BOMProtocolType) type originalSize:(NSNumber*) size savedSize:(NSNumber*) savedSize data:(NSData*) data {
	if ((self = [super init])) {
		self.file = file;
		self.rootFolder = rootFolder;
		self.type = type;
		self.size = size;
		self.savedSize = savedSize;
		self.optimizedData = data;
	}
	return self;
}

- (NSString*) description {
	FileSizeNumberFormatter *sizeFormatter = [[FileSizeNumberFormatter alloc] init];
	sizeFormatter.maximumFractionDigits = 2;
	NSString *typeString = @"convert opaque PNG to JPG";
	switch (self.type) {
		case BOMProtocolOptimizedPNG:
			typeString = @"re-quantify PNG";
			break;
		case BOMProtocolOptimizedJPG:
			typeString = @"re-compress JPG";
			break;
		default:;
	}
	NSString *filePath = [self.file.path substringFromIndex: self.rootFolder.path.length+1];
	return [NSString stringWithFormat:@"%@;%@;%@;%@;%@;%ld;%d%%;;;", filePath, typeString, [sizeFormatter stringFromNumber:self.size], self.size, [sizeFormatter stringFromNumber: [NSNumber numberWithLong:self.optimizedData.length]], self.optimizedData.length, (int)round((self.savedSize.longValue*100.0)/(float)self.size.longValue)];
}
@end
