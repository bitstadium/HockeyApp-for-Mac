#import "NSFileHandle+CNSAvailableData.h"

@implementation NSFileHandle (CNSAvailableData)

- (NSData *)availableDataOrError:(NSException**)returnError {
  for(;;) {
    @try {
      return [self availableData];
    }
    @catch (NSException *e) {
      if ([[e name] isEqualToString:NSFileHandleOperationException]) {
        if ([[e reason] isEqualToString:@"*** -[NSConcreteFileHandle availableData]: Interrupted system call"]) {
          continue;
        }
        if (returnError)
          *returnError = e;
        return nil;
      }
      @throw;
    }
  }
}

@end
