import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  print('[${DateTime.now().toIso8601String()}] main start');
  WidgetsFlutterBinding.ensureInitialized();
  print('[${DateTime.now().toIso8601String()}] initializing Firebase');
  await FirebaseBootstrap.initialize();
  print('[${DateTime.now().toIso8601String()}] Firebase init completed');
  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const AafnaiKaresabariApp()));
  print('[${DateTime.now().toIso8601String()}] App launched');
  unawaited(container.read(notificationServiceProvider).registerFirebaseListeners());
  print('[${DateTime.now().toIso8601String()}] Notification listeners registered');
}
