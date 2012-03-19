#import "CNSDevice.h"

@implementation CNSDevice

- (NSString *)getUUID {
  char buffer[128];
  
  io_registry_entry_t registry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
  CFStringRef uuid = (CFStringRef)IORegistryEntryCreateCFProperty(registry, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
  IOObjectRelease(registry);
  CFStringGetCString(uuid, buffer, 128, kCFStringEncodingMacRoman);
  CFRelease(uuid);    
  
  return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end
