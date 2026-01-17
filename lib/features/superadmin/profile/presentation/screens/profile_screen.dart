import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; 
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

//  keep YOUR l10n import (since your main.dart uses it)
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/repositories/admin_repository_impl.dart';
import '../../data/services/admin_api.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/update_password.dart';
import '../../domain/usecases/update_notifications.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_form.dart';
import '../widgets/notifications_tile.dart';
import '../widgets/change_password_sheet.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';

// local storage for clearing token on logout
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class SuperAdminProfileScreen extends StatelessWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Dio dio = DioClient.ensure();
    final repo = AdminRepositoryImpl(AdminApi(dio));

    return BlocProvider(
      create: (_) => ProfileBloc(
        getMe: GetMe(repo),
        updateProfile: UpdateProfile(repo),
        updatePassword: UpdatePassword(repo),
        updateNotifications: UpdateNotifications(repo),
      )..add(LoadProfile()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) {
          AppToast.error(ctx, st.error!);
        }
        if (st.success?.isNotEmpty == true) {
          AppToast.success(ctx, st.success!);
        }
      },
      builder: (context, state) {
        if (state.loading && state.me == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.me == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 42),
                  const SizedBox(height: 8),
                  Text(l10n.err_unknown),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<ProfileBloc>().add(LoadProfile()),
                    child: Text(l10n.common_retry),
                  ),
                ],
              ),
            ),
          );
        }

        final me = state.me!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.nav_profile)),
          body: RefreshIndicator.adaptive(
            onRefresh: () async =>
                context.read<ProfileBloc>().add(RefreshProfile()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ProfileHeader(me: me),
                const SizedBox(height: 14),

                // ✅ Language switcher (this is what was missing)
                _LanguageTile(l10n: l10n),
                const SizedBox(height: 12),

                // Profile form
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profile_details,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ProfileForm(
                          me: me,
                          busy: state.savingProfile,
                          onSubmit: (p) =>
                              context.read<ProfileBloc>().add(SubmitProfile(p)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Notifications
                NotificationsTile(
                  notifyItems: me.notifyItemUpdates,
                  notifyFeedback: me.notifyUserFeedback,
                  busy: state.savingNotifications,
                  onSave: (items, fb) => context
                      .read<ProfileBloc>()
                      .add(SubmitNotifications(items, fb)),
                ),

                const SizedBox(height: 12),

                // Password
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.password_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.profile_password_hint)),
                        const SizedBox(width: 8),
                        AppButton(
                          label: l10n.profile_change_password,
                          type: AppButtonType.outline,
                          trailing: const Icon(Icons.edit_rounded),
                          isBusy: state.savingPassword,
                          onPressed: state.savingPassword
                              ? null
                              : () async {
                                  final profileBloc =
                                      context.read<ProfileBloc>();
                                  await showModalBottomSheet<bool>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BlocProvider.value(
                                      value: profileBloc,
                                      child: ChangePasswordSheet(
                                        busy: state.savingPassword,
                                        onSubmit: (c, n) async {
                                          profileBloc.add(SubmitPassword(c, n));
                                        },
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Logout Card (destructive) =====
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.common_security,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withOpacity(.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.error.withOpacity(.35),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: cs.error.withOpacity(.12),
                              child:
                                  Icon(Icons.logout_rounded, color: cs.error),
                            ),
                            title: Text(
                              l10n.common_sign_out,
                              style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              l10n.common_sign_out_hint,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () => _confirmLogout(context, l10n),
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(l10n.common_sign_out),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ===== end logout card =====
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final cs = Theme.of(context).colorScheme;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogoutConfirmSheet(l10n: l10n, cs: cs),
    );

    if (ok != true) return;

    // 1) clear token from prefs
    final store = JwtLocalDataSource();
    await store.clear();

    // 2) remove Authorization header from Dio
    final dio = DioClient.ensure();
    dio.options.headers.remove('Authorization');

    if (!context.mounted) return;

    AppToast.info(context, l10n.common_signed_out);

    // 3) route to /login
    context.go('/login');
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguageTile({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            const Icon(Icons.language_rounded),
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
      ),
    );
  }
}

class _LogoutConfirmSheet extends StatelessWidget {
  final AppLocalizations l10n;
  final ColorScheme cs;
  const _LogoutConfirmSheet({required this.l10n, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: kElevationToShadow[3],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.error.withOpacity(.12),
                  child: Icon(Icons.logout_rounded, color: cs.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.common_sign_out,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.common_sign_out_confirm,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.common_cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.common_sign_out),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
