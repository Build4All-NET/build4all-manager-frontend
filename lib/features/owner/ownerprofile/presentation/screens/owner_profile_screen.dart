// lib/features/owner/ownerprofile/presentation/screens/owner_profile_screen.dart

import 'package:auto_size_text/auto_size_text.dart';
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

import 'owner_edit_profile_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  final int? ownerId; // if provided -> view someone else; else /me
  final Dio dio;

  const OwnerProfileScreen({super.key, required this.dio, this.ownerId});

  int? _normalizeOwnerId(int? id) {
    if (id == null) return null;
    if (id <= 0) return null; // treat 0/-1 as "me"
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final repo = OwnerProfileRepositoryImpl(OwnerProfileApi(dio));
    final uc = GetOwnerProfileUseCase(repo);

    final normalized = _normalizeOwnerId(ownerId);

    return BlocProvider(
      create: (_) => OwnerProfileBloc(getProfile: uc)
        ..add(OwnerProfileStarted(adminId: normalized)),
      child: _OwnerProfileView(dio: dio, ownerId: normalized),
    );
  }
}

class _OwnerProfileView extends StatelessWidget {
  final Dio dio;
  final int? ownerId; // already normalized

  const _OwnerProfileView({required this.dio, this.ownerId});

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
                title: AutoSizeText(
                  l10n.logout_confirm ?? 'Do you want to log out?',
                  maxLines: 2,
                  minFontSize: 12,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                subtitle: AutoSizeText(
                  l10n.owner_nav_profile,
                  maxLines: 1,
                  minFontSize: 11,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.ellipsis,
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
                      child: AutoSizeText(
                        l10n.cancel ?? 'Cancel',
                        maxLines: 1,
                        minFontSize: 12,
                        stepGranularity: 0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: AutoSizeText(
                        l10n.logout ?? 'Logout',
                        maxLines: 1,
                        minFontSize: 12,
                        stepGranularity: 0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Future<void> _editFlow(BuildContext context, dynamic p) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerEditProfileScreen(dio: dio, initial: p),
      ),
    );

    if (ok == true && context.mounted) {
      // refresh same mode (me vs by-id)
      context.read<OwnerProfileBloc>().add(OwnerProfileStarted(adminId: ownerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<OwnerProfileBloc, OwnerProfileState>(
      builder: (context, s) {
        final p = s.profile;

        // can edit ONLY when it's /me
        final bool canEdit = ownerId == null && p != null && !s.loading;

        final appBar = AppBar(
          title: AutoSizeText(
            l10n.owner_nav_profile,
            maxLines: 1,
            minFontSize: 14,
            stepGranularity: 0.5,
            overflow: TextOverflow.ellipsis,
          ),
        );

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AutoSizeText(
                      s.error!,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      minFontSize: 12,
                      stepGranularity: 0.5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context
                          .read<OwnerProfileBloc>()
                          .add(OwnerProfileStarted(adminId: ownerId)),
                      child: Text(l10n.retry ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (p == null) {
          return Scaffold(
            appBar: appBar,
            body: Center(
              child: AutoSizeText(
                l10n.owner_nav_profile,
                maxLines: 1,
                minFontSize: 12,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<OwnerProfileBloc>().add(
                    OwnerProfileStarted(adminId: ownerId),
                  );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool wide = constraints.maxWidth >= 720;
                const double maxCardWidth = 480;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                canEdit: canEdit,
                                onEdit: () => _editFlow(context, p),
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

/* =========================================================
 * ✅ PRIVATE WIDGETS (must be in SAME FILE to use "_" names)
 * ========================================================= */

class _PreferencesCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onLogout;

  final bool canEdit;
  final VoidCallback onEdit;

  const _PreferencesCard({
    required this.l10n,
    required this.onLogout,
    required this.canEdit,
    required this.onEdit,
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
                Expanded(
                  child: AutoSizeText(
                    l10n.settings ?? 'Settings',
                    maxLines: 1,
                    minFontSize: 14,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          // Edit profile
          Opacity(
            opacity: canEdit ? 1 : 0.45,
            child: ListTile(
              onTap: canEdit ? onEdit : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withOpacity(.12),
                child: Icon(Icons.edit_rounded, color: cs.primary, size: 18),
              ),
              title: AutoSizeText(
                l10n.owner_profile_edit_title ?? 'Edit profile',
                maxLines: 1,
                minFontSize: 12,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              subtitle: AutoSizeText(
                canEdit ? (l10n.owner_profile_edit_basic ?? 'Update your account info') : '',
                maxLines: 2,
                minFontSize: 11,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          _LanguageRow(l10n: l10n),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          // Logout
          ListTile(
            onTap: onLogout,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: cs.error.withOpacity(.12),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 18),
            ),
            title: AutoSizeText(
              l10n.logout ?? 'Logout',
              maxLines: 1,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: AutoSizeText(
              l10n.logout_confirm ?? 'Sign out of this account',
              maxLines: 2,
              minFontSize: 11,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguageRow({required this.l10n});

  String _labelFor(String code) {
    switch (code) {
      case 'system':
        return l10n.common_system_language;
      case 'en':
        return l10n.lang_english;
      case 'ar':
        return l10n.lang_arabic;
      case 'fr':
        return l10n.lang_french;
      default:
        return l10n.common_system_language;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primary.withOpacity(.12),
            child: Icon(Icons.language_rounded, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AutoSizeText(
              l10n.common_language,
              maxLines: 1,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              final value = locale?.languageCode ?? 'system';
              final codes = const ['system', 'en', 'ar', 'fr'];

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isDense: true,
                      iconEnabledColor: cs.onSurfaceVariant,
                      items: codes
                          .map(
                            (code) => DropdownMenuItem<String>(
                              value: code,
                              child: AutoSizeText(
                                _labelFor(code),
                                maxLines: 1,
                                minFontSize: 11,
                                stepGranularity: 0.5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}