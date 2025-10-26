import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web options from your Firebase project
    return const FirebaseOptions(
      apiKey: 'AIzaSyBvGXse33LIcZ_vzRM89qPWgRWZwUoRL2w',
      appId: '1:591975707019:web:b2494ceedcbe2a92b4ff8e',
      messagingSenderId: '591975707019',
      projectId: 'ceocred',
      authDomain: 'ceocred.firebaseapp.com',
      storageBucket: 'ceocred.firebasestorage.app',
    );
  }
}