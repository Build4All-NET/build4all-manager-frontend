import 'package:build4all_manager/core/network/connecting/connection_banner.dart';
import 'package:build4all_manager/core/network/connecting/connection_cubit.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:build4all_manager/app/router/router.dart' as nav;
import 'package:build4all_manager/features/theme_manager/data/local_theme_store.dart';
import 'package:build4all_manager/features/theme_manager/presentation/theme_cubit.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Build shared Dio from lib/config/hostIp.json
  await DioClient.init();

  // 2) Restore token and set it globally (if exists)
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
    final dio = DioClient.ensure();
    final baseUrl = dio.options.baseUrl;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(LocalThemeStore())..load()),

        // ✅ THIS is what you were missing
       BlocProvider(
          create: (_) => ConnectionCubit(
            baseUrl: DioClient.ensure().options.baseUrl,
          ),
        ),

      ],
      child: BlocBuilder<ThemeCubit, ThemeVM>(
        builder: (context, vm) {
          return MaterialApp.router(
            title: 'Build4All Manager',
            debugShowCheckedModeBanner: false,
            theme: vm.light,
            darkTheme: vm.dark,
            themeMode: vm.mode,
            routerConfig: nav.router,

            // ✅ THIS is what makes banner show فوق كل screens
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: ConnectionBanner(),
                  ),
                ],
              );
            },

            supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
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
