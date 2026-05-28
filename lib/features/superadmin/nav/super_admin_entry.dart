
import 'package:build4all_manager/features/notifications_admin/presentation/screens/admin_notifications_screen.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/presentation/screens/firebase_pool_screen.dart';
import 'package:build4all_manager/features/superadmin/sprint_release/presentation/cubit/sprint_release_cubit.dart';
import 'package:build4all_manager/features/superadmin/sprint_release/presentation/screens/sprint_release_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import 'super_admin_nav_shell.dart';

// screens
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:build4all_manager/features/superadmin/projectCreate/presentation/screens/create_project_screen.dart';
import 'package:build4all_manager/features/superadmin/publish_admin/presentation/screens/publish_requests_screen.dart';
import 'package:build4all_manager/features/superadmin/profile/presentation/screens/profile_screen.dart';

// auth storage
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class SuperAdminEntry extends StatefulWidget {
  final String? backendMenuType;
  final int adminId;
  final String? adminName;
  final Dio dio;
  final int initialIndex;

  const SuperAdminEntry({
    super.key,
    required this.adminId,
    required this.dio,
    this.backendMenuType,
    this.adminName,
    this.initialIndex = 0,
  });

  @override
  State<SuperAdminEntry> createState() => _SuperAdminEntryState();
}

class _SuperAdminEntryState extends State<SuperAdminEntry> {
  // Cached once on first build — avoids recreating all page widgets on every
  // parent setState (e.g. notification-count polling) which causes all
  // IndexedStack children to remount simultaneously.
  List<SuperAdminDestination>? _destinations;

  Future<String?> _tokenProvider() async {
    final store = JwtLocalDataSource();
    final (token, _) = await store.read();
    return token.isEmpty ? null : token;
  }

  List<SuperAdminDestination> _buildDestinations(AppLocalizations l10n) {
    return [
      SuperAdminDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: l10n.super_nav_dashboard,
        page: DashboardScreen(dio: widget.dio),
      ),
      SuperAdminDestination(
        icon: Icons.add_box_outlined,
        selectedIcon: Icons.add_box_rounded,
        label: l10n.super_create_project_title,
        page: CreateProjectScreen(
          dio: widget.dio,
          baseUrl: widget.dio.options.baseUrl,
          tokenProvider: _tokenProvider,
        ),
      ),
      SuperAdminDestination(
        icon: Icons.publish_outlined,
        selectedIcon: Icons.publish_rounded,
        label: l10n.owner_nav_requests,
        page: PublishRequestsScreen(dio: widget.dio),
      ),
      SuperAdminDestination(
        icon: Icons.storage_outlined,
        selectedIcon: Icons.storage_rounded,
        label: 'Firebase Pool',
        page: const FirebasePoolScreen(),
      ),
      SuperAdminDestination(
        icon: Icons.rocket_launch_outlined,
        selectedIcon: Icons.rocket_launch_rounded,
        label: 'Workflows',
        page: BlocProvider(
          create: (_) => SprintReleaseCubit(),
          child: const SprintReleaseScreen(),
        ),
      ),
      SuperAdminDestination(
        icon: Icons.notifications_none_outlined,
        selectedIcon: Icons.notifications,
        label: l10n.super_nav_notifications,
        page: const AdminNotificationsScreen(),
      ),
      SuperAdminDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.super_nav_profile,
        page: const SuperAdminProfileScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _destinations ??= _buildDestinations(AppLocalizations.of(context)!);

    return SuperAdminNavShell(
      backendMenuType: widget.backendMenuType,
      override: SuperMenuType.drawer,
      destinations: _destinations!,
      initialIndex: widget.initialIndex,
    );
  }
}
