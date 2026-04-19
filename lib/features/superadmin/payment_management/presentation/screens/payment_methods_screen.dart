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
import '../widgets/pm_list_widgets.dart';
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
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => context
                    .read<PaymentMethodBloc>()
                    .add(RefreshPaymentMethods()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Method'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async => context
                .read<PaymentMethodBloc>()
                .add(RefreshPaymentMethods()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PaymentMethodState state) {
    if (state.loading && state.items.isEmpty) return const PmLoadingView();
    if (state.error != null && state.items.isEmpty) {
      return PmErrorView(
        message: state.error!,
        onRetry: () =>
            context.read<PaymentMethodBloc>().add(LoadPaymentMethods()),
      );
    }
    if (state.items.isEmpty) {
      return const PmEmptyView(
        icon: Icons.payment_rounded,
        title: 'No payment methods yet',
        subtitle: 'Tap + to add your first payment method.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        return PaymentMethodCard(
          method: item,
          isToggling: state.togglingIds.contains(item.id),
          onToggle: (val) => context.read<PaymentMethodBloc>().add(
                TogglePaymentMethodEnabled(id: item.id, isEnabled: val),
              ),
          onEdit: () => _openForm(context, item),
        );
      },
    );
  }

  Future<void> _openForm(
      BuildContext context, PaymentMethod? existing) async {
    final bloc = context.read<PaymentMethodBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentMethodFormScreen(existing: existing),
      ),
    );
    if (result == true && context.mounted) bloc.add(RefreshPaymentMethods());
  }
}
