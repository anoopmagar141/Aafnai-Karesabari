import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/app_user.dart';
final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);
