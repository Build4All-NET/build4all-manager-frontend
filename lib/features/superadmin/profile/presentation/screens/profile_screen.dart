import 'package:build4all_manager/core/auth/session_manager.dart';
import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../payment_management/presentation/screens/payment_methods_screen.dart';
import '../../../payment_management/presentation/screens/payment_types_screen.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/services/admin_api.dart';
import '../../domain/entities/admin_profile.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/update_notifications.dart';
import '../../domain/usecases/update_password.dart';
import '../../domain/usecases/update_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/notifications_tile.dart';
import '../widgets/profile_form.dart';

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
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 46),
                    const SizedBox(height: 10),
                    Text(l10n.err_unknown),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<ProfileBloc>().add(LoadProfile()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.common_retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final AdminProfile me = state.me!;
        final bottomSafe = MediaQuery.of(context).padding.bottom;
        final bottomPad = 16.0 + bottomSafe;

        final busyAny = state.loading ||
            state.savingProfile ||
            state.savingNotifications ||
            state.savingPassword;

        return Scaffold(
          body: RefreshIndicator.adaptive(
            onRefresh: () async => context.read<ProfileBloc>().add(
                  RefreshProfile(),
                ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverAppBar(
                  pinned: false,
                  expandedHeight: 190,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _ProfileHero(me: me),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: busyAny
                        ? const LinearProgressIndicator(minHeight: 2)
                        : const SizedBox(height: 2),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _SectionTitle(
                          icon: Icons.language_rounded,
                          title: l10n.common_language,
                        ),
                        const SizedBox(height: 10),
                        _LanguageTile(l10n: l10n),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.badge_rounded,
                          title: l10n.profile_details,
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: ProfileForm(
                              me: me,
                              busy: state.savingProfile,
                              onSubmit: (p) => context
                                  .read<ProfileBloc>()
                                  .add(SubmitProfile(p)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.notifications_active_rounded,
                          title: l10n.profile_update_notifications,
                        ),
                        const SizedBox(height: 10),
                        NotificationsTile(
                          notifyItems: me.notifyItemUpdates,
                          notifyFeedback: me.notifyUserFeedback,
                          busy: state.savingNotifications,
                          onSave: (items, fb) => context
                              .read<ProfileBloc>()
                              .add(SubmitNotifications(items, fb)),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.lock_rounded,
                          title: l10n.common_security,
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: const Icon(Icons.password_rounded),
                            title: Text(l10n.profile_change_password),
                            subtitle: Text(l10n.profile_password_hint),
                            trailing: IconButton(
                              tooltip: l10n.profile_change_password,
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
                                              profileBloc.add(
                                                SubmitPassword(c, n),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.edit_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.payments_rounded,
                          title: 'Payment Management',
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading: const Icon(Icons.credit_card_rounded),
                                title: const Text('Payment Methods'),
                                subtitle: const Text(
                                    'Manage available payment methods'),
                                trailing: const Icon(
                                    Icons.chevron_right_rounded),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentMethodsScreen(),
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading:
                                    const Icon(Icons.category_rounded),
                                title: const Text('Payment Types'),
                                subtitle: const Text(
                                    'Manage custom payment type registry'),
                                trailing: const Icon(
                                    Icons.chevron_right_rounded),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentTypesScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.common_sign_out,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.common_sign_out_hint,
                                  style:
                                      TextStyle(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                      foregroundColor: cs.onError,
                                    ),
                                    onPressed: () =>
                                        _confirmLogout(context, l10n),
                                    icon: const Icon(Icons.logout_rounded),
                                    label: Text(l10n.common_sign_out),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AppLocalizations l10n) async {
    final cs = Theme.of(context).colorScheme;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogoutConfirmSheet(l10n: l10n, cs: cs),
    );

    if (ok != true) return;

    final authApi = AuthApi(DioClient.ensure());
    final sessionManager = SessionManager(
      store: JwtLocalDataSource(),
      authApi: authApi,
    );

    final IAuthRepository repo = AuthRepositoryImpl(
      api: authApi,
      sessionManager: sessionManager,
    );

    await repo.logout();

    if (!context.mounted) return;

    AppToast.info(context, l10n.common_signed_out);
    context.go('/login');
  }
}

class _ProfileHero extends StatelessWidget {
  final AdminProfile me;
  const _ProfileHero({required this.me});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.onPrimary.withOpacity(.14),
                child: Text(
                  _initials(me.firstName, me.lastName),
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: cs.onPrimary,
                      ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${me.firstName} ${me.lastName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${me.username} • ${l10n.nav_super_admin}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        me.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String f, String l) =>
      '${(f.isNotEmpty ? f[0] : 'A')}${(l.isNotEmpty ? l[0] : 'U')}'
          .toUpperCase();
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          children: [
            const Icon(Icons.language_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.common_language,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) {
                final value = locale?.languageCode ?? 'system';

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: value,
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(
                            l10n.common_system_language,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(
                            l10n.lang_english,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(
                            l10n.lang_arabic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text(
                            l10n.lang_french,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
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
