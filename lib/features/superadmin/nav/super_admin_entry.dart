import 'package:build4all_manager/features/notifications_admin/presentation/screens/admin_notifications_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import 'super_admin_nav_shell.dart';

// screens
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:build4all_manager/features/superadmin/projectCreate/presentation/screens/create_project_screen.dart';
import 'package:build4all_manager/features/superadmin/publish_admin/presentation/screens/publish_requests_screen.dart';
import 'package:build4all_manager/features/superadmin/profile/presentation/screens/profile_screen.dart';

// auth storage (your existing way)
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class SuperAdminEntry extends StatelessWidget {
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

  Future<String?> _tokenProvider() async {
    final store = JwtLocalDataSource();
    final (token, _) = await store.read();
    return token.isEmpty ? null : token;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ If you don't have l10n key, don't crash the whole nav.
    final createLabel = _tryL10nCreateProject(l10n);

   final destinations = <SuperAdminDestination>[
  SuperAdminDestination(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    label: l10n.super_nav_dashboard,
    page: const DashboardScreen(),
  ),
  SuperAdminDestination(
    icon: Icons.add_box_outlined,
    selectedIcon: Icons.add_box_rounded,
    label: createLabel,
    page: CreateProjectScreen(
      dio: dio,
      baseUrl: dio.options.baseUrl,
      tokenProvider: _tokenProvider,
    ),
  ),
  SuperAdminDestination(
    icon: Icons.publish_outlined,
    selectedIcon: Icons.publish_rounded,
    label: l10n.super_nav_publish_requests,
    page: PublishRequestsScreen(dio: dio),
  ),
  SuperAdminDestination(
    icon: Icons.notifications_none_outlined,
    selectedIcon: Icons.notifications,
    label: 'Notifications',
    page: const AdminNotificationsScreen(),
  ),
  SuperAdminDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: l10n.super_nav_profile,
    page: const SuperAdminProfileScreen(),
  ),
];
    return SuperAdminNavShell(
      backendMenuType: backendMenuType,
      destinations: destinations,
      initialIndex: initialIndex,
    );
  }

  /// ✅ avoids build crash when key is missing.
  String _tryL10nCreateProject(AppLocalizations l10n) {
    // You said: getter super_nav_create_project doesn't exist.
    // So we fallback to an existing key you DO have (super_create_project_title)
    // or a hardcoded safe string.
    try {
      return l10n.super_create_project_title;
    } catch (_) {
      return 'Create Project';
    }
  }
}
