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

/// ===============================================================
/// Owner session scope (ownerId/dio available everywhere under shell)
/// ===============================================================
class OwnerSessionScope extends InheritedWidget {
  final int ownerId;
  final String? ownerName;
  final Dio dio;
  final String backendMenuType;

  const OwnerSessionScope({
    super.key,
    required this.ownerId,
    required this.dio,
    required this.backendMenuType,
    this.ownerName,
    required super.child,
  });

  static OwnerSessionScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<OwnerSessionScope>();
    assert(s != null, 'OwnerSessionScope not found in context');
    return s!;
  }

  @override
  bool updateShouldNotify(covariant OwnerSessionScope oldWidget) => false;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s) ?? num.tryParse(s)?.toInt();
}

String? _asNonEmptyStr(dynamic v) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? null : s;
}

/// ===============================================================
/// Owner Register Bloc wrapper
/// ===============================================================
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

/// ===============================================================
/// Public paths (no token)
/// ===============================================================
const _publicPaths = <String>{
  '/',
  '/login',
  '/loginScreen',
  '/owner/register',
  '/owner/register/otp',
  '/owner/register/profile',
};

final _ownerShellKey = GlobalKey<NavigatorState>(debugLabel: 'owner-shell');

final router = GoRouter(
  navigatorKey: appNavKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashGate()),
    GoRoute(path: '/login', builder: (_, __) => const AppLoginScreen()),
    GoRoute(path: '/loginScreen', builder: (_, __) => const AppLoginScreen()),
    GoRoute(path: '/manager', builder: (_, __) => const SuperAdminEntryLoader()),

    // keep /owner stable (redirect into shell)
    GoRoute(path: '/owner', redirect: (_, __) => '/owner/home'),

    // ✅ OWNER SHELL: nav stays on all /owner/... pages
    ShellRoute(
      navigatorKey: _ownerShellKey,
      builder: (context, state, child) => _OwnerShellLoader(child: child),
      routes: [
        GoRoute(
          path: '/owner/home',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);
            return OwnerHomeScreen(
              ownerId: s.ownerId,
              dio: s.dio,
              ownerName: s.ownerName,
            );
          },
        ),
        GoRoute(
          path: '/owner/projects',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);
            return OwnerProjectsScreen(ownerId: s.ownerId, dio: s.dio);
          },
        ),
        GoRoute(
          path: '/owner/profile',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);
            return OwnerProfileScreen(dio: s.dio);
          },
        ),
        GoRoute(
          path: '/owner/project/:id',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);

            final idStr =
                state.pathParameters['id'] ?? '${projectTemplates.first.id}';
            final id = int.tryParse(idStr) ?? projectTemplates.first.id;

            final tpl = projectTemplates.firstWhere(
              (t) => t.id == id,
              orElse: () => projectTemplates.first,
            );

            return OwnerProjectDetailsScreen(tpl: tpl, ownerId: s.ownerId);
          },
        ),
        GoRoute(
          path: '/owner/requests/list',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);
            return OwnerRequestsListScreen(ownerId: s.ownerId, dio: s.dio);
          },
        ),
        GoRoute(
          path: '/owner/requests',
          builder: (context, state) {
            final s = OwnerSessionScope.of(context);
            final extra = (state.extra is Map) ? state.extra as Map : const {};

            return OwnerRequestScreen(
              baseUrl: s.dio.options.baseUrl,
              ownerId: s.ownerId,
              dio: s.dio,
              initialProjectId: _asInt(extra['projectId']),
              initialAppName: _asNonEmptyStr(extra['appName']),
            );
          },
        ),
      ],
    ),

    // ✅ owner register is OUTSIDE shell (public)
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

/// ===============================================================
/// Auth Redirect
/// ===============================================================
Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final store = JwtLocalDataSource();
  final (token, roleRaw) = await store.read();

  final role = roleRaw.toUpperCase().trim();
  final loc = state.matchedLocation;
  final isPublic = _publicPaths.contains(loc);

  if (token.isEmpty || role.isEmpty) {
    return isPublic ? null : '/login';
  }

  final goingToAuth = loc.startsWith('/login') || loc.startsWith('/owner/register');
  if (goingToAuth) return role == 'SUPER_ADMIN' ? '/manager' : '/owner/home';

  if (role == 'SUPER_ADMIN' && (loc.startsWith('/owner') || loc == '/home')) {
    return '/manager';
  }
  if (role != 'SUPER_ADMIN' && (loc.startsWith('/manager') || loc == '/home')) {
    return '/owner/home';
  }

  return null;
}

/// ===============================================================
/// JWT helpers
/// ===============================================================
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

  String? fullFromParts;
  if (first != null && last != null) {
    fullFromParts = '$first $last'.trim();
  } else if (first != null) {
    fullFromParts = first;
  }

  final raw = fullFromParts ??
      pick(claims['name']) ??
      pick(claims['fullName']) ??
      pick(claims['displayName']) ??
      pick(claims['ownerName']) ??
      pick(claims['adminName']) ??
      pick(claims['username']) ??
      pick(claims['preferred_username']);

  if (raw == null) return null;

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

/// ===============================================================
/// Owner Shell Loader
/// - builds OwnerNavShell once
/// - keeps nav visible always
/// - syncs selected tab with route
/// - navigates when tab changes
/// ===============================================================
class _OwnerShellLoader extends StatefulWidget {
  final Widget child;
  const _OwnerShellLoader({required this.child});

  @override
  State<_OwnerShellLoader> createState() => _OwnerShellLoaderState();
}

class _OwnerShellLoaderState extends State<_OwnerShellLoader> {
  late final OwnerNavCubit _nav;

  @override
  void initState() {
    super.initState();
    _nav = OwnerNavCubit(initialIndex: 0);
  }

  @override
  void dispose() {
    _nav.close();
    super.dispose();
  }

  int _indexForLoc(String loc) {
    if (loc.startsWith('/owner/projects')) return 1;
    if (loc.startsWith('/owner/profile')) return 2;
    return 0; // home + requests + details
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<(int?, String?)>(
      future: _loadOwnerProfileFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final (ownerId, ownerName) = snap.data ?? (null, null);
        if (ownerId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
          return Scaffold(body: Center(child: Text(l10n.owner_nav_home)));
        }

        final Dio dio = DioClient.ensure();

        // if you later fetch menu type from backend config, plug it here
        final backendMenuType = 'bottom';

        final loc = GoRouterState.of(context).uri.toString();
        final idx = _indexForLoc(loc);

        // keep cubit synced with current route
        if (_nav.state.index != idx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_nav.state.index != idx) _nav.setIndex(idx);
          });
        }

        // ✅ must match your NEW OwnerDestination signature (route required)
        final destinations = <OwnerDestination>[
          OwnerDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: l10n.owner_nav_home,
            route: '/owner/home',
          ),
          OwnerDestination(
            icon: Icons.apps_outlined,
            selectedIcon: Icons.apps_rounded,
            label: l10n.owner_nav_projects,
            route: '/owner/projects',
          ),
          OwnerDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.owner_nav_profile,
            route: '/owner/profile',
          ),
        ];

        return BlocProvider.value(
          value: _nav,
          child: BlocListener<OwnerNavCubit, OwnerNavState>(
            listenWhen: (p, c) => p.index != c.index,
            listener: (context, st) {
              final i = st.index.clamp(0, destinations.length - 1);
              final target = destinations[i].route;
              final current = GoRouterState.of(context).uri.toString();
              if (!current.startsWith(target)) context.go(target);
            },
            child: OwnerSessionScope(
              ownerId: ownerId,
              ownerName: ownerName,
              dio: dio,
              backendMenuType: backendMenuType,
              child: OwnerNavShell(
                backendMenuType: backendMenuType,
                destinations: destinations,
                initialIndex: idx,
                child: widget.child, // ✅ required by your updated shell
              ),
            ),
          ),
        );
      },
    );
  }
}