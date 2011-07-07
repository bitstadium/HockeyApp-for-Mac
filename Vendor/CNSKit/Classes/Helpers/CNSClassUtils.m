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
