import 'package:build4all_manager/features/notifications_admin/presentation/screens/admin_notifications_screen.dart';
import 'package:build4all_manager/features/superadmin/firebase_pool/presentation/screens/firebase_pool_screen.dart';
import 'package:build4all_manager/features/superadmin/payment_management/presentation/screens/license_plan_pricings_screen.dart';
import 'package:build4all_manager/features/superadmin/payment_management/presentation/screens/payment_methods_screen.dart';
import 'package:build4all_manager/features/superadmin/payment_management/presentation/screens/payment_types_screen.dart';
import 'package:build4all_manager/features/superadmin/payment_management/presentation/screens/plans_screen.dart';
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
  // But we rebuild it when locale changes so drawer labels update correctly.
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

      // Payment / Pricing drawer items
      SuperAdminDestination(
        icon: Icons.layers_outlined,
        selectedIcon: Icons.layers_rounded,
        label: l10n.super_nav_plans,
        page: const PlansScreen(),
      ),

      SuperAdminDestination(
        icon: Icons.sell_outlined,
        selectedIcon: Icons.sell_rounded,
        label: l10n.super_nav_plan_pricing,
        page: const LicensePlanPricingsScreen(),
      ),

      SuperAdminDestination(
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
        label: l10n.super_nav_payment_methods,
        page: const PaymentMethodsScreen(),
      ),

      SuperAdminDestination(
        icon: Icons.category_outlined,
        selectedIcon: Icons.category_rounded,
        label: l10n.super_nav_billing_types,
        page: const PaymentTypesScreen(),
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

    // Important:
    // If user changes language, rebuild labels.
    // Otherwise cached drawer labels stay in the old language.
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