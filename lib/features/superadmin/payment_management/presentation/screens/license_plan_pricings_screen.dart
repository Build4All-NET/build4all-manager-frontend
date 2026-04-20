import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/license_plan_pricing_repository_impl.dart';
import '../../data/services/license_plan_pricing_api.dart';
import '../../domain/entities/license_plan_pricing.dart';
import '../../domain/usecases/create_license_plan_pricing.dart';
import '../../domain/usecases/get_license_plan_pricings.dart';
import '../../domain/usecases/toggle_license_plan_pricing.dart';
import '../../domain/usecases/update_license_plan_pricing.dart';
import '../bloc/license_plan_pricing_bloc.dart';
import '../bloc/license_plan_pricing_event.dart';
import '../bloc/license_plan_pricing_state.dart';
import '../widgets/license_plan_pricing_card.dart';
import '../widgets/pm_list_widgets.dart';
import 'license_plan_pricing_form_screen.dart';

class LicensePlanPricingsScreen extends StatelessWidget {
  const LicensePlanPricingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = LicensePlanPricingApi(DioClient.ensure());
    final repo = LicensePlanPricingRepositoryImpl(api);
    return BlocProvider(
      create: (_) => LicensePlanPricingBloc(
        getAll: GetLicensePlanPricings(repo),
        createOne: CreateLicensePlanPricing(repo),
        updateOne: UpdateLicensePlanPricing(repo),
        toggleOne: ToggleLicensePlanPricing(repo),
      )..add(LoadLicensePlanPricings()),
      child: const _LicensePlanPricingsView(),
    );
  }
}

class _LicensePlanPricingsView extends StatelessWidget {
  const _LicensePlanPricingsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LicensePlanPricingBloc, LicensePlanPricingState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Plan Pricing'),
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
                    .read<LicensePlanPricingBloc>()
                    .add(RefreshLicensePlanPricings()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Pricing'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async => context
                .read<LicensePlanPricingBloc>()
                .add(RefreshLicensePlanPricings()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LicensePlanPricingState state) {
    if (state.loading && state.items.isEmpty) return const PmLoadingView();
    if (state.error != null && state.items.isEmpty) {
      return PmErrorView(
        message: state.error!,
        onRetry: () => context
            .read<LicensePlanPricingBloc>()
            .add(LoadLicensePlanPricings()),
      );
    }
    if (state.items.isEmpty) {
      return const PmEmptyView(
        icon: Icons.sell_rounded,
        title: 'No pricing rows yet',
        subtitle: 'Tap + to create the first pricing row.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        return LicensePlanPricingCard(
          pricing: item,
          isToggling: state.togglingIds.contains(item.id),
          onToggle: (val) => context.read<LicensePlanPricingBloc>().add(
                ToggleLicensePlanPricingActive(id: item.id, isActive: val),
              ),
          onEdit: () => _openForm(context, item),
        );
      },
    );
  }

  Future<void> _openForm(
      BuildContext context, LicensePlanPricing? existing) async {
    final bloc = context.read<LicensePlanPricingBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LicensePlanPricingFormScreen(existing: existing),
      ),
    );
    if (result == true && context.mounted) {
      bloc.add(RefreshLicensePlanPricings());
    }
  }
}
