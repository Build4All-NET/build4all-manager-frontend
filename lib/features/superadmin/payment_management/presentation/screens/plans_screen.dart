import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/plan_repository_impl.dart';
import '../../data/services/plan_api.dart';
import '../../domain/entities/plan.dart';
import '../../domain/usecases/create_plan.dart';
import '../../domain/usecases/delete_plan.dart';
import '../../domain/usecases/get_plans.dart';
import '../../domain/usecases/update_plan.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';
import '../widgets/plan_card.dart';
import '../widgets/pm_list_widgets.dart';
import 'plan_form_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PlanRepositoryImpl(PlanApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PlanBloc(
        getPlans: GetPlans(repo),
        createPlan: CreatePlan(repo),
        updatePlan: UpdatePlan(repo),
        deletePlan: DeletePlan(repo),
      )..add(LoadPlans()),
      child: const _PlansView(),
    );
  }
}

class _PlansView extends StatelessWidget {
  const _PlansView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanBloc, PlanState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
        if (st.success?.isNotEmpty == true) AppToast.success(ctx, st.success!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Plans'),
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
                    context.read<PlanBloc>().add(RefreshPlans()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Plan'),
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: () async =>
                context.read<PlanBloc>().add(RefreshPlans()),
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PlanState state) {
    if (state.loading && state.items.isEmpty) return const PmLoadingView();
    if (state.error != null && state.items.isEmpty) {
      return PmErrorView(
        message: state.error!,
        onRetry: () => context.read<PlanBloc>().add(LoadPlans()),
      );
    }
    if (state.items.isEmpty) {
      return const PmEmptyView(
        icon: Icons.layers_rounded,
        title: 'No plans yet',
        subtitle: 'Tap + to create your first subscription plan.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = state.items[i];
        return PlanCard(
          plan: item,
          isDeleting: state.deletingCodes.contains(item.code),
          onEdit: () => _openForm(context, item),
          onDelete: () =>
              context.read<PlanBloc>().add(DeletePlanEvent(item.code)),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, Plan? existing) async {
    final bloc = context.read<PlanBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanFormScreen(existing: existing),
      ),
    );
    if (result == true && context.mounted) bloc.add(RefreshPlans());
  }
}
