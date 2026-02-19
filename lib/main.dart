import 'package:build4all_manager/core/config/app_boot_guard.dart';
import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/localization/locale_storage.dart';
import 'package:build4all_manager/core/network/connecting/connection_banner.dart';
import 'package:build4all_manager/core/network/connecting/connection_cubit.dart';
import 'package:build4all_manager/core/network/connecting/server_down_overlay.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:build4all_manager/app/router/router.dart' as nav;
import 'package:build4all_manager/features/theme_manager/data/local_theme_store.dart';
import 'package:build4all_manager/features/theme_manager/presentation/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DioClient.init();

  //  Boot guard BEFORE reading token (kills stale tokens after DB reset / env switch)
  await AppBootGuard.run(
    currentApiBaseUrl: DioClient.ensure().options.baseUrl,
  );

  //  Read token normally
  final jwt = JwtLocalDataSource();
  final (token, _) = await jwt.read();
  if (token.isNotEmpty) {
    DioClient.setToken(token);
  }

  runApp(const Build4AllManagerApp());
}

class Build4AllManagerApp extends StatelessWidget {
  const Build4AllManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(LocalThemeStore())..load()),
        BlocProvider(
          create: (_) => ConnectionCubit(
            baseUrl: DioClient.ensure().options.baseUrl,
          ),
        ),
        BlocProvider(
          create: (_) => LocaleCubit(LocaleStorage())..loadSavedLocale(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeVM>(
        builder: (context, vm) {
          return BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'Build4All Manager',
                debugShowCheckedModeBanner: false,
                theme: vm.light,
                darkTheme: vm.dark,
                themeMode: vm.mode,
                routerConfig: nav.router,
                locale: locale,
                builder: (context, child) {
                  return Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const Align(
                        alignment: Alignment.topCenter,
                        child: ConnectionBanner(),
                      ),
                      const ServerDownOverlay(),
                    ],
                  );
                },
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                localeListResolutionCallback: (locales, supported) {
                  if (locales == null || locales.isEmpty) {
                    return supported.first;
                  }
                  final first = locales.first;
                  for (final s in supported) {
                    if (s.languageCode == first.languageCode) return s;
                  }
                  return supported.first;
                },
              );
            },
          );
        },
      ),
    );
  }
}
