import 'dart:async';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';

import 'package:build4all_manager/shared/widgets/notification_badge.dart';
import 'package:flutter/material.dart';

class AdminNotificationBell extends StatefulWidget {
  final Future<void> Function()? onTap;
  final String? tooltip;

  const AdminNotificationBell({
    super.key,
    this.onTap,
    this.tooltip,
  });

  @override
  State<AdminNotificationBell> createState() => _AdminNotificationBellState();
}

class _AdminNotificationBellState extends State<AdminNotificationBell>
    with WidgetsBindingObserver {
  late final AdminNotificationsApi _api;
  Timer? _timer;

  int _count = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = AdminNotificationsApi(DioClient.ensure());

    _loadCount();

    // Simple polling for first version
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadCount(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCount(silent: true);
    }
  }

  Future<void> _loadCount({bool silent = false}) async {
    if (_loading) return;

    _loading = true;
    try {
      final count = await _api.getUnreadCount();
      if (mounted) {
        setState(() => _count = count);
      }
    } catch (_) {
      // Keep badge silent on failure
    } finally {
      _loading = false;
    }
  }

  Future<void> _handleTap() async {
    if (widget.onTap != null) {
      await widget.onTap!.call();
    }
    await _loadCount(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: _count,
      tooltip: widget.tooltip ?? 'Notifications',
      onTap: _handleTap,
    );
  }
}