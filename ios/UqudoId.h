#import <React/RCTBridgeModule.h>
#import <UqudoSDK/UqudoSDK.h>
#import <React/RCTEventEmitter.h>

@interface UqudoId : RCTEventEmitter <RCTBridgeModule, UQBuilderControllerDelegate>
@property (nonatomic, strong) RCTPromiseResolveBlock promiseResolve;
@property (nonatomic, strong) RCTPromiseRejectBlock promiseReject;
@end
