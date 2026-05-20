import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
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

const _kPlanCodes = ['PRO_HOSTEDB', 'SMART', 'FREE'];

class PlanFormScreen extends StatelessWidget {
  final Plan? existing;
  const PlanFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    final repo = PlanRepositoryImpl(PlanApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PlanBloc(
        getPlans: GetPlans(repo),
        createPlan: CreatePlan(repo),
        updatePlan: UpdatePlan(repo),
        deletePlan: DeletePlan(repo),
      ),
      child: _FormView(existing: existing),
    );
  }
}

class _FormView extends StatefulWidget {
  final Plan? existing;
  const _FormView({this.existing});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usersAllowedCtrl;
  late final TextEditingController _billingCycleCtrl;
  late String? _selectedCode;
  late bool _requiresDedicatedServer;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _displayNameCtrl = TextEditingController(text: e?.displayName ?? '');
    _usersAllowedCtrl = TextEditingController(
      text: e?.usersAllowed?.toString() ?? '',
    );
    _billingCycleCtrl = TextEditingController(
      text: e?.billingCycleMonths.toString() ?? '1',
    );
    _selectedCode = e?.code ?? _kPlanCodes.first;
    _requiresDedicatedServer = e?.requiresDedicatedServer ?? false;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usersAllowedCtrl.dispose();
    _billingCycleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final usersText = _usersAllowedCtrl.text.trim();
    final plan = Plan(
      code: _isEditMode ? widget.existing!.code : (_selectedCode ?? _kPlanCodes.first),
      displayName: _displayNameCtrl.text.trim(),
      usersAllowed: usersText.isEmpty ? null : int.tryParse(usersText),
      billingCycleMonths:
          int.tryParse(_billingCycleCtrl.text.trim()) ?? 1,
      requiresDedicatedServer: _requiresDedicatedServer,
    );
    if (_isEditMode) {
      context.read<PlanBloc>().add(EditPlan(plan));
    } else {
      context.read<PlanBloc>().add(AddPlan(plan));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<PlanBloc, PlanState>(
      listenWhen: (p, c) =>
          p.saving != c.saving || p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (!st.saving && st.success?.isNotEmpty == true) {
          AppToast.success(ctx, st.success!);
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(true);
        }
        if (st.error?.isNotEmpty == true) AppToast.error(ctx, st.error!);
      },
      builder: (context, state) {
        final busy = state.saving;
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditMode ? 'Edit Plan' : 'Add Plan'),
            centerTitle: false,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Code selector (dropdown in create, read-only chip in edit)
                if (!_isEditMode) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCode,
                    decoration: const InputDecoration(
                      labelText: 'Plan Code',
                      prefixIcon: Icon(Icons.code_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: _kPlanCodes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) => setState(() => _selectedCode = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.err_required : null,
                  ),
                ] else ...[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Plan Code',
                      prefixIcon: Icon(Icons.code_rounded),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      widget.existing!.code,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Code cannot be changed after creation',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppTextField(
                  controller: _displayNameCtrl,
                  label: 'Display Name',
                  hint: 'e.g. Basic, Pro, Enterprise',
                  prefix: const Icon(Icons.label_outline),
                  enabled: !busy,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.err_required : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _usersAllowedCtrl,
                  label: 'Users Allowed',
                  hint: 'Leave empty for unlimited',
                  helper: 'Leave empty for unlimited users',
                  prefix: const Icon(Icons.people_alt_outlined),
                  keyboardType: TextInputType.number,
                  enabled: !busy,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be a positive integer';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _billingCycleCtrl,
                  label: 'Billing Cycle (months)',
                  hint: 'e.g. 1, 3, 12',
                  prefix: const Icon(Icons.calendar_month_outlined),
                  keyboardType: TextInputType.number,
                  enabled: !busy,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.err_required;
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be a positive integer';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    title: const Text('Requires Dedicated Server'),
                    subtitle: Text(
                      _requiresDedicatedServer
                          ? 'This plan requires a dedicated server'
                          : 'Shared hosting is sufficient',
                    ),
                    secondary: Icon(
                      Icons.dns_outlined,
                      color: _requiresDedicatedServer
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: _requiresDedicatedServer,
                    onChanged: busy
                        ? null
                        : (v) =>
                            setState(() => _requiresDedicatedServer = v),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        type: AppButtonType.text,
                        onPressed: busy ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _isEditMode ? 'Save Changes' : 'Add Plan',
                        type: AppButtonType.primary,
                        isBusy: busy,
                        onPressed: busy ? null : _submit,
                        trailing: Icon(
                          _isEditMode
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
