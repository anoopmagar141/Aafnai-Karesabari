import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  debugPrint('[${DateTime.now().toIso8601String()}] main start');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[${DateTime.now().toIso8601String()}] initializing Firebase');
  await FirebaseBootstrap.initialize();
  debugPrint('[${DateTime.now().toIso8601String()}] Firebase init completed');
  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const AafnaiKaresabariApp()));
  debugPrint('[${DateTime.now().toIso8601String()}] App launched');
  unawaited(container.read(notificationServiceProvider).registerFirebaseListeners());
  debugPrint('[${DateTime.now().toIso8601String()}] Notification listeners registered');
}
