import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/payment_method_repository_impl.dart';
import '../../data/services/payment_method_api.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/usecases/create_payment_method.dart';
import '../../domain/usecases/get_payment_methods.dart';
import '../../domain/usecases/toggle_payment_method.dart';
import '../../domain/usecases/update_payment_method.dart';
import '../bloc/payment_method_bloc.dart';
import '../bloc/payment_method_event.dart';
import '../bloc/payment_method_state.dart';
import '../widgets/payment_method_card.dart';
import 'payment_method_form_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo =
        PaymentMethodRepositoryImpl(PaymentMethodApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PaymentMethodBloc(
        getPaymentMethods: GetPaymentMethods(repo),
        createPaymentMethod: CreatePaymentMethod(repo),
        updatePaymentMethod: UpdatePaymentMethod(repo),
        togglePaymentMethod: TogglePaymentMethod(repo),
      )..add(LoadPaymentMethods()),
      child: const _PaymentMethodsView(),
    );
  }
}

class _PaymentMethodsView extends StatelessWidget {
  const _PaymentMethodsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentMethodBloc, PaymentMethodState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Methods'),
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
                onPressed: () => context.read<PaymentMethodBloc>().add(RefreshPaymentMethods()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Method'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async => context.read<PaymentMethodBloc>().add(RefreshPaymentMethods()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PaymentMethodState state) {
    if (state.loading && state.items.isEmpty) return const _LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => context.read<PaymentMethodBloc>().add(LoadPaymentMethods()),
      );
    }
    if (state.items.isEmpty) return const _EmptyView();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        return PaymentMethodCard(
          method: item,
          isToggling: state.togglingIds.contains(item.id),
          onToggle: (val) => context.read<PaymentMethodBloc>().add(TogglePaymentMethodEnabled(id: item.id, isEnabled: val)),
          onEdit: () => _openForm(context, item),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, PaymentMethod? existing) async {
    final bloc = context.read<PaymentMethodBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentMethodFormScreen(existing: existing)),
    );
    if (result == true && context.mounted) bloc.add(RefreshPaymentMethods());
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
            Container(height: 12, width: 100, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6))),
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
                  Icon(Icons.payment_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(.4)),
                  const SizedBox(height: 16),
                  Text('No payment methods yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Tap + to add your first payment method.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
