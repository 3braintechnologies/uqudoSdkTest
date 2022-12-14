import { NativeModules } from 'react-native'

export class UqudoIdSDK {
  init() {
    NativeModules.UqudoId.init()
  }
  setLocale(locale) {
    NativeModules.UqudoId.setLocale(locale)
  }
  async enroll(enrollmentConfiguration) {
    var result = await NativeModules.UqudoId.enroll(
      JSON.stringify(enrollmentConfiguration)
    )
    return result
  }
  async recover(accountRecoveryConfiguration) {
    var result = await NativeModules.UqudoId.recover(
      JSON.stringify(accountRecoveryConfiguration)
    )
    return result
  }
  async faceSession(faceSessionConfiguration) {
    var result = await NativeModules.UqudoId.faceSession(
      JSON.stringify(faceSessionConfiguration)
    )
    return result
  }
}

export const DocumentType = Object.freeze({
  BHR_ID: 'BHR_ID',
  GENERIC_ID: 'GENERIC_ID',
  KWT_ID: 'KWT_ID',
  OMN_ID: 'OMN_ID',
  PAK_ID: 'PAK_ID',
  PASSPORT: 'PASSPORT',
  SAU_ID: 'SAU_ID',
  UAE_ID: 'UAE_ID',
  UAE_DL: 'UAE_DL',
  UAE_VISA: 'UAE_VISA',
  UAE_VL: 'UAE_VL',
  QAT_ID: 'QAT_ID',
  NLD_DL: 'NLD_DL',
  DEU_ID: 'DEU_ID',
  SDN_ID: 'SDN_ID',
  SDN_DL: 'SDN_DL',
  SDN_VL: 'SDN_VL',
})

export const BackgroundCheckType = Object.freeze({
  RDC: 'RDC',
  DOW_JONES: 'DOW_JONES',
})

export class Enrollment {
  constructor(
    documentList,
    authorizationToken,
    nonce,
    isRootedDeviceAllowed,
    isSecuredWindowsDisabled,
    facialRecognitionSpecification,
    backgroundCheckConfiguration,
    sessionId,
    userIdentifier
  ) {
    this.documentList = documentList
    this.authorizationToken = authorizationToken
    this.nonce = nonce
    this.isRootedDeviceAllowed = isRootedDeviceAllowed
    this.isSecuredWindowsDisabled = isSecuredWindowsDisabled
    this.facialRecognitionSpecification = facialRecognitionSpecification
    this.backgroundCheckConfiguration = backgroundCheckConfiguration
    this.sessionId = sessionId
    this.userIdentifier = userIdentifier
  }
}

export class EnrollmentBuilder {
  setToken(token) {
    this.authorizationToken = token
    return this
  }

  setNonce(nonce) {
    this.nonce = nonce
    return this
  }

  setSessionId(sessionId) {
    this.sessionId = sessionId
    return this
  }

  setUserIdentifier(userIdentifier) {
    this.userIdentifier = userIdentifier
    return this
  }

  enableRootedDeviceUsage() {
    this.isRootedDeviceAllowed = true
    return this
  }

  disableSecureWindow() {
    this.isSecuredWindowsDisabled = true
    return this
  }

  enableFacialRecognition() {
    if (arguments.length === 0) {
      this.facialRecognitionSpecification =
        new FacialRecognitionConfigurationBuilder().build()
    } else {
      this.facialRecognitionSpecification = arguments[0]
    }
    return this
  }

  enableBackgroundCheck() {
    if (arguments.length === 0) {
      this.backgroundCheckConfiguration =
        new BackgroundCheckConfigurationBuilder().build()
    } else {
      this.backgroundCheckConfiguration = arguments[0]
    }
    return this
  }

  add(document) {
    if (this.documentList == null) {
      this.documentList = new Array()
    }
    this.documentList.push(document)
    return this
  }

  build() {
    return new Enrollment(
      this.documentList,
      this.authorizationToken,
      this.nonce,
      this.isRootedDeviceAllowed,
      this.isSecuredWindowsDisabled,
      this.facialRecognitionSpecification,
      this.backgroundCheckConfiguration,
      this.sessionId
    )
  }
}

export class FacialRecognitionConfigurationBuilder {
  constructor() {
    this.enrollFace = false

    return {
      enrollFace: function () {
        this.enrollFace = true
        return this
      },

      setScanMinimumMatchLevel: function (scanMinimumMatchLevel) {
        this.scanMinimumMatchLevel = scanMinimumMatchLevel
        return this
      },

      setReadMinimumMatchLevel: function (readMinimumMatchLevel) {
        this.readMinimumMatchLevel = readMinimumMatchLevel
        return this
      },

      build: function () {
        return new FacialRecognitionConfiguration(
          this.enrollFace,
          this.scanMinimumMatchLevel,
          this.readMinimumMatchLevel
        )
      },
    }
  }
}

export class FacialRecognitionConfiguration {
  constructor(enrollFace, scanMinimumMatchLevel, readMinimumMatchLevel) {
    this.enrollFace = enrollFace
    this.scanMinimumMatchLevel = scanMinimumMatchLevel
    this.readMinimumMatchLevel = readMinimumMatchLevel
  }
}

export class BackgroundCheckConfigurationBuilder {
  constructor() {
    this.disableConsent = false
    this.backgroundCheckType = BackgroundCheckType.RDC
    this.monitoringEnabled = false

    return {
      disableConsent: function () {
        this.disableConsent = true
        return this
      },

      enableMonitoring: function () {
        this.monitoringEnabled = true
        return this
      },

      setBackgroundCheckType: function (backgroundCheckType) {
        this.backgroundCheckType = backgroundCheckType
        return this
      },

      build: function () {
        return new BackgroundCheckConfiguration(
          this.disableConsent,
          this.backgroundCheckType,
          this.monitoringEnabled
        )
      },
    }
  }
}

export class BackgroundCheckConfiguration {
  constructor(disableConsent, backgroundCheckType, monitoringEnabled) {
    this.disableConsent = disableConsent
    this.backgroundCheckType = backgroundCheckType
    this.monitoringEnabled = monitoringEnabled
  }
}

export class DocumentBuilder {
  constructor() {
    return {
      setDocumentType: function (documentType) {
        this.documentType = documentType
        return this
      },

      disableHelpPage: function () {
        this.isHelpPageVisible = false
        return this
      },

      disableExpiryValidation: function () {
        this.isExpiredDocumentAllowed = true
        return this
      },

      enableReading: function () {
        if (arguments.length === 0) {
          this.readingConfiguration = new ReadingConfigurationBuilder().build()
        } else {
          this.readingConfiguration = arguments[0]
        }
        return this
      },

      disableUserDataReview: function () {
        this.isUserDataReviewDisabled = true
        return this
      },

      setFaceScanMinimumMatchLevel: function (faceScanMinimumMatchLevel) {
        this.faceScanMinimumMatchLevel = faceScanMinimumMatchLevel
        return this
      },

      setFaceReadMinimumMatchLevel: function (faceReadMinimumMatchLevel) {
        this.faceReadMinimumMatchLevel = faceReadMinimumMatchLevel
        return this
      },

      enableScanReview: function (
        isFrontSideReviewEnabled,
        isBackSideReviewEnabled
      ) {
        this.isBackSideReviewEnabled = isBackSideReviewEnabled
        this.isFrontSideReviewEnabled = isFrontSideReviewEnabled
        return this
      },

      enableUpload: function () {
        this.isUploadEnabled = true
        return this
      },

      enablePhotoQualityDetection: function () {
        this.isPhotoQualityDetectionEnabled = true
        return this
      },

      build: function () {
        return new Document(
          this.documentType,
          this.readingConfiguration,
          this.isHelpPageVisible,
          this.faceScanMinimumMatchLevel,
          this.faceReadMinimumMatchLevel,
          this.isExpiredDocumentAllowed,
          this.isUserDataReviewDisabled,
          this.isFrontSideReviewEnabled,
          this.isBackSideReviewEnabled,
          this.isUploadEnabled,
          this.isPhotoQualityDetectionEnabled
        )
      },
    }
  }
}

export class ReadingConfigurationBuilder {
  constructor() {
    this.forceReadingValue = false
    this.forceReadingIfSupportedValue = false
    return {
      forceReading: function (value) {
        this.forceReadingValue = value
        return this
      },

      forceReadingIfSupported: function (value) {
        this.forceReadingIfSupportedValue = value
        return this
      },

      build: function () {
        return new ReadingConfiguration(
          this.forceReadingValue,
          this.forceReadingIfSupportedValue
        )
      },
    }
  }
}

export class ReadingConfiguration {
  constructor(forceReading, forceReadingIfSupported) {
    this.forceReading = forceReading
    this.forceReadingIfSupported = forceReadingIfSupported
  }
}

export class Document {
  constructor(
    documentType,
    readingConfiguration,
    isHelpPageDisabled,
    faceScanMinimumMatchLevel,
    faceReadMinimumMatchLevel,
    isExpiredDocumentValidateDisabled,
    isUserDataReviewDisabled,
    isFrontSideReviewEnabled,
    isBackSideReviewEnabled,
    isUploadEnabled,
    isPhotoQualityDetectionEnabled
  ) {
    this.documentType = documentType
    this.readingConfiguration = readingConfiguration
    this.isHelpPageDisabled = isHelpPageDisabled
    this.faceScanMinimumMatchLevel = faceScanMinimumMatchLevel
    this.faceReadMinimumMatchLevel = faceReadMinimumMatchLevel
    this.isExpiredDocumentValidateDisabled = isExpiredDocumentValidateDisabled
    this.isUserDataReviewDisabled = isUserDataReviewDisabled
    this.isFrontSideReviewEnabled = isFrontSideReviewEnabled
    this.isBackSideReviewEnabled = isBackSideReviewEnabled
    this.isUploadEnabled = isUploadEnabled
    this.isPhotoQualityDetectionEnabled = isPhotoQualityDetectionEnabled
  }
}

export class AccountRecoveryBuilder {
  constructor() {
    return {
      /**
       * Pass the token received from Uqudo to authenticate the SDK
       */
      setToken: function (token) {
        this.authorizationToken = token
        return this
      },

      /**
       * Pass the enrollment identifier for the account to be recovered
       */
      setEnrollmentIdentifier: function (identifier) {
        this.enrollmentIdentifier = identifier
        return this
      },

      /**
       * You can pass your custom nonce to provide security to the enrollment process
       */
      setNonce: function (nonce) {
        this.nonce = nonce
        return this
      },

      /**
       * Whether you want the sdk to run on the rooted devices or not. By default it is false
       */
      enableRootedDeviceUsage: function () {
        this.isRootedDeviceAllowed = true
        return this
      },

      /**
       * To allow user to capture/record screenshot or video of the screen on the device app is installed.
       * Default is screenshot and video recording of the screen is not allowed
       */
      disableSecureWindow: function () {
        this.isSecuredWindowsDisabled = true
        return this
      },

      /**
       * Set this to use the value passed for facialRecognition for Account Recovery
       */
      setMinimumMatchLevel: function (value) {
        this.minimumMatchLevel = value
        return this
      },

      /**
       * @returns Intent with the configuration and the token needed to authorize the activity to
       * recover the account
       */
      build: function () {
        return new AccountRecoveryConfiguration(
          this.authorizationToken,
          this.enrollmentIdentifier,
          this.nonce,
          this.isRootedDeviceAllowed,
          this.isSecuredWindowsDisabled,
          this.minimumMatchLevel
        )
      },
    }
  }
}

export class AccountRecoveryConfiguration {
  constructor(
    token,
    enrollmentIdentifier,
    nonce,
    isRootedDeviceAllowed,
    isSecuredWindowsDisabled,
    minimumMatchLevel
  ) {
    this.token = token
    this.enrollmentIdentifier = enrollmentIdentifier
    this.nonce = nonce
    this.isRootedDeviceAllowed = isRootedDeviceAllowed
    this.isSecuredWindowsDisabled = isSecuredWindowsDisabled
    this.minimumMatchLevel = minimumMatchLevel
  }
}

export class FaceSessionBuilder {
  constructor() {
    return {
      setToken: function (token) {
        this.authorizationToken = token
        return this
      },

      setSessionId: function (sessionId) {
        this.sessionId = sessionId
        return this
      },

      setNonce: function (nonce) {
        this.nonce = nonce
        return this
      },

      enableRootedDeviceUsage: function () {
        this.isRootedDeviceAllowed = true
        return this
      },

      disableSecureWindow: function () {
        this.isSecuredWindowsDisabled = true
        return this
      },

      setMinimumMatchLevel: function (value) {
        this.minimumMatchLevel = value
        return this
      },

      build: function () {
        return new FaceSessionConfiguration(
          this.authorizationToken,
          this.sessionId,
          this.nonce,
          this.isRootedDeviceAllowed,
          this.isSecuredWindowsDisabled,
          this.minimumMatchLevel
        )
      },
    }
  }
}

export class FaceSessionConfiguration {
  constructor(
    token,
    sessionId,
    nonce,
    isRootedDeviceAllowed,
    isSecuredWindowsDisabled,
    minimumMatchLevel
  ) {
    this.token = token
    this.sessionId = sessionId
    this.nonce = nonce
    this.isRootedDeviceAllowed = isRootedDeviceAllowed
    this.isSecuredWindowsDisabled = isSecuredWindowsDisabled
    this.minimumMatchLevel = minimumMatchLevel
  }
}
