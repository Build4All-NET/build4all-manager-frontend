import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../domain/entities/firebase_project_account.dart';
import '../bloc/firebase_pool_bloc.dart';
import '../bloc/firebase_pool_event.dart';
import '../bloc/firebase_pool_state.dart';
import 'firebase_pool_form_screen.dart';

class FirebasePoolScreen extends StatelessWidget {
  const FirebasePoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebasePoolBloc()..add(LoadFirebasePool()),
      child: const _FirebasePoolView(),
    );
  }
}

class _FirebasePoolView extends StatelessWidget {
  const _FirebasePoolView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirebasePoolBloc, FirebasePoolState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Firebase Project Pool'),
            centerTitle: false,
            actions: [
              if (state.loading && state.items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () =>
                    context.read<FirebasePoolBloc>().add(RefreshFirebasePool()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Account'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async =>
                context.read<FirebasePoolBloc>().add(RefreshFirebasePool()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FirebasePoolState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<FirebasePoolBloc>().add(LoadFirebasePool()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Firebase accounts yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first Firebase project account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        final isActing = state.actingIds.contains(item.id);
        return _FirebaseAccountCard(
          account: item,
          isActing: isActing,
          onEnable: () =>
              context.read<FirebasePoolBloc>().add(EnableFirebaseAccount(item.id)),
          onDisable: () =>
              context.read<FirebasePoolBloc>().add(DisableFirebaseAccount(item.id)),
          onSetDefault: () => context
              .read<FirebasePoolBloc>()
              .add(SetDefaultFirebaseAccount(item.id)),
          onEdit: () => _openForm(context, item),
        );
      },
    );
  }

  Future<void> _openForm(
      BuildContext context, FirebaseProjectAccount? existing) async {
    final bloc = context.read<FirebasePoolBloc>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FirebasePoolFormScreen(existing: existing),
      ),
    );
    if (saved == true && context.mounted) {
      bloc.add(RefreshFirebasePool());
    }
  }
}

class _FirebaseAccountCard extends StatelessWidget {
  final FirebaseProjectAccount account;
  final bool isActing;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;

  const _FirebaseAccountCard({
    required this.account,
    required this.isActing,
    required this.onEnable,
    required this.onDisable,
    required this.onSetDefault,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, cs),
          const Divider(height: 1),
          _buildCapacity(context, cs),
          const Divider(height: 1),
          _buildActions(context, cs),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor(account.status).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storage_rounded,
              color: _statusColor(account.status),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (account.isDefault) ...
                      [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  account.firebaseProjectId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurface.withOpacity(.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: account.status),
        ],
      ),
    );
  }

  Widget _buildCapacity(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: _CapacityBar(
              label: 'Android',
              icon: Icons.android_rounded,
              iconColor: const Color(0xFF16A34A),
              used: account.usedAndroidApps,
              max: account.maxAndroidApps,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CapacityBar(
              label: 'iOS',
              icon: Icons.apple_rounded,
              iconColor: cs.onSurface,
              used: account.usedIosApps,
              max: account.maxIosApps,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme cs) {
    final isEnabled = account.isActive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          if (isActing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isEnabled,
              onChanged: (_) => isEnabled ? onDisable() : onEnable(),
            ),
          const SizedBox(width: 4),
          Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isEnabled
                  ? const Color(0xFF16A34A)
                  : cs.onSurface.withOpacity(.5),
            ),
          ),
          const Spacer(),
          if (!account.isDefault)
            OutlinedButton(
              onPressed: isActing ? null : onSetDefault,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Set Default',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit',
            onPressed: isActing ? null : onEdit,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'RATE_LIMITED':
        return const Color(0xFFD97706);
      case 'FULL':
        return const Color(0xFF7C3AED);
      case 'FAILED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        fg = const Color(0xFF15803D);
        bg = const Color(0xFFDCFCE7);
        label = 'ACTIVE';
        break;
      case 'RATE_LIMITED':
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        label = 'RATE LIMITED';
        break;
      case 'FULL':
        fg = const Color(0xFF6D28D9);
        bg = const Color(0xFFEDE9FE);
        label = 'FULL';
        break;
      case 'FAILED':
        fg = const Color(0xFFB91C1C);
        bg = const Color(0xFFFEE2E2);
        label = 'FAILED';
        break;
      case 'RESERVED':
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFDBEAFE);
        label = 'RESERVED';
        break;
      default:
        fg = const Color(0xFF374151);
        bg = const Color(0xFFF3F4F6);
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final int used;
  final int max;

  const _CapacityBar({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.used,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();
    final barColor = ratio >= 0.9
        ? const Color(0xFFDC2626)
        : ratio >= 0.75
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$used / $max  ($pct%)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
