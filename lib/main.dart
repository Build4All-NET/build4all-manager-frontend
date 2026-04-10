import 'package:build4all_manager/core/config/app_boot_guard.dart';
import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/localization/locale_storage.dart';
import 'package:build4all_manager/core/network/connecting/connection_banner.dart';
import 'package:build4all_manager/core/network/connecting/connection_cubit.dart';
import 'package:build4all_manager/core/network/connecting/server_down_overlay.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/notifications/firebase_push_service.dart';
import 'package:build4all_manager/core/notifications/local_notification_service.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:build4all_manager/app/router/router.dart' as nav;
import 'package:build4all_manager/features/theme_manager/data/local_theme_store.dart';
import 'package:build4all_manager/features/theme_manager/presentation/theme_cubit.dart';
import 'firebase_options.dart';

Future<void> _initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DioClient.init();
  } catch (e) {
    debugPrint('DioClient.init failed => $e');
  }

  try {
    await _initFirebase();
  } catch (e) {
    debugPrint('Firebase init failed => $e');
  }

  try {
    await LocalNotificationService().init();
  } catch (e) {
    debugPrint('LocalNotificationService.init failed => $e');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Build4All Manager';

    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new notification';

    debugPrint('Foreground FCM received => title=$title, body=$body');

    try {
      await LocalNotificationService().show(
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Local foreground notification show failed => $e');
    }
  });

  try {
    final jwt = JwtLocalDataSource();
    final (token, _) = await jwt.read();
    if (token.isNotEmpty) {
      DioClient.setToken(token);
    }
  } catch (e) {
    debugPrint('Restore token failed => $e');
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
                      const _BootGuardRunner(),
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

class _BootGuardRunner extends StatefulWidget {
  const _BootGuardRunner();

  @override
  State<_BootGuardRunner> createState() => _BootGuardRunnerState();
}

class _BootGuardRunnerState extends State<_BootGuardRunner> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AppBootGuard.run(
          currentApiBaseUrl: DioClient.ensure().options.baseUrl,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('AppBootGuard failed or timed out => $e');
      }

      try {
        await FirebasePushService().initForAdmin().timeout(
          const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint('FirebasePushService init failed or timed out => $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}