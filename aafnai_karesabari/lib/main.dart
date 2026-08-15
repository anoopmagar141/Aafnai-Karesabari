import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'data/services/notification_service.dart';

/// App entry point: initializes Firebase, then launches [AafnaiKaresabariApp].
/// Every step is resilient by design — see the inline comments below for
/// why Firebase failures and notification registration never block launch.
Future<void> main() async {
  debugPrint('[${DateTime.now().toIso8601String()}] main start');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[${DateTime.now().toIso8601String()}] initializing Firebase');
  try {
    await FirebaseBootstrap.initialize();
    debugPrint('[${DateTime.now().toIso8601String()}] Firebase init completed');
  } catch (error, stack) {
    // A Firebase init failure must never block the app from launching at
    // all — that leaves the user stuck on the native splash screen forever
    // with no way to see what went wrong. Log it and proceed; individual
    // Firestore-backed screens already have their own local-data fallback.
    debugPrint('[${DateTime.now().toIso8601String()}] Firebase init FAILED, continuing without it: $error\n$stack');
  }
  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const AafnaiKaresabariApp()));
  debugPrint('[${DateTime.now().toIso8601String()}] App launched');
  // Firebase.apps stays empty when init above failed — every Firestore-
  // backed repository call throws '[core/no-app]' in that case, so skip
  // eagerly touching one here rather than crashing the launch sequence.
  if (Firebase.apps.isNotEmpty) {
    unawaited(container.read(notificationServiceProvider).registerFirebaseListeners());
    debugPrint('[${DateTime.now().toIso8601String()}] Notification listeners registered');
  }
}
