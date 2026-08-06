import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static Future<void> initialize() => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
