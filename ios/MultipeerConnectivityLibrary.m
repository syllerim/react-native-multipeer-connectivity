#import "MultipeerConnectivityLibrary.h"
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_MODULE(RNTMultipeerConnectivity, RCTEventEmitter)

RCT_EXTERN_METHOD(send:(NSString *)message);

@end

@implementation MultipeerConnectivityLibrary

RCT_EXPORT_MODULE()

@end
