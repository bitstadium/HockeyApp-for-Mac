#import "CNSClassUtils.h"
#import </usr/include/objc/objc-class.h>

@implementation CNSClassUtils

+ (void)checkDelegate:(id)delegate performSelector:(SEL)selector withObject:(id)object {
  if ([delegate respondsToSelector:selector]) {
    [delegate performSelector:selector withObject:object];
  }
}

+ (void)checkDelegate:(id)delegate performSelector:(SEL)selector withObject:(id)object0 withObject:(id)object1 {
  if ([delegate respondsToSelector:selector]) {
    [delegate performSelector:selector withObject:object0 withObject:object1];
  }
}

+ (void)swizzleSelector:(SEL)originalSelector ofClass:(Class)klass withSelector:(SEL)newSelector {
  Method originalMethod = class_getInstanceMethod(klass, originalSelector);
  Method newMethod = class_getInstanceMethod(klass, newSelector);
  
  if (class_addMethod(klass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
    class_replaceMethod(klass, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  }
  else {
    method_exchangeImplementations(originalMethod, newMethod);
  }  
}

@end
