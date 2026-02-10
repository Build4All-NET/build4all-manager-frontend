// lib/features/owner/ownerprofile/presentation/screens/owner_profile_screen.dart

import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/features/owner/ownerprofile/data/repositories/owner_profile_repository_impl.dart';
import 'package:build4all_manager/features/owner/ownerprofile/data/services/owner_profile_api.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/get_owner_profile_usecase.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/bloc/owner_profile_bloc.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/bloc/owner_profile_event.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/bloc/owner_profile_state.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/widgets/profile_header.dart';
import 'package:build4all_manager/features/owner/ownerprofile/presentation/widgets/profile_info_card.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OwnerProfileScreen extends StatelessWidget {
  final int? ownerId; // optional: if provided, fetch by id; else /me
  final Dio dio;

  const OwnerProfileScreen({super.key, required this.dio, this.ownerId});

  @override
  Widget build(BuildContext context) {
    final repo = OwnerProfileRepositoryImpl(OwnerProfileApi(dio));
    final uc = GetOwnerProfileUseCase(repo);

    return BlocProvider(
      create: (_) => OwnerProfileBloc(getProfile: uc)
        ..add(OwnerProfileStarted(adminId: ownerId)),
      child: const _OwnerProfileView(),
    );
  }
}

class _OwnerProfileView extends StatelessWidget {
  const _OwnerProfileView();

  Future<void> _logoutFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.logout_confirm ?? 'Do you want to log out?',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  l10n.owner_nav_profile,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                leading: CircleAvatar(
                  backgroundColor: cs.error.withOpacity(.12),
                  child: Icon(Icons.logout_rounded, color: cs.error),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.logout ?? 'Logout'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    final store = JwtLocalDataSource();
    await store.clear();

    if (!context.mounted) return;

    AppToast.success(context, l10n.logged_out ?? 'Logged out');
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<OwnerProfileBloc, OwnerProfileState>(
      builder: (context, s) {
        final appBar = _ProfileAppBar(onLogout: () => _logoutFlow(context));

        if (s.loading) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (s.error != null) {
          return Scaffold(
            appBar: appBar,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.error!, textAlign: TextAlign.center),
              ),
            ),
          );
        }

        final p = s.profile;
        if (p == null) {
          return Scaffold(
            appBar: appBar,
            body: Center(child: Text(l10n.owner_nav_profile)),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: RefreshIndicator(
            onRefresh: () async =>
                context.read<OwnerProfileBloc>().add(OwnerProfileRefreshed()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool wide = constraints.maxWidth >= 720;
                const double maxCardWidth = 480;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: wide ? maxCardWidth : double.infinity,
                              child: ProfileHeader(p: p),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: wide ? maxCardWidth : double.infinity,
                              child: ProfileInfoCard(p: p),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: wide ? maxCardWidth : double.infinity,
                              child: _PreferencesCard(
                                l10n: l10n,
                                onLogout: () => _logoutFlow(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogout;
  const _ProfileAppBar({this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(l10n.owner_nav_profile),
      actions: [
        IconButton(
          tooltip: l10n.logout ?? 'Logout',
          onPressed: onLogout,
          icon: Icon(Icons.logout_rounded, color: cs.onSurface),
        ),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onLogout;

  const _PreferencesCard({
    required this.l10n,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  // If you don't have l10n.settings, fallback is fine
                  l10n.settings ?? 'Settings',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          // ✅ language row (NO nested Card)
          _LanguageRow(l10n: l10n),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          ListTile(
            onTap: onLogout,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: cs.error.withOpacity(.12),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 18),
            ),
            title: Text(
              l10n.logout ?? 'Logout',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              l10n.logout_confirm ?? 'Sign out of this account',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing:
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ✅ Professional: row inside settings card (not a card on its own)
class _LanguageRow extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguageRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0x1A000000),
            child: Icon(Icons.language_rounded, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.common_language)),
          const SizedBox(width: 8),
          BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              final value = locale?.languageCode ?? 'system';

              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n.common_system_language),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.lang_english),
                    ),
                    DropdownMenuItem(
                      value: 'ar',
                      child: Text(l10n.lang_arabic),
                    ),
                    DropdownMenuItem(
                      value: 'fr',
                      child: Text(l10n.lang_french),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final cubit = context.read<LocaleCubit>();
                    if (v == 'system') {
                      cubit.setLocale(null);
                    } else {
                      cubit.setLocale(Locale(v));
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
