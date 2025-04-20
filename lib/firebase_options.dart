import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase yapılandırma seçenekleri
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions platformu desteklemiyor: $defaultTargetPlatform',
        );
    }
  }

  // TODO: Bu değerleri Firebase konsolunuzdan kopyalayın
  // Firebase projenize gidin > Proje Ayarları > Genel > Uygulamalarınız > Android/iOS
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '### ANDROID API KEY BURAYA ###',
    appId: '### ANDROID APP ID BURAYA ###',
    messagingSenderId: '### SENDER ID BURAYA ###',
    projectId: 'probody-a741c',  // Bu değeri Firebase konsolunuzdan alın
    storageBucket: 'probody-a741c.appspot.com', // Bu değeri Firebase konsolunuzdan alın
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '### IOS API KEY BURAYA ###',
    appId: '### IOS APP ID BURAYA ###',
    messagingSenderId: '### SENDER ID BURAYA ###',
    projectId: 'probody-a741c', // Bu değeri Firebase konsolunuzdan alın
    storageBucket: 'probody-a741c.appspot.com', // Bu değeri Firebase konsolunuzdan alın
    iosClientId: '### IOS CLIENT ID BURAYA ###',
    iosBundleId: 'com.example.probodyEms',
  );
}