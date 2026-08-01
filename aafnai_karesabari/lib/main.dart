import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const AafnaiKaresabariApp()));

  unawaited(container.read(notificationServiceProvider).registerFirebaseListeners());
}
