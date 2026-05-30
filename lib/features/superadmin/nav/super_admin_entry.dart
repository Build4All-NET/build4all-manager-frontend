import 'package:build4all_manager/features/notifications_admin/presentation/screens/admin_notifications_screen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/apps_licenses_screen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/upgrade_requests_screen.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/presentation/screens/firebase_pool_screen.dart';
import 'package:build4all_manager/features/superadmin/ios_internal_testing/presentation/screens/super_admin_ios_internal_testing_screen.dart';
import 'package:build4all_manager/features/superadmin/payment_management/presentation/screens/payment_management_screen.dart';
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
  // Cached to avoid recreating all page widgets on every rebuild.
  // Rebuilt only when locale changes so drawer labels update correctly.
  List<SuperAdminDestination>? _destinations;
  String? _lastLocaleTag;

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
        label: l10n.super_nav_firebase_pool,
        page: const FirebasePoolScreen(),
      ),

      // One clean drawer item for all payment submodules.
      SuperAdminDestination(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: l10n.super_nav_payment,
        page: const PaymentManagementScreen(),
      ),

      // Moved from Dashboard to Drawer.
      SuperAdminDestination(
        icon: Icons.verified_user_outlined,
        selectedIcon: Icons.verified_user_rounded,
        label: l10n.super_nav_licenses,
        page: const AppsLicensesScreen(),
      ),

      // Moved from Dashboard to Drawer.
      SuperAdminDestination(
        icon: Icons.upgrade_outlined,
        selectedIcon: Icons.upgrade_rounded,
        label: l10n.super_nav_upgrade_requests,
        page: const SuperAdminUpgradeRequestsScreen(),
      ),

      // Moved from Dashboard to Drawer.
      SuperAdminDestination(
        icon: Icons.phone_iphone_outlined,
        selectedIcon: Icons.phone_iphone_rounded,
        label: l10n.super_nav_ios_internal_testing,
        page: SuperAdminIosInternalTestingScreen(
          dio: widget.dio,
        ),
      ),

      SuperAdminDestination(
        icon: Icons.rocket_launch_outlined,
        selectedIcon: Icons.rocket_launch_rounded,
        label: l10n.super_nav_workflows,
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
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    if (_destinations == null || _lastLocaleTag != localeTag) {
      _lastLocaleTag = localeTag;
      _destinations = _buildDestinations(l10n);
    }

    return SuperAdminNavShell(
      backendMenuType: widget.backendMenuType,
      override: SuperMenuType.drawer,
      destinations: _destinations!,
      initialIndex: widget.initialIndex,
    );
  }
}