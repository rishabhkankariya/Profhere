import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  // Register a Web app in Firebase Console → Project Settings → Add app → Web
  // Then replace the appId below with the one shown.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAmbCK1Kvnxf01lv1d4-nMJVEYHHOXhLh0',
    authDomain: 'profhere.firebaseapp.com',
    projectId: 'profhere',
    storageBucket: 'profhere.firebasestorage.app',
    messagingSenderId: '61179747959',
    appId: '1:61179747959:web:c2406f7f3e360579267072',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2K5TUsLXpAUYf46gvnAmj2jp2AjWvZi8',
    appId: '1:61179747959:android:254775a5688aefc2267072',
    messagingSenderId: '61179747959',
    projectId: 'profhere',
    storageBucket: 'profhere.firebasestorage.app',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2K5TUsLXpAUYf46gvnAmj2jp2AjWvZi8',
    appId: '1:61179747959:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '61179747959',
    projectId: 'profhere',
    storageBucket: 'profhere.firebasestorage.app',
    iosBundleId: 'com.profhere.profhere',
  );
}
