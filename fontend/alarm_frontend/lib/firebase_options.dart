// File updated to use environment variables for Firebase credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY'),
    appId: dotenv.get('FIREBASE_WEB_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    authDomain: dotenv.get('FIREBASE_WEB_AUTH_DOMAIN'),
    databaseURL: dotenv.get('FIREBASE_DATABASE_URL'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
    measurementId: dotenv.get('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY'),
    appId: dotenv.get('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    databaseURL: dotenv.get('FIREBASE_DATABASE_URL'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY'),
    appId: dotenv.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    databaseURL: dotenv.get('FIREBASE_DATABASE_URL'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );
}
