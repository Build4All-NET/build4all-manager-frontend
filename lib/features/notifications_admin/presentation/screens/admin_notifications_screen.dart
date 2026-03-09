import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/notifications_admin/data/model/admin_notification_model.dart';

import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';

import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_bloc.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_event.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/bloc/admin_notifications_state.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/cubit/admin_unread_count_cubit.dart';
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

    return BlocConsumer<AdminNotificationsBloc, AdminNotificationsState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
    listener: (context, state) {
  final error = state.error;
  if (error != null && error.trim().isNotEmpty) {
    AppToast.error(context, error);
  }

  final unreadCubit = context.read<AdminUnreadCountCubit?>();
  unreadCubit?.setCount(state.unreadCount);
},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.loading
                    ? null
                    : () {
                        context.read<AdminNotificationsBloc>().add(
                              const AdminNotificationsRefreshed(),
                            );
                      },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<AdminNotificationsBloc>().add(
                      const AdminNotificationsRefreshed(),
                    );
              },
              child: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminNotificationsState state) {
    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
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
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
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
                              _formatDate(item.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'NEW',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Actions',
                  onSelected: (value) {
                    if (value == 'read' && !item.isRead) {
                      bloc.add(AdminNotificationMarkedRead(item.id));
                    } else if (value == 'delete') {
                      bloc.add(AdminNotificationDeleted(item.id));
                    }
                  },
                  itemBuilder: (context) => [
                    if (!item.isRead)
                      const PopupMenuItem<String>(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown date';

    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';

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
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When something important happens, it will show up here.',
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