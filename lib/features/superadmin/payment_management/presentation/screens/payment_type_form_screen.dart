import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
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

class PaymentTypeFormScreen extends StatelessWidget {
  final ManagedPaymentType? existing;
  const PaymentTypeFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    final repo = PaymentTypeRepositoryImpl(PaymentTypeApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PaymentTypeBloc(
        getPaymentTypes: GetPaymentTypes(repo),
        createPaymentType: CreatePaymentType(repo),
        updatePaymentType: UpdatePaymentType(repo),
        togglePaymentType: TogglePaymentType(repo),
      ),
      child: _FormView(existing: existing),
    );
  }
}

class _FormView extends StatefulWidget {
  final ManagedPaymentType? existing;
  const _FormView({this.existing});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeNameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descriptionCtrl;
  late bool _isActive;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _typeNameCtrl = TextEditingController(text: e?.typeName ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _typeNameCtrl.dispose();
    _codeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final type = ManagedPaymentType(
      id: widget.existing?.id ?? 0,
      typeName: _typeNameCtrl.text.trim(),
      code: _codeCtrl.text.trim().toUpperCase(),
      description: _descriptionCtrl.text.trim(),
      isActive: _isActive,
      createdAt: widget.existing?.createdAt,
    );
    if (_isEditMode) {
      context.read<PaymentTypeBloc>().add(EditPaymentType(type));
    } else {
      context.read<PaymentTypeBloc>().add(AddPaymentType(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<PaymentTypeBloc, PaymentTypeState>(
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
            title: Text(_isEditMode ? 'Edit Payment Type' : 'Add Payment Type'),
            centerTitle: false,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                AppTextField(
                  controller: _typeNameCtrl,
                  label: 'Type Name',
                  hint: 'e.g. Credit Card, Mobile Wallet',
                  prefix: const Icon(Icons.label_outline),
                  enabled: !busy,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.err_required
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _codeCtrl,
                  label: 'Code',
                  hint: 'e.g. CREDIT_CARD, MOBILE_WALLET',
                  prefix: const Icon(Icons.code_rounded),
                  enabled: !busy && !_isEditMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.err_required;
                    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Code cannot be changed after creation',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _descriptionCtrl,
                  label: 'Description',
                  hint: 'Optional description',
                  prefix: const Icon(Icons.description_outlined),
                  enabled: !busy,
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text('Active'),
                    subtitle: Text(_isActive ? 'Available for selection' : 'Hidden from selection'),
                    secondary: Icon(
                      _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: _isActive,
                    onChanged: busy ? null : (v) => setState(() => _isActive = v),
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
                        label: _isEditMode ? 'Save Changes' : 'Add Type',
                        type: AppButtonType.primary,
                        isBusy: busy,
                        onPressed: busy ? null : _submit,
                        trailing: Icon(
                          _isEditMode ? Icons.save_rounded : Icons.add_rounded,
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
