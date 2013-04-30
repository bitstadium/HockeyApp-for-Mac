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

#import "CNSConnectionHelper.h"
#import "CNSLogHelper.h"
#import "CNSPreferencesViewController.h"
#import "NSString+CNSStringAdditions.h"

@interface CNSConnectionHelper ()

- (void)releaseConnection;

@end

@implementation CNSConnectionHelper

@synthesize data;
@synthesize identifier;
@synthesize statusCode;

#pragma mark -
#pragma mark Initialization

- (id)initWithRequest:(NSMutableURLRequest *)request delegate:(id)aDelegate selector:(SEL)aSelector identifier:(NSString *)anIdentifier token:(NSString*)token {
  if ((self = [super init])) {
    delegate = [aDelegate retain];
    selector = aSelector;
    
    data = [[NSMutableData alloc] init];
    identifier = [anIdentifier retain];
    
    if (token == nil) {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      token	= [defaults valueForKey:CNSUserDefaultsToken];
    }
    [request addValue:token	forHTTPHeaderField:@"X-HockeyAppToken"];
    
    lastAverage = 0;
    startDate = [[NSDate date] retain];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self performSelector:@selector(estimateRemaingTime) withObject:nil afterDelay:1.0];
  }
  return self;
}

- (void)cancelConnection {
  [connection cancel];
  [self releaseConnection];
}

#pragma mark -
#pragma mark Memory Management Methods

- (void)releaseConnection {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(estimateRemaingTime) object:nil];

  [startDate release];
  startDate = nil;
  
  [delegate release];
  delegate = nil;
  
  [connection release];
  connection = nil;
}

- (void)dealloc {
  [data release];
  data = nil;
	
	[identifier release];

  [self releaseConnection];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Connection Delegate Methods

#ifdef DEBUG
- (BOOL)connection:(NSURLConnection *)aConnection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)space {
  return [[space authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
  }
}  
#endif

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)response {
  statusCode = [response statusCode];
  [data setLength:0];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)receivedData {
	[data appendData:receivedData];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  if ([delegate respondsToSelector:@selector(connectionHelperDidFail:)]) {
    [delegate performSelector:@selector(connectionHelperDidFail:) withObject:self];
  }

  [self releaseConnection];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  bytesUploaded = totalBytesWritten;
  remaingBytesToUpload = totalBytesExpectedToWrite - totalBytesWritten;
  
  if ([delegate respondsToSelector:@selector(connectionHelper:didProgress:)]) {
    [delegate performSelector:@selector(connectionHelper:didProgress:) withObject:self withObject:[NSNumber numberWithFloat:(float)totalBytesWritten / (float)totalBytesExpectedToWrite]];
  }
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
  if ([delegate respondsToSelector:@selector(connectionHelperDidFail:)]) {
    [delegate performSelector:@selector(connectionHelperDidFail:) withObject:self];
  }
  
  [self releaseConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if ([delegate respondsToSelector:selector]) {
    [delegate performSelectorInBackground:selector withObject:self];
  }
  
  [self releaseConnection];
}

#pragma mark -
#pragma mark Time Helper Methods

- (void)estimateRemaingTime {
  double average = [startDate timeIntervalSinceNow] * -1.f / bytesUploaded;
  lastAverage = (lastAverage == 0 ? average : lastAverage);
  lastAverage = 0.9 * lastAverage + 0.1 * average;
  long remainingTime = remaingBytesToUpload * lastAverage;

  if ([delegate respondsToSelector:@selector(connectionHelper:didEstimateRemainingTime:)]) {
    [delegate performSelector:@selector(connectionHelper:didEstimateRemainingTime:) withObject:self withObject:[NSNumber numberWithLong:remainingTime]];
  }
  
  [self performSelector:@selector(estimateRemaingTime) withObject:nil afterDelay:1.0];
}

@end
