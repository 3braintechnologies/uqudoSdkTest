#import <UqudoSDK/UQTracer.h>

@interface MyTracer : UQTracer
@property(nonatomic, retain) RCTEventEmitter *emitter;
@property(nonatomic, assign) bool hasListeners;
@end
