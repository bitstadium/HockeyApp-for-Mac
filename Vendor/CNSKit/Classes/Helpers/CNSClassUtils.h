@interface CNSClassUtils : NSObject {
}

+ (void)checkDelegate:(id)delegate performSelector:(SEL)selector withObject:(id)object;
+ (void)checkDelegate:(id)delegate performSelector:(SEL)selector withObject:(id)object withObject:(id)object;
+ (void)swizzleSelector:(SEL)originalSelector ofClass:(Class)klass withSelector:(SEL)newSelector;

@end
