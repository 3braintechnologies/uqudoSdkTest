package io.sdk.uqudoid;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import android.util.SparseArray;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.jetbrains.annotations.NotNull;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.UUID;

import io.uqudo.sdk.core.DocumentBuilder;
import io.uqudo.sdk.core.SessionStatus;
import io.uqudo.sdk.core.SessionStatusCode;
import io.uqudo.sdk.core.UqudoBuilder;
import io.uqudo.sdk.core.UqudoSDK;
import io.uqudo.sdk.core.analytics.Trace;
import io.uqudo.sdk.core.analytics.Tracer;
import io.uqudo.sdk.core.builder.BackgroundCheckConfigurationBuilder;
import io.uqudo.sdk.core.builder.FacialRecognitionConfigurationBuilder;
import io.uqudo.sdk.core.builder.ReadingConfigurationBuilder;
import io.uqudo.sdk.core.domain.model.BackgroundCheckType;
import io.uqudo.sdk.core.domain.model.Document;
import io.uqudo.sdk.core.domain.model.DocumentType;

public class UqudoIdModule extends ReactContextBaseJavaModule implements ActivityEventListener {

    private final ReactApplicationContext context;
    private final SparseArray<Promise> mPromises;
    public static final int REQUEST_CODE_ENROLLMENT = 1001;
    public static final int REQUEST_CODE_ACCOUNT_RECOVERY = 1002;
    public static final int REQUEST_CODE_FACE_SESSION = 1003;

    public UqudoIdModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
        mPromises = new SparseArray<>();
    }

    @Override
    public String getName() {
        return "UqudoId";
    }

    @Override
    public void initialize() {
        super.initialize();
        getReactApplicationContext().addActivityEventListener(this);
    }

    @Override
    public void onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy();
        getReactApplicationContext().removeActivityEventListener(this);
    }

    @ReactMethod
    public void init() {
        UqudoSDK.init(context, new TraceObject());
    }

    private class TraceObject implements Tracer {
        @Override
        public void trace(@NotNull Trace trace) {
            try {
                JSONObject json = new JSONObject();
                json.put("category", trace.getCategory());
                json.put("sessionId", trace.getSessionId());
                json.put("event", trace.getEvent());
                json.put("page", trace.getPage());
                json.put("statusCode", trace.getStatusCode());
                json.put("status", trace.getStatus());
                json.put("message", trace.getStatusMessage());
                json.put("timestamp", trace.getTimestamp());
                json.put("documentType", trace.getDocumentType());
                String data = json.toString();
                context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("TraceEvent", data);
            } catch (Exception e) {
                Log.e("UqudoIdModule", e.getMessage(), e);
            }
        }
    }

    @ReactMethod
    public void setLocale(String locale) {
        UqudoSDK.setLocale(context, locale);
    }

    @ReactMethod
    public void enroll(String message, Promise promise) {
        if (message != null && message.length() > 0) {
            try {
                JSONObject json = new JSONObject(message);
                UqudoBuilder.Enrollment enrollment = new UqudoBuilder.Enrollment();
                if (json.has("isSecuredWindowsDisabled") && json.getBoolean("isSecuredWindowsDisabled")) {
                    enrollment.disableSecureWindow();
                }
                if (json.has("isRootedDeviceAllowed") && json.getBoolean("isRootedDeviceAllowed")) {
                    enrollment.enableRootedDeviceUsage();
                }
                if (json.has("nonce")) {
                    enrollment.setNonce(json.getString("nonce"));
                }
                if (json.has("sessionId")) {
                    enrollment.setSessionId(json.getString("sessionId"));
                }
                if (json.has("userIdentifier")) {
                    enrollment.setUserIdentifier(UUID.fromString(json.getString("userIdentifier")));
                }
                if (json.has("facialRecognitionSpecification")) {
                    FacialRecognitionConfigurationBuilder faceBuilder = new FacialRecognitionConfigurationBuilder();
                    JSONObject faceObject = json.getJSONObject("facialRecognitionSpecification");
                    if (faceObject.has("enrollFace") && faceObject.getBoolean("enrollFace")) {
                        faceBuilder.enrollFace();
                    }
                    if (faceObject.has("scanMinimumMatchLevel") && faceObject.getInt("scanMinimumMatchLevel") > 0) {
                        faceBuilder.setScanMinimumMatchLevel(faceObject.getInt("scanMinimumMatchLevel"));
                    }
                    if (faceObject.has("readMinimumMatchLevel") && faceObject.getInt("readMinimumMatchLevel") > 0) {
                        faceBuilder.setReadMinimumMatchLevel(faceObject.getInt("readMinimumMatchLevel"));
                    }
                    enrollment.enableFacialRecognition(faceBuilder.build());
                }
                if (json.has("backgroundCheckConfiguration")) {
                    BackgroundCheckConfigurationBuilder backgroundCheckConfigurationBuilder = new BackgroundCheckConfigurationBuilder();
                    JSONObject backgroundObject = json.getJSONObject("backgroundCheckConfiguration");
                    if (backgroundObject.has("disableConsent")) {
                        backgroundCheckConfigurationBuilder.disableConsent();
                    }
                    if (backgroundObject.has("backgroundCheckType")) {
                        backgroundCheckConfigurationBuilder.setBackgroundCheckType(BackgroundCheckType.valueOf(backgroundObject.getString("backgroundCheckType")));
                    }
                    if (backgroundObject.has("monitoringEnabled")) {
                        backgroundCheckConfigurationBuilder.enableMonitoring();
                    }
                    enrollment.enableBackgroundCheck(backgroundCheckConfigurationBuilder.build());
                }
                enrollment.setToken(json.getString("authorizationToken"));
                JSONArray documentList = json.getJSONArray("documentList");
                for (int i = 0; i < documentList.length(); i++) {
                    JSONObject documentJson = documentList.getJSONObject(i);
                    DocumentBuilder documentBuilder = new DocumentBuilder(context);
                    documentBuilder.setDocumentType(DocumentType.valueOf(documentJson.getString("documentType")));
                    if (documentJson.has("isHelpPageDisabled") && documentJson.getBoolean("isHelpPageDisabled")) {
                        documentBuilder.disableHelpPage();
                    }
                    if (documentJson.has("isExpiredDocumentValidateDisabled") && documentJson.getBoolean("isExpiredDocumentValidateDisabled")) {
                        documentBuilder.disableExpiryValidation();
                    }
                    if (documentJson.has("isUserDataReviewDisabled") && documentJson.getBoolean("isUserDataReviewDisabled")) {
                        documentBuilder.disableUserDataReview();
                    }
                    if (documentJson.has("isFrontSideReviewEnabled") || documentJson.has("isBackSideReviewEnabled")) {
                        documentBuilder.enableScanReview(documentJson.optBoolean("isFrontSideReviewEnabled", false), documentJson.optBoolean("isBackSideReviewEnabled", false));
                    }
                    if (documentJson.has("isUploadEnabled") && documentJson.getBoolean("isUploadEnabled")) {
                        documentBuilder.enableUpload();
                    }
                    if (documentJson.has("isPhotoQualityDetectionEnabled") && documentJson.getBoolean("isPhotoQualityDetectionEnabled")) {
                        documentBuilder.enablePhotoQualityDetection();
                    }
                    if (documentJson.has("readingConfiguration")) {
                        JSONObject readConfiguration = documentJson.getJSONObject("readingConfiguration");
                        if (readConfiguration.has("forceReading")) {
                            ReadingConfigurationBuilder readingConfigurationBuilder = new ReadingConfigurationBuilder();
                            if (readConfiguration.has("forceReading")) {
                                readingConfigurationBuilder.forceReading(readConfiguration.getBoolean("forceReading"));
                            }
                            if (readConfiguration.has("forceReadingIfSupported")) {
                                readingConfigurationBuilder.forceReadingIfSupported(readConfiguration.getBoolean("forceReadingIfSupported"));
                            }
                            documentBuilder.enableReading(readingConfigurationBuilder.build());
                        } else {
                            documentBuilder.enableReading();
                        }
                    }
                    if (documentJson.has("faceScanMinimumMatchLevel") && documentJson.getInt("faceScanMinimumMatchLevel") > 0) {
                        documentBuilder.setFaceScanMinimumMatchLevel(documentJson.getInt("faceScanMinimumMatchLevel"));
                    }
                    if (documentJson.has("faceReadMinimumMatchLevel") && documentJson.getInt("faceReadMinimumMatchLevel") > 0) {
                        documentBuilder.setFaceReadMinimumMatchLevel(documentJson.getInt("faceReadMinimumMatchLevel"));
                    }
                    Document document = documentBuilder.build();
                    enrollment.add(document);
                }
                Intent intent = enrollment.build(context);
                getReactApplicationContext().startActivityForResult(intent, REQUEST_CODE_ENROLLMENT, null);
                mPromises.put(REQUEST_CODE_ENROLLMENT, promise);
            } catch (Exception e) {
                Log.e("UqudoIdModule", e.getMessage(), e);
                sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), e.getMessage(), null);
            }
        } else {
            sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), "Expected enrollment object as argument.", null);
        }
    }

    @ReactMethod
    public void recover(String message, Promise promise) {
        if (message != null && message.length() > 0) {
            try {
                JSONObject json = new JSONObject(message);
                UqudoBuilder.AccountRecovery recovery = new UqudoBuilder.AccountRecovery();
                recovery.setToken(json.getString("token"));
                recovery.setEnrollmentIdentifier(json.getString("enrollmentIdentifier"));
                if (json.has("nonce")) {
                    recovery.setNonce(json.getString("nonce"));
                }
                if (json.has("isRootedDeviceAllowed")) {
                    recovery.enableRootedDeviceUsage();
                }
                if (json.has("isSecuredWindowsDisabled")) {
                    recovery.disableSecureWindow();
                }
                if (json.has("minimumMatchLevel") && json.getInt("minimumMatchLevel") > 0) {
                    recovery.setMinimumMatchLevel(json.getInt("minimumMatchLevel"));
                }
                Intent intent = recovery.build(context);
                getReactApplicationContext().startActivityForResult(intent, REQUEST_CODE_ACCOUNT_RECOVERY, null);
                mPromises.put(REQUEST_CODE_ACCOUNT_RECOVERY, promise);
            } catch (Exception e) {
                Log.e("UqudoIdModule", e.getMessage(), e);
                sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), e.getMessage(), null);
            }
        } else {
            sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), "Expected account recovery object as argument.", null);
        }
    }

    @ReactMethod
    public void faceSession(String configuration, Promise promise) {
        if (configuration != null && configuration.length() > 0) {
            try {
                JSONObject json = new JSONObject(configuration);
                UqudoBuilder.FaceSession faceSession = new UqudoBuilder.FaceSession();
                faceSession.setToken(json.getString("token"));
                faceSession.setSessionId(json.getString("sessionId"));
                if (json.has("nonce")) {
                    faceSession.setNonce(json.getString("nonce"));
                }
                if (json.has("isRootedDeviceAllowed")) {
                    faceSession.enableRootedDeviceUsage();
                }
                if (json.has("isSecuredWindowsDisabled")) {
                    faceSession.disableSecureWindow();
                }
                if (json.has("minimumMatchLevel") && json.getInt("minimumMatchLevel") > 0) {
                    faceSession.setMinimumMatchLevel(json.getInt("minimumMatchLevel"));
                }
                Intent intent = faceSession.build(context);
                getReactApplicationContext().startActivityForResult(intent, REQUEST_CODE_FACE_SESSION, null);
                mPromises.put(REQUEST_CODE_FACE_SESSION, promise);
            } catch (Exception e) {
                Log.e("UqudoIdModule", e.getMessage(), e);
                sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), e.getMessage(), null);
            }
        } else {
            sendError(promise, SessionStatusCode.UNEXPECTED_ERROR.name(), "Expected face session configuration as argument.", null);
        }
    }

    private void sendError(Promise promise, String code, String message, String task) {
        JSONObject error = new JSONObject();
        try {
            error.put("code", code);
            error.put("message", message);
            error.put("task", task);
        } catch (Exception e) {
            e.printStackTrace();
        }
        promise.reject(error.toString());
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        Promise promise = mPromises.get(requestCode);
        if (promise == null) {
            return;
        }
        if (requestCode == REQUEST_CODE_ENROLLMENT || requestCode == REQUEST_CODE_ACCOUNT_RECOVERY || requestCode == REQUEST_CODE_FACE_SESSION) {
            if (resultCode == Activity.RESULT_OK) {
                WritableMap map = Arguments.createMap();
                map.putString("result", data.getStringExtra("data"));
                promise.resolve(map);
            } else if (resultCode == Activity.RESULT_CANCELED) {
                if (data != null) {
                    //Something wrong happened while using the SDK
                    SessionStatus sessionStatus = data.getParcelableExtra("key_session_status");
                    assert sessionStatus != null;
                    sendError(promise, sessionStatus.getSessionStatusCode().name(), sessionStatus.getSessionStatusCode().getMessage(), sessionStatus.getSessionTask().name());
                }
            }
        }
    }

    @Override
    public void onNewIntent(Intent intent) {

    }
}
