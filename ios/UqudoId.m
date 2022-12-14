#import "UqudoId.h"
#import <UqudoSDK/UqudoSDK.h>
#import "MyTracer.h"

@implementation UqudoId

MyTracer *tracer;

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(init:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    tracer = [[MyTracer alloc] init];
    tracer.emitter = self;
    [[UQBuilderController alloc] initWithTracer:tracer];
}

RCT_EXPORT_METHOD(setLocale:(NSString *)locale resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:locale, nil]forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

RCT_EXPORT_METHOD(enroll:(NSString *)enrollObj resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    self.promiseResolve = resolve;
    self.promiseReject = reject;
    
    @try {
        if (enrollObj != nil && [enrollObj length] > 0) {
            NSData* data = [enrollObj dataUsingEncoding:NSUTF8StringEncoding];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            NSString* authorizationToken = json[@"authorizationToken"];
            NSString* nonce = json[@"nonce"];
            NSDictionary* documentList = json[@"documentList"];
            NSDictionary* facialRecognitionSpecification = json[@"facialRecognitionSpecification"];
            NSDictionary* backgroundCheckConfiguration = json[@"backgroundCheckConfiguration"];
            
            // Config enrollment builder
            UQEnrollmentBuilder *enrollmentBuilder = [[UQEnrollmentBuilder alloc] init];
            NSString* sessionId = json[@"sessionId"];
            if (sessionId && sessionId.length > 0) {
                [enrollmentBuilder setSessionID:sessionId];
            }
            if (json[@"isRootedDeviceAllowed"]) {
                enrollmentBuilder.isRootedDeviceAllowed = [[json valueForKey:@"isRootedDeviceAllowed"] boolValue];
            }
            if (facialRecognitionSpecification) {
                // Enable help page for face recognition
                enrollmentBuilder.enableFacialRecognition = TRUE;
                
                // Enable enroll face option
                if (facialRecognitionSpecification[@"enrollFace"]) {
                    enrollmentBuilder.enrollFace = [[facialRecognitionSpecification valueForKey:@"enrollFace"] boolValue];
                }
                
                if (facialRecognitionSpecification[@"scanMinimumMatchLevel"]) {
                    enrollmentBuilder.scanMinimumMatchLevel = [[facialRecognitionSpecification valueForKey:@"scanMinimumMatchLevel"] integerValue];
                }
                
                if (facialRecognitionSpecification[@"readMinimumMatchLevel"]) {
                    enrollmentBuilder.readMinimumMatchLevel = [[facialRecognitionSpecification valueForKey:@"readMinimumMatchLevel"] integerValue];
                }
            }
            if (backgroundCheckConfiguration) {
                BOOL isDisableConsent = FALSE;
                BackgroundCheckType type = RDC;
                if (backgroundCheckConfiguration[@"disableConsent"]) {
                    isDisableConsent = [[backgroundCheckConfiguration valueForKey:@"disableConsent"] boolValue];
                }
                if (backgroundCheckConfiguration[@"backgroudCheckType"]) {
                    if ([backgroundCheckConfiguration[@"backgroudCheckType"] isEqual:@"RDC"]) {
                        type = RDC;
                    } else {
                        type = DOW_JONES;
                    }
                }
                BOOL isMonitoringEnabled = FALSE;
                if (backgroundCheckConfiguration[@"monitoringEnabled"]) {
                    isMonitoringEnabled = [[backgroundCheckConfiguration valueForKey:@"monitoringEnabled"] boolValue];
                }
                [enrollmentBuilder enableBackgroundCheck:isDisableConsent type:type monitoring:isMonitoringEnabled];
            }
            for (NSDictionary *document in documentList) {
                NSString* documentType = document[@"documentType"];
                UQDocumentConfig *documentObject = [[UQDocumentConfig alloc] initWithDocumentTypeName:documentType];
                if(documentObject.documentType == UNSPECIFY){
                    continue;
                }
                
                UQScanConfig *scanConfig = [[UQScanConfig alloc] init];
                if (document[@"isHelpPageDisabled"]) {
                    scanConfig.disableHelpPage = [[document valueForKey:@"isHelpPageDisabled"] boolValue];
                }
                if (document[@"faceScanMinimumMatchLevel"]) {
                    scanConfig.faceMinimumMatchLevel = [[document valueForKey:@"faceScanMinimumMatchLevel"] intValue];
                }
                BOOL isEnableFrontSideReview = false;
                BOOL isEnableBackSideReview = false;
                
                if (document[@"isFrontSideReviewEnabled"]) {
                    isEnableFrontSideReview = [[document valueForKey:@"isFrontSideReviewEnabled"] boolValue];
                }
                if (document[@"isBackSideReviewEnabled"]) {
                    isEnableBackSideReview = [[document valueForKey:@"isBackSideReviewEnabled"] boolValue];
                }
                [scanConfig enableScanReview:isEnableFrontSideReview backSide:isEnableBackSideReview];
                if (document[@"isUploadEnabled"]) {
                    scanConfig.enableUpload = [[document valueForKey:@"isUploadEnabled"] boolValue];
                }
                if (document[@"isPhotoQualityDetectionEnabled"]) {
                    scanConfig.enablePhotoQualityDetection = [[document valueForKey:@"isPhotoQualityDetectionEnabled"] boolValue];
                }
                documentObject.scan = scanConfig;

                if (document[@"isExpiredDocumentValidateDisabled"]) {
                    documentObject.disableExpiryValidation = [[document valueForKey:@"isExpiredDocumentValidateDisabled"] boolValue];
                }
                
                if (document[@"isUserDataReviewDisabled"]) {
                    documentObject.disableUserDataReview = [[document valueForKey:@"isUserDataReviewDisabled"] boolValue];
                }
                
                if (document[@"readingConfiguration"]) {
                    if (@available(iOS 13, *)) {
                        NSDictionary *readingConfiguration = document[@"readingConfiguration"];
                        
                        UQReadingConfig *readConfig = [[UQReadingConfig alloc] init];
                        readConfig.enableReading = TRUE;
                        if (readingConfiguration[@"forceReading"]) {
                            [readConfig forceReading:[[readingConfiguration valueForKey:@"forceReading"] boolValue]];
                        }
                        if (readingConfiguration[@"forceReadingIfSupported"]) {
                            [readConfig forceReadingIfSupported:[[readingConfiguration valueForKey:@"forceReadingIfSupported"] boolValue]];
                        }
                        if (document[@"faceReadMinimumMatchLevel"]) {
                            readConfig.faceMinimumMatchLevel = [[document valueForKey:@"faceReadMinimumMatchLevel"] intValue];
                        }
                        documentObject.reading = readConfig;
                    }
                }
                
                [enrollmentBuilder add:documentObject];
            }
            // Add enrollment to builder
            UQBuilderController *builderController = [UQBuilderController defaultBuilder];
            builderController.delegate = self;
            [builderController setEnrollment:enrollmentBuilder];
            // Start enrollment flow
            // accessToken reuire, if no token the UQExceptionInvalidToken will throw
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                    UIWindow *window = [UIApplication sharedApplication].keyWindow;
                    UIViewController *rootViewController = window.rootViewController;
                    builderController.appViewController = rootViewController;
                    [builderController performEnrollmentWithToken:authorizationToken optionNonce:nonce];
                });
        } else {
            UQSessionStatus *status =[[UQSessionStatus alloc] init];
            status.statusCode = UNEXPECTED_ERROR;
            status.message = @"Expected enrollment object as argument.";
            status.statusTask = -1;
            [self sendPluginError:status];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.callStackSymbols);
        UQSessionStatus *status =[[UQSessionStatus alloc] init];
        status.statusCode = UNEXPECTED_ERROR;
        status.message = exception.reason;
        status.statusTask = -1;
        [self sendPluginError:status];
    }
}

- (void) didEnrollmentFailWithError:(NSError *)error {
    NSLog(@"Error %ld %@", (long)error.code, error.localizedDescription);
    UQSessionStatus *status =[[UQSessionStatus alloc] init];
    status.statusCode = UNEXPECTED_ERROR;
    status.message = error.localizedDescription;
    status.statusTask = -1;
    [self sendPluginError:status];
}

- (void) didEnrollmentCompleteWithInfo:(NSString *)jwsString {
    NSMutableDictionary *jsonResults = [[NSMutableDictionary alloc]init];
    [jsonResults setValue:jwsString forKey:@"result"];
    self.promiseResolve(jsonResults);
}

- (void) didEnrollmentIncompleteWithStatus:(UQSessionStatus *)status {
    [self sendPluginError:status];
}

RCT_EXPORT_METHOD(recover:(NSString *)recoverObj resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    self.promiseResolve = resolve;
    self.promiseReject = reject;
    @try {
        if (recoverObj != nil && [recoverObj length] > 0) {
            NSData *data = [recoverObj dataUsingEncoding:NSUTF8StringEncoding];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

            UQAccountRecoveryBuilder *accountRecoveryBuilder = [[UQAccountRecoveryBuilder alloc] init];
            accountRecoveryBuilder.authorizationToken = json[@"token"];
            accountRecoveryBuilder.enrollmentIdentifier = json[@"enrollmentIdentifier"];
            accountRecoveryBuilder.nonce = json[@"nonce"];
            if (json[@"isRootedDeviceAllowed"]) {
                accountRecoveryBuilder.isRootedDeviceAllowed = [[json valueForKey:@"isRootedDeviceAllowed"] boolValue];
            }
            if (json[@"minimumMatchLevel"]) {
                accountRecoveryBuilder.minimumMatchLevel = [[json valueForKey:@"minimumMatchLevel"] intValue];
            }
            UQBuilderController *builderController = [UQBuilderController defaultBuilder];
            builderController.delegate = self;
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            builderController.appViewController = rootViewController;
            [builderController setAccountRecovery:accountRecoveryBuilder];
            [builderController performAccountRecovery];
        } else {
            UQSessionStatus *status =[[UQSessionStatus alloc] init];
            status.statusCode = UNEXPECTED_ERROR;
            status.message = @"Expected account recovery object as argument.";
            status.statusTask = -1;
            [self sendPluginError:status];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.callStackSymbols);
        UQSessionStatus *status =[[UQSessionStatus alloc] init];
        status.statusCode = UNEXPECTED_ERROR;
        status.message = exception.reason;
        status.statusTask = -1;
        [self sendPluginError:status];
    }
}

- (void)didAccountRecoveryCompleteWithInfo:(nonnull NSString *)jwsString {
    NSMutableDictionary *jsonResults = [[NSMutableDictionary alloc]init];
    [jsonResults setValue:jwsString forKey:@"result"];
    self.promiseResolve(jsonResults);
}

- (void)didAccountRecoveryFailWithError:(nonnull NSError *)error {
    NSLog(@"Error %ld %@", (long)error.code, error.localizedDescription);
    UQSessionStatus *status =[[UQSessionStatus alloc] init];
    status.statusCode = UNEXPECTED_ERROR;
    status.message = error.localizedDescription;
    status.statusTask = -1;
    [self sendPluginError:status];
}

- (void)didAccountRecoveryIncompleteWithStatus:(UQSessionStatus *)status {
    [self sendPluginError:status];
}

RCT_EXPORT_METHOD(faceSession:(NSString *)configuration resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    self.promiseResolve = resolve;
    self.promiseReject = reject;
    @try {
        if (configuration != nil && [configuration length] > 0) {
            NSData *data = [configuration dataUsingEncoding:NSUTF8StringEncoding];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

            UQFaceSessionBuilder *faceSessionBuilder = [[UQFaceSessionBuilder alloc] init];
            faceSessionBuilder.authorizationToken = json[@"token"];
            faceSessionBuilder.sessionId = json[@"sessionId"];
            faceSessionBuilder.nonce = json[@"nonce"];
            if (json[@"isRootedDeviceAllowed"]) {
                faceSessionBuilder.isRootedDeviceAllowed = [[json valueForKey:@"isRootedDeviceAllowed"] boolValue];
            }
            if (json[@"minimumMatchLevel"]) {
                faceSessionBuilder.minimumMatchLevel = [[json valueForKey:@"minimumMatchLevel"] intValue];
            }
            UQBuilderController *builderController = [UQBuilderController defaultBuilder];
            builderController.delegate = self;
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            builderController.appViewController = rootViewController;
            [builderController setFaceSession:faceSessionBuilder];
            [builderController performFaceSession];
        } else {
            UQSessionStatus *status =[[UQSessionStatus alloc] init];
            status.statusCode = UNEXPECTED_ERROR;
            status.message = @"Expected face session configuration as argument.";
            status.statusTask = -1;
            [self sendPluginError:status];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.callStackSymbols);
        UQSessionStatus *status =[[UQSessionStatus alloc] init];
        status.statusCode = UNEXPECTED_ERROR;
        status.message = exception.reason;
        status.statusTask = -1;
        [self sendPluginError:status];
    }
}

- (void)didFaceSessionCompleteWithInfo:(nonnull NSString *)jwsString {
    NSMutableDictionary *jsonResults = [[NSMutableDictionary alloc]init];
    [jsonResults setValue:jwsString forKey:@"result"];
    self.promiseResolve(jsonResults);
}

- (void)didFaceSessionFailWithError:(nonnull NSError *)error {
    NSLog(@"Error %ld %@", (long)error.code, error.localizedDescription);
    UQSessionStatus *status =[[UQSessionStatus alloc] init];
    status.statusCode = UNEXPECTED_ERROR;
    status.message = error.localizedDescription;
    status.statusTask = -1;
    [self sendPluginError:status];
}

- (void)didFaceSessionIncompleteWithStatus:(UQSessionStatus *)status {
    [self sendPluginError:status];
}

- (void) didRootedDeviceDetected:(NSString *)info {
    UQSessionStatus *status =[[UQSessionStatus alloc] init];
    status.statusCode = UNEXPECTED_ERROR;
    status.message = info;
    status.statusTask = -1;
    [self sendPluginError:status];
}

- (void)sendPluginError:(UQSessionStatus *)status {
    NSString *code = nil;
    switch (status.statusCode) {
        case USER_CANCEL:
            code = @"USER_CANCEL";
            break;
        case SESSION_EXPIRED:
            code = @"SESSION_EXPIRED";
            break;
        case UNEXPECTED_ERROR:
            code = @"UNEXPECTED_ERROR";
            break;
        case SESSION_INVALIDATED_CHIP_VALIDATION_FAILED:
            code = @"SESSION_INVALIDATED_CHIP_VALIDATION_FAILED";
            break;
        case SESSION_INVALIDATED_READING_NOT_SUPPORTED:
            code = @"SESSION_INVALIDATED_READING_NOT_SUPPORTED";
            break;
        case SESSION_INVALIDATED_READING_INVALID_DOCUMENT:
            code = @"SESSION_INVALIDATED_READING_INVALID_DOCUMENT";
            break;
        case SESSION_INVALIDATED_FACE_RECOGNITION_TOO_MANY_ATTEMPTS:
            code = @"SESSION_INVALIDATED_FACE_RECOGNITION_TOO_MANY_ATTEMPTS";
            break;
    }
    NSString *task = nil;
    switch (status.statusTask) {
        case SCAN:
            task = @"SCAN";
            break;
        case READING:
            task = @"READING";
            break;
        case FACE:
            task = @"FACE";
            break;
        case BACKGROUND_CHECK:
            task = @"BACKGROUND_CHECK";
            break;
    }
    NSMutableDictionary *error = [[NSMutableDictionary alloc]init];
    [error setValue:code forKey:@"code"];
    [error setValue:status.message forKey:@"message"];
    [error setValue:task forKey:@"task"];
    
    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:error options:NSJSONWritingPrettyPrinted error:&err];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    self.promiseReject(nil, jsonString, nil);
}

-(void)startObserving {
    if(tracer != nil) {
        tracer.hasListeners = YES;
    }
}

-(void)stopObserving {
    if(tracer != nil) {
         tracer.hasListeners = NO;
    }
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"TraceEvent"];
}

@end


@implementation MyTracer

- (void)trace:(UQTrace *)trace {
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
    
    if(nil != trace.sessionId){
        [parameters setValue:trace.sessionId forKey:@"sessionId"];
    }
    [parameters setValue:trace.event->name forKey:@"event"];
    [parameters setValue:trace.status->name forKey:@"status"];
    
    NSString *timeStamp = [self timeStamp:trace.timestamp];
    [parameters setValue:timeStamp forKey:@"timestamp"];
    
    if (TP_NULL != trace.page) {
        [parameters setValue:trace.page->name forKey:@"page"];
    }
    if (TSC_NULL != trace.statusCode) {
        [parameters setValue:trace.statusCode->name forKey:@"statusCode"];
    }
    if (trace.documentType != UNSPECIFY) {
        UQDocumentConfig *document = [[UQDocumentConfig alloc] initWithDocumentType:trace.documentType];
        [parameters setValue:document.documentName forKey:@"documentType"];
    }
    if (trace.statusMessage) {
        [parameters setValue:trace.statusMessage forKey:@"statusMessage"];
    }

    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&err];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if(_hasListeners) {
        [_emitter sendEventWithName:@"TraceEvent" body:jsonString];
    }
}

- (NSString *)timeStamp:(NSDate *)currentDate {
    return [NSDateFormatter localizedStringFromDate:currentDate
                                            dateStyle:NSDateFormatterFullStyle
                                            timeStyle:NSDateFormatterFullStyle];
}

@end
