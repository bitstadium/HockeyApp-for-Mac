#import "CNSApp.h"

@interface CNSArchive : CNSApp {
@private
  BOOL dsymCreated;
  BOOL ipaCreated;
  NSDictionary *info;
  NSString *dsymPath;
  NSString *ipaPath;
}

@property (nonatomic, retain) NSDictionary *info;
@property (nonatomic, retain) NSString *dsymPath;
@property (nonatomic, retain) NSString *ipaPath;

@property (nonatomic, assign) BOOL dsymCreated;
@property (nonatomic, assign) BOOL ipaCreated;

@end
