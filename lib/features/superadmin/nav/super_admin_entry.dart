import 'package:build4all_manager/features/superadmin/profile/presentation/screens/profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import 'super_admin_nav_shell.dart';

// ✅ replace these with your real screens
import 'package:build4all_manager/features/auth/presentation/screens/super_admin_home_screen.dart';

import 'package:build4all_manager/features/superadmin/publish_admin/presentation/screens/publish_requests_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = <SuperAdminDestination>[
      SuperAdminDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: l10n.super_nav_dashboard,
        page: const SuperAdminHomeScreen(),
      ),
      SuperAdminDestination(
        icon: Icons.publish_outlined,
        selectedIcon: Icons.publish_rounded,
        label: l10n.super_nav_publish_requests,
        page: PublishRequestsScreen(dio: dio),
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
}
