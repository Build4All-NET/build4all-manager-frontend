import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/network/globals.dart' as g;

import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:build4all_manager/features/superadmin/nav/super_admin_nav_shell.dart';
import 'package:build4all_manager/features/superadmin/profile/presentation/screens/profile_screen.dart';
import 'package:build4all_manager/features/superadmin/projectCreate/presentation/screens/create_project_screen.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  /// pass "top" | "bottom" | "drawer" from backend active theme if you have it
  final String? menuType;

  /// force a mode for testing: SuperMenuType.top / bottom / drawer
  final SuperMenuType? overrideMenu;

  const SuperAdminHomeScreen({
    super.key,
    this.menuType,
    this.overrideMenu,
  });

  @override
  Widget build(BuildContext context) {
    final Dio dio = DioClient.ensure();
    final l10n = AppLocalizations.of(context)!;

    // ✅ IMPORTANT:
    // g.appServerRoot is usually "http://host:8080/api"
    // CreateProjectScreen normally wants "http://host:8080"
    final String baseUrl = g.serverRootNoApi();

    // ✅ token provider from the same local datasource used by interceptor
    final jwt = JwtLocalDataSource();
    Future<String?> tokenProvider() async {
      final (token, _) = await jwt.read();
      return token.trim().isNotEmpty ? token.trim() : null;
    }

    final destinations = <SuperAdminDestination>[
      SuperAdminDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: l10n.nav_dashboard,
        page:
            const DashboardScreen(), // ✅ content-only screen (no nested appbar)
      ),
      SuperAdminDestination(
        icon: Icons.add_box_outlined,
        selectedIcon: Icons.add_box,
        label: l10n.super_create_project_title,
        page: CreateProjectScreen(
          dio: dio,
          baseUrl: baseUrl,
          tokenProvider: tokenProvider,
        ),
      ),
      SuperAdminDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.nav_profile,
        page: const SuperAdminProfileScreen(),
      ),
    ];

    return SuperAdminNavShell(
      destinations: destinations,
      backendMenuType: menuType,
      override: overrideMenu,
    );
  }
}
