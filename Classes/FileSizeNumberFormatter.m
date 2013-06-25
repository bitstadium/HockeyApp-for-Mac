//
//  FileSize.h
//  Created by Oliver Michalak on 05.06.13.
//	(c) oliver@werk01.de
//	based on http://stackoverflow.com/a/2975631
//	available under the MIT license:
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "FileSizeNumberFormatter.h"

static const char sUnits[] = { '\0', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' };
static int sMaxUnits = sizeof sUnits - 1;

@implementation FileSizeNumberFormatter

- (NSString *) stringFromNumber:(NSNumber*) number {
	int multiplier = 1024; // 1000
	int exponent = 0;
	
	double bytes = [number doubleValue];
	
	while ((bytes >= multiplier) && (exponent < sMaxUnits)) {
		bytes /= multiplier;
		exponent++;
	}
	
	return [NSString stringWithFormat:@"%@ %cB", [super stringFromNumber: [NSNumber numberWithDouble: bytes]], sUnits[exponent]];
}

@end
