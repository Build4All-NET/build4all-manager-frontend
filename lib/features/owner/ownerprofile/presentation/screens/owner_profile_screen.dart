import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/core/auth/session_manager.dart';
import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:build4all_manager/features/owner/ownerprofile/data/repositories/owner_profile_repository_impl.dart';
import 'package:build4all_manager/features/owner/ownerprofile/data/services/owner_profile_api.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/delete_owner_account_usecase.dart';
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
  final int? ownerId;
  final Dio dio;

  const OwnerProfileScreen({
    super.key,
    required this.dio,
    this.ownerId,
  });

  int? _normalizeOwnerId(int? id) {
    if (id == null) return null;
    if (id <= 0) return null;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final repo = OwnerProfileRepositoryImpl(OwnerProfileApi(dio));
    final getProfileUc = GetOwnerProfileUseCase(repo);
    final deleteAccountUc = DeleteOwnerAccountUseCase(repo);

    final normalized = _normalizeOwnerId(ownerId);

    return BlocProvider(
      create: (_) => OwnerProfileBloc(
        getProfile: getProfileUc,
        deleteAccount: deleteAccountUc,
      )..add(OwnerProfileStarted(adminId: normalized)),
      child: _OwnerProfileView(
        dio: dio,
        ownerId: normalized,
      ),
    );
  }
}

class _OwnerProfileView extends StatelessWidget {
  final Dio dio;
  final int? ownerId;

  const _OwnerProfileView({
    required this.dio,
    this.ownerId,
  });

  Future<void> _logoutFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: AutoSizeText(
                  l10n.owner_nav_profile,
                  maxLines: 1,
                  minFontSize: 11,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: cs.error.withOpacity(.12),
                  child: Icon(
                    Icons.logout_rounded,
                    color: cs.error,
                  ),
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

    await _logoutFromBackendSafely();

    if (!context.mounted) return;

    AppToast.success(
      context,
      l10n.logged_out ?? 'Logged out',
    );

    context.go('/login');
  }

  Future<void> _logoutFromBackendSafely() async {
    final authApi = AuthApi(DioClient.ensure());
    final sessionManager = SessionManager(
      store: JwtLocalDataSource(),
      authApi: authApi,
    );

    final IAuthRepository repo = AuthRepositoryImpl(
      api: authApi,
      sessionManager: sessionManager,
    );

    try {
      await repo.logout();
    } catch (_) {
      // Keep logout navigation safe even if backend logout fails.
    }
  }

  Future<void> _clearLocalSessionOnly() async {
    final sessionManager = SessionManager(
      store: JwtLocalDataSource(),
      authApi: AuthApi(DioClient.ensure()),
    );

    await sessionManager.clearSession();
  }

  Future<void> _deleteAccountFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final String? password = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return _DeleteAccountSheet(l10n: l10n);
      },
    );

    final cleanedPassword = password?.trim();

    if (cleanedPassword == null || cleanedPassword.isEmpty) return;
    if (!context.mounted) return;

    context.read<OwnerProfileBloc>().add(
          OwnerProfileDeleteRequested(password: cleanedPassword),
        );
  }

  Future<void> _editFlow(BuildContext context, dynamic p) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnerEditProfileScreen(
          dio: dio,
          initial: p,
        ),
      ),
    );

    if (ok == true && context.mounted) {
      context.read<OwnerProfileBloc>().add(
            OwnerProfileStarted(adminId: ownerId),
          );
    }
  }

  String _friendlyDeleteError(AppLocalizations l10n, String raw) {
    final lower = raw.toLowerCase();

    final looksLikePasswordError = lower.contains('password') ||
        lower.contains('incorrect') ||
        lower.contains('wrong') ||
        lower.contains('invalid credentials') ||
        lower.contains('bad credentials');

    final looksGeneric = lower.contains('something went wrong') ||
        lower.contains('bad request') ||
        lower.trim().isEmpty;

    if (looksLikePasswordError || looksGeneric) {
      return l10n.owner_profile_delete_incorrect_password;
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OwnerProfileBloc, OwnerProfileState>(
      listenWhen: (previous, current) {
        return previous.deleteSuccess != current.deleteSuccess ||
            previous.deleteError != current.deleteError;
      },
      listener: (context, s) async {
        final deleteError = s.deleteError?.trim();

        if (deleteError != null && deleteError.isNotEmpty) {
          AppToast.error(
            context,
            _friendlyDeleteError(l10n, deleteError),
          );
          return;
        }

        if (s.deleteSuccess) {
          await _clearLocalSessionOnly();

          if (!context.mounted) return;

          AppToast.success(
            context,
            l10n.owner_profile_delete_success,
          );

          await Future.delayed(const Duration(milliseconds: 250));

          if (!context.mounted) return;

          context.go('/login');
        }
      },
      builder: (context, s) {
        final p = s.profile;
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
            body: const Center(
              child: CircularProgressIndicator(),
            ),
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
                      onPressed: () {
                        context.read<OwnerProfileBloc>().add(
                              OwnerProfileStarted(adminId: ownerId),
                            );
                      },
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

        return Stack(
          children: [
            Scaffold(
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
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              20,
                              16,
                              24,
                            ),
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
                                    onDeleteAccount: () {
                                      _deleteAccountFlow(context);
                                    },
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
            ),
            if (s.deletingAccount)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(.22),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DeleteAccountSheet extends StatefulWidget {
  final AppLocalizations l10n;

  const _DeleteAccountSheet({
    required this.l10n,
  });

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final TextEditingController _passwordController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _localError = widget.l10n.owner_profile_delete_password_required;
      });
      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = widget.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: cs.error.withOpacity(.12),
              child: Icon(
                Icons.delete_forever_rounded,
                color: cs.error,
              ),
            ),
            title: AutoSizeText(
              l10n.owner_profile_delete_confirm_title,
              maxLines: 2,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.error,
              ),
            ),
            subtitle: AutoSizeText(
              l10n.owner_profile_delete_confirm_message,
              maxLines: 6,
              minFontSize: 11,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.owner_profile_delete_password_hint,
              errorText: _localError,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
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
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: AutoSizeText(
                    l10n.owner_profile_delete_action,
                    maxLines: 1,
                    minFontSize: 11,
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
  }
}

class _PreferencesCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final bool canEdit;
  final VoidCallback onEdit;

  const _PreferencesCard({
    required this.l10n,
    required this.onLogout,
    required this.onDeleteAccount,
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
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withOpacity(.7),
          ),
          Opacity(
            opacity: canEdit ? 1 : 0.45,
            child: ListTile(
              onTap: canEdit ? onEdit : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withOpacity(.12),
                child: Icon(
                  Icons.edit_rounded,
                  color: cs.primary,
                  size: 18,
                ),
              ),
              title: AutoSizeText(
                l10n.owner_profile_edit_title ?? 'Edit profile',
                maxLines: 1,
                minFontSize: 12,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: AutoSizeText(
                canEdit
                    ? (l10n.owner_profile_edit_basic ??
                        'Update your account info')
                    : '',
                maxLines: 2,
                minFontSize: 11,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withOpacity(.7),
          ),
          _LanguageRow(l10n: l10n),
          Divider(
            height: 1,
            color: cs.outlineVariant.withOpacity(.7),
          ),
          ListTile(
            onTap: onDeleteAccount,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: cs.error.withOpacity(.12),
              child: Icon(
                Icons.delete_forever_rounded,
                color: cs.error,
                size: 18,
              ),
            ),
            title: AutoSizeText(
              l10n.owner_profile_delete_action,
              maxLines: 1,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.error,
              ),
            ),
            subtitle: AutoSizeText(
              l10n.owner_profile_delete_subtitle,
              maxLines: 2,
              minFontSize: 11,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withOpacity(.7),
          ),
          ListTile(
            onTap: onLogout,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: cs.error.withOpacity(.12),
              child: Icon(
                Icons.logout_rounded,
                color: cs.error,
                size: 18,
              ),
            ),
            title: AutoSizeText(
              l10n.logout ?? 'Logout',
              maxLines: 1,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: AutoSizeText(
              l10n.logout_confirm ?? 'Sign out of this account',
              maxLines: 2,
              minFontSize: 11,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocalizations l10n;

  const _LanguageRow({
    required this.l10n,
  });

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
            child: Icon(
              Icons.language_rounded,
              size: 18,
              color: cs.primary,
            ),
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