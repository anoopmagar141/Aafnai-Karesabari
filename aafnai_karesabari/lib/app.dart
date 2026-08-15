import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's root widget: sets up the Riverpod [ProviderScope], the
/// Material theme, GoRouter, and English/Nepali localization.
class AafnaiKaresabariApp extends StatelessWidget {
  const AafnaiKaresabariApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Aafnai Karesabari',
        theme: AppTheme.light,
        routerConfig: appRouter,
        supportedLocales: const [Locale('en'), Locale('ne')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
      ),
    );
}
