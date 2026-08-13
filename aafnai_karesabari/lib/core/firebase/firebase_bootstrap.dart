import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static Future<void> initialize() async {
    // On Android, google-services.json + the Google Services Gradle plugin
    // auto-initialize the default FirebaseApp natively before Dart code
    // ever runs (see the native "FirebaseInitProvider" log line that always
    // precedes this call). Calling Firebase.initializeApp() again here then
    // throws "[core/duplicate-app]" — skip it when that's already happened.
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } on FirebaseException catch (error) {
      if (error.code == 'duplicate-app') {
        return;
      }
      rethrow;
    } catch (error, stack) {
      debugPrint('FirebaseBootstrap: initializeApp failed: $error\n$stack');
      rethrow;
    }
  }
}
