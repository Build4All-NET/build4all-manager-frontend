import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/notifications_admin/data/model/admin_notification_model.dart';
import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_bloc.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_event.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_state.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/cubit/admin_unread_count_cubit.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminNotificationsBloc(
        AdminNotificationsApi(DioClient.ensure()),
      )..add(const AdminNotificationsStarted()),
      child: const _AdminNotificationsView(),
    );
  }
}

class _AdminNotificationsView extends StatelessWidget {
  const _AdminNotificationsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AdminNotificationsBloc, AdminNotificationsState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, state) {
        final error = state.error;
        if (error != null && error.trim().isNotEmpty) {
          AppToast.error(context, error);
        }

       AdminUnreadCountCubit? unreadCubit;
try {
  unreadCubit = BlocProvider.of<AdminUnreadCountCubit>(
    context,
    listen: false,
  );
} catch (_) {
  unreadCubit = null;
}
unreadCubit?.setCount(state.unreadCount);
      },
      builder: (context, state) {
        return ColoredBox(
          color: cs.surface,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () {
                              context.read<AdminNotificationsBloc>().add(
                                    const AdminNotificationsRefreshed(),
                                  );
                            },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.common_refresh),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<AdminNotificationsBloc>().add(
                            const AdminNotificationsRefreshed(),
                          );
                    },
                    child: _buildBody(context, state),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminNotificationsState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state.loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.common_loading),
              ],
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 140),
          _EmptyState(),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _NotificationCard(item: item);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AdminNotificationModel item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminNotificationsBloc>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final bg = item.isRead
        ? cs.surfaceContainerHighest.withOpacity(.35)
        : cs.primary.withOpacity(.08);

    final border = item.isRead ? cs.outlineVariant : cs.primary.withOpacity(.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (!item.isRead) {
            bloc.add(AdminNotificationMarkedRead(item.id));
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingDot(isRead: item.isRead),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              item.isRead ? FontWeight.w500 : FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 15,
                            color: cs.outline,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatDate(context, item.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'read' && !item.isRead) {
                      bloc.add(AdminNotificationMarkedRead(item.id));
                    } else if (value == 'delete') {
                      bloc.add(AdminNotificationDeleted(item.id));
                    }
                  },
                  itemBuilder: (context) => [
                    if (!item.isRead)
                      PopupMenuItem<String>(
                        value: 'read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.admin_notifications_mark_as_read),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.common_delete),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? dt) {
    final l10n = AppLocalizations.of(context)!;

    if (dt == null) return l10n.common_unknown;

    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return l10n.timeago_just_now;
    if (diff.inMinutes < 60) return l10n.timeago_minutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeago_hours(diff.inHours);
    if (diff.inDays < 7) return l10n.timeago_days(diff.inDays);

    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    return '$y-$m-$d  $hh:$mm';
  }
}

class _LeadingDot extends StatelessWidget {
  final bool isRead;

  const _LeadingDot({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isRead ? cs.surfaceContainerHighest : cs.primary.withOpacity(.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        isRead ? Icons.notifications_none_outlined : Icons.notifications_active,
        size: 20,
        color: isRead ? cs.outline : cs.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: cs.outline,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.admin_notifications_empty_title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.admin_notifications_empty_subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.outline,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}