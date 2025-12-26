import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:build4all_manager/app/router/router.dart' as nav;
import 'package:build4all_manager/features/theme_manager/data/local_theme_store.dart';
import 'package:build4all_manager/features/theme_manager/presentation/theme_cubit.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

class Build4AllManagerApp extends StatelessWidget {
  const Build4AllManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(LocalThemeStore())..load(),
      child: BlocBuilder<ThemeCubit, ThemeVM>(
        builder: (context, vm) {
          return MaterialApp.router(
            title: 'Build4All Manager',
            debugShowCheckedModeBanner: false,
            theme: vm.light,
            darkTheme: vm.dark,
            themeMode: vm.mode,
            routerConfig: nav.router,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('fr'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            localeListResolutionCallback: (locales, supported) {
              if (locales == null || locales.isEmpty) return supported.first;
              final first = locales.first;
              for (final s in supported) {
                if (s.languageCode == first.languageCode) return s;
              }
              return supported.first;
            },
          );
        },
      ),
    );
  }
}
