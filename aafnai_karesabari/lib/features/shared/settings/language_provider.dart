import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/app_user.dart';

/// The current UI language selection, defaulting to English.
final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);
