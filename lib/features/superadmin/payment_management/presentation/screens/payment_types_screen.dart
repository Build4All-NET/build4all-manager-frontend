import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/payment_type_repository_impl.dart';
import '../../data/services/payment_type_api.dart';
import '../../domain/entities/managed_payment_type.dart';
import '../../domain/usecases/create_payment_type.dart';
import '../../domain/usecases/get_payment_types.dart';
import '../../domain/usecases/toggle_payment_type.dart';
import '../../domain/usecases/update_payment_type.dart';
import '../bloc/payment_type_bloc.dart';
import '../bloc/payment_type_event.dart';
import '../bloc/payment_type_state.dart';
import '../widgets/payment_type_card.dart';
import 'payment_type_form_screen.dart';

class PaymentTypesScreen extends StatelessWidget {
  const PaymentTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PaymentTypeRepositoryImpl(PaymentTypeApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PaymentTypeBloc(
        getPaymentTypes: GetPaymentTypes(repo),
        createPaymentType: CreatePaymentType(repo),
        updatePaymentType: UpdatePaymentType(repo),
        togglePaymentType: TogglePaymentType(repo),
      )..add(LoadPaymentTypes()),
      child: const _PaymentTypesView(),
    );
  }
}

class _PaymentTypesView extends StatelessWidget {
  const _PaymentTypesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentTypeBloc, PaymentTypeState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Types'),
            centerTitle: false,
            actions: [
              if (state.loading && state.items.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => context.read<PaymentTypeBloc>().add(RefreshPaymentTypes()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Type'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async => context.read<PaymentTypeBloc>().add(RefreshPaymentTypes()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PaymentTypeState state) {
    if (state.loading && state.items.isEmpty) return const _LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => context.read<PaymentTypeBloc>().add(LoadPaymentTypes()),
      );
    }
    if (state.items.isEmpty) return const _EmptyView();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        return PaymentTypeCard(
          type: item,
          isToggling: state.togglingIds.contains(item.id),
          onToggle: (val) => context.read<PaymentTypeBloc>().add(TogglePaymentTypeActive(id: item.id, isActive: val)),
          onEdit: () => _openForm(context, item),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, ManagedPaymentType? existing) async {
    final bloc = context.read<PaymentTypeBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentTypeFormScreen(existing: existing)),
    );
    if (result == true && context.mounted) bloc.add(RefreshPaymentTypes());
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 160, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(height: 12, width: 80, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(.4)),
                  const SizedBox(height: 16),
                  Text('No payment types yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Tap + to create your first payment type.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
