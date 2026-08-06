import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

bool _firebaseTestHarnessReady = false;

Future<void> setupFirebaseForTests() async {
  if (_firebaseTestHarnessReady) return;

  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }

  _firebaseTestHarnessReady = true;
}
