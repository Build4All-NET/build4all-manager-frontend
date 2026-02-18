import 'package:build4all_manager/app/nav_key.dart';
import 'package:build4all_manager/app/router/super_admin_entry_loader.dart';
import 'package:build4all_manager/features/owner/ownerhome/data/static_project_models.dart';
import 'package:build4all_manager/features/owner/ownerhome/presentation/screens/owner_project_details_screen.dart';
import 'package:build4all_manager/features/owner/ownerhome/presentation/screens/owner_requests_list_screen.dart';
import 'package:build4all_manager/features/owner/ownernav/presentation/controllers/owner_nav_cubit.dart';
import 'package:build4all_manager/features/owner/ownerrequests/presentation/screens/owner_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// splash / homes
import 'package:build4all_manager/app/splash_gate.dart';
import 'package:build4all_manager/features/auth/presentation/screens/app_login_screen.dart';

// owner shell + screens
import 'package:build4all_manager/features/owner/ownernav/presentation/screens/owner_nav_shell.dart';
import 'package:build4all_manager/features/owner/ownerhome/presentation/screens/owner_home_screen.dart';
import 'package:build4all_manager/features/owner/ownerprojects/presentation/screens/owner_projects_screen.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/screens/owner_profile_screen.dart';

// l10n
import 'package:build4all_manager/l10n/app_localizations.dart';

// auth repo + jwt store
import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:build4all_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

// owner register flow
import 'package:build4all_manager/features/auth/domain/usecases/OwnerCompleteProfile.dart';
import 'package:build4all_manager/features/auth/domain/usecases/OwnerSendOtp.dart';
import 'package:build4all_manager/features/auth/domain/usecases/OwnerVerifyOtp.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/OwnerRegisterBloc.dart';
import 'package:build4all_manager/features/auth/presentation/screens/register/owner_register_email_screen.dart';
import 'package:build4all_manager/features/auth/presentation/screens/register/owner_register_otp_screen.dart';
import 'package:build4all_manager/features/auth/presentation/screens/register/owner_register_profile_screen.dart';

// shared Dio
import 'package:build4all_manager/core/network/dio_client.dart';

// JWT helpers
import 'package:build4all_manager/core/auth/jwt_claims.dart';

Widget _withOwnerRegBloc(Widget child) {
  final IAuthRepository repo =
      AuthRepositoryImpl(api: AuthApi(), jwtStore: JwtLocalDataSource());
  return BlocProvider(
    create: (_) => OwnerRegisterBloc(
      OwnerSendOtpUseCase(repo),
      OwnerVerifyOtpUseCase(repo),
      OwnerCompleteProfileUseCase(repo),
    ),
    child: child,
  );
}

const _publicPaths = <String>{
  '/',
  '/login',
  '/loginScreen',
  '/owner/register',
  '/owner/register/otp',
  '/owner/register/profile',
};

final router = GoRouter(
  navigatorKey: appNavKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashGate()),
    GoRoute(path: '/login', builder: (_, __) => const AppLoginScreen()),
    GoRoute(path: '/loginScreen', builder: (_, __) => const AppLoginScreen()),
    GoRoute(
      path: '/manager',
      builder: (_, __) => const SuperAdminEntryLoader(),
    ),
    GoRoute(path: '/owner', builder: (_, __) => const _OwnerEntryLoader()),
    GoRoute(
      path: '/owner/projects',
      builder: (_, __) => const _OwnerProjectsBuilder(),
    ),
    GoRoute(
      path: '/owner/project/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr) ?? projectTemplates.first.id;
        final tpl = projectTemplates.firstWhere(
          (t) => t.id == id,
          orElse: () => projectTemplates.first,
        );
        return _OwnerProjectDetailsBuilder(tpl: tpl);
      },
    ),
    GoRoute(
      path: '/owner/requests/list',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final ownerId = extra?['ownerId'] as int?;
        final dio = extra?['dio'] as Dio?;

        if (ownerId == null || dio == null) {
          return const Scaffold(
            body: Center(child: Text('Missing navigation params')),
          );
        }

        return OwnerRequestsListScreen(ownerId: ownerId, dio: dio);
      },
    ),
    GoRoute(
      path: '/owner/requests',
      builder: (context, state) {
        final extra = (state.extra ?? const {}) as Map;
        final int? initialProjectId = extra['projectId'] as int?;
        final String? initialAppName = extra['appName'] as String?;
        return _OwnerRequestsBuilder(
          initialProjectId: initialProjectId,
          initialAppName: initialAppName,
        );
      },
    ),
    GoRoute(
      path: '/owner/profile',
      builder: (_, __) => const _OwnerEntryLoader(initialIndex: 2),
    ),
    GoRoute(
      path: '/owner/register',
      builder: (_, __) => _withOwnerRegBloc(const OwnerRegisterEmailScreen()),
      routes: [
        GoRoute(
          path: 'otp',
          builder: (ctx, st) {
            final extra = (st.extra ?? {}) as Map;
            return _withOwnerRegBloc(
              OwnerRegisterOtpScreen(
                email: (extra['email'] ?? '') as String,
                password: (extra['password'] ?? '') as String,
              ),
            );
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (ctx, st) => _withOwnerRegBloc(
            OwnerRegisterProfileScreen(
              registrationToken: (st.extra ?? '') as String,
            ),
          ),
        ),
      ],
    ),
  ],
  redirect: _authRedirect,
);

Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final store = JwtLocalDataSource();
  final (token, roleRaw) = await store.read();

  final role = roleRaw.toUpperCase().trim();
  final loc = state.matchedLocation;
  final isPublic = _publicPaths.contains(loc);

  if (token.isEmpty || role.isEmpty) {
    return isPublic ? null : '/login';
  }

  final goingToAuth =
      loc.startsWith('/login') || loc.startsWith('/owner/register');

  if (goingToAuth) return role == 'SUPER_ADMIN' ? '/manager' : '/owner';

  if (role == 'SUPER_ADMIN' && (loc == '/owner' || loc == '/home')) {
    return '/manager';
  }
  if (role != 'SUPER_ADMIN' && (loc == '/manager' || loc == '/home')) {
    return '/owner';
  }

  return null;
}

Future<int?> _loadOwnerIdFromJwt() async {
  try {
    final store = JwtLocalDataSource();
    final (token, _) = await store.read();
    if (token.isEmpty) return null;

    final claims = JwtClaims.decode(token);
    final id =
        JwtClaims.extractInt(claims, ['id', 'ownerId', 'adminId', 'sub']);
    return id;
  } catch (_) {
    return null;
  }
}

/// ✅ Better: builds a display name from various claim keys.
/// Refuses to return emails as "name".
String? _extractDisplayName(Map<String, dynamic>? claims) {
  if (claims == null) return null;

  String? pick(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  final first = pick(claims['firstName']) ??
      pick(claims['given_name']) ??
      pick(claims['givenName']) ??
      pick(claims['firstname']);

  final last = pick(claims['lastName']) ??
      pick(claims['family_name']) ??
      pick(claims['familyName']) ??
      pick(claims['lastname']);

  // Prefer first + last if available
  String? fullFromParts;
  if (first != null && last != null) {
    fullFromParts = '$first $last'.trim();
  } else if (first != null) {
    fullFromParts = first;
  }

  // Fallback keys
  final raw = fullFromParts ??
      pick(claims['name']) ??
      pick(claims['fullName']) ??
      pick(claims['displayName']) ??
      pick(claims['ownerName']) ??
      pick(claims['adminName']) ??
      pick(claims['username']) ??
      pick(claims['preferred_username']);

  if (raw == null) return null;

  // refuse email as a display name
  final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw);
  if (isEmail) return null;

  return raw;
}

Future<(int?, String?)> _loadOwnerProfileFromJwt() async {
  try {
    final store = JwtLocalDataSource();
    final (token, _) = await store.read();
    if (token.isEmpty) return (null, null);

    final Map<String, dynamic>? claims = JwtClaims.decode(token);

    final id = JwtClaims.extractInt(
      claims,
      ['id', 'ownerId', 'adminId', 'sub'],
    );

    final name = _extractDisplayName(claims);

    return (id, name);
  } catch (_) {
    return (null, null);
  }
}

class _OwnerEntryLoader extends StatelessWidget {
  final int initialIndex;
  const _OwnerEntryLoader({this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<(int?, String?)>(
      future: _loadOwnerProfileFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final (ownerId, ownerName) = snap.data ?? (null, null);

        if (ownerId == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return Scaffold(body: Center(child: Text(l10n.owner_nav_profile)));
        }

        final Dio dio = DioClient.ensure();
        return OwnerEntry(
          ownerId: ownerId,
          ownerName: ownerName,
          dio: dio,
          backendMenuType: 'bottom',
          initialIndex: initialIndex,
        );
      },
    );
  }
}

class _OwnerProjectsBuilder extends StatelessWidget {
  const _OwnerProjectsBuilder();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _loadOwnerIdFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final ownerId = snap.data;
        if (ownerId == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const SizedBox.shrink();
        }
        final Dio dio = DioClient.ensure();
        return OwnerProjectsScreen(ownerId: ownerId, dio: dio);
      },
    );
  }
}

class _OwnerProjectDetailsBuilder extends StatelessWidget {
  final ProjectTemplate tpl;
  const _OwnerProjectDetailsBuilder({required this.tpl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _loadOwnerIdFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final ownerId = snap.data;
        if (ownerId == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const SizedBox.shrink();
        }
        return OwnerProjectDetailsScreen(tpl: tpl, ownerId: ownerId);
      },
    );
  }
}

class OwnerEntry extends StatelessWidget {
  final String? backendMenuType;
  final int ownerId;
  final String? ownerName;
  final Dio dio;
  final int initialIndex;

  const OwnerEntry({
    super.key,
    required this.ownerId,
    required this.dio,
    this.backendMenuType,
    this.ownerName,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = <OwnerDestination>[
      OwnerDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.owner_nav_home,
        page: OwnerHomeScreen(
          ownerId: ownerId,
          dio: dio,
          ownerName: ownerName,
        ),
      ),
      OwnerDestination(
        icon: Icons.apps_outlined,
        selectedIcon: Icons.apps_rounded,
        label: l10n.owner_nav_projects,
        page: OwnerProjectsScreen(ownerId: ownerId, dio: dio),
      ),
      OwnerDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.owner_nav_profile,
        page: OwnerProfileScreen( dio: dio),
      ),
    ];

    // ✅ FIX: respect initialIndex (no more hardcoded 0)
    return BlocProvider(
      create: (_) => OwnerNavCubit(initialIndex: initialIndex),
      child: OwnerNavShell(
        backendMenuType: backendMenuType,
        destinations: destinations,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _OwnerRequestsBuilder extends StatelessWidget {
  final int? initialProjectId;
  final String? initialAppName;
  const _OwnerRequestsBuilder({
    this.initialProjectId,
    this.initialAppName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _loadOwnerIdFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final ownerId = snap.data;
        if (ownerId == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const SizedBox.shrink();
        }

        return OwnerRequestScreen(
          baseUrl: DioClient.ensure().options.baseUrl,
          ownerId: ownerId,
          dio: DioClient.ensure(),
          initialProjectId: initialProjectId,
          initialAppName: initialAppName,
        );
      },
    );
  }
}
