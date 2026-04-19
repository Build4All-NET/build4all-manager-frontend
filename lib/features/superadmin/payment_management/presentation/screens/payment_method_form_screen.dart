import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/payment_method_repository_impl.dart';
import '../../data/repositories/payment_type_repository_impl.dart';
import '../../data/services/payment_method_api.dart';
import '../../data/services/payment_type_api.dart';
import '../../domain/entities/managed_payment_type.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_config.dart';
import '../../domain/entities/payment_type.dart';
import '../../domain/usecases/create_payment_method.dart';
import '../../domain/usecases/get_payment_methods.dart';
import '../../domain/usecases/get_payment_types.dart';
import '../../domain/usecases/toggle_payment_method.dart';
import '../../domain/usecases/update_payment_method.dart';
import '../bloc/payment_method_bloc.dart';
import '../bloc/payment_method_event.dart';
import '../bloc/payment_method_state.dart';

class PaymentMethodFormScreen extends StatelessWidget {
  final PaymentMethod? existing;
  const PaymentMethodFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    final methodRepo =
        PaymentMethodRepositoryImpl(PaymentMethodApi(DioClient.ensure()));
    return BlocProvider(
      create: (_) => PaymentMethodBloc(
        getPaymentMethods: GetPaymentMethods(methodRepo),
        createPaymentMethod: CreatePaymentMethod(methodRepo),
        updatePaymentMethod: UpdatePaymentMethod(methodRepo),
        togglePaymentMethod: TogglePaymentMethod(methodRepo),
      ),
      child: _FormView(existing: existing),
    );
  }
}

class _FormView extends StatefulWidget {
  final PaymentMethod? existing;
  const _FormView({this.existing});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _providerCtrl;
  late final TextEditingController _descriptionCtrl;
  late PaymentType _selectedType;
  String _selectedTypeCode = '';
  late bool _isEnabled;

  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _paypalClientIdCtrl;
  late final TextEditingController _paypalSecretCtrl;
  bool _paypalSandbox = false;
  late final TextEditingController _stripePublishableKeyCtrl;
  late final TextEditingController _stripeSecretKeyCtrl;
  late final TextEditingController _visaMerchantIdCtrl;
  late final TextEditingController _visaTerminalIdCtrl;
  final List<_KVEntry> _customFields = [];

  List<ManagedPaymentType> _availableTypes = [];
  bool _loadingTypes = true;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _displayNameCtrl = TextEditingController(text: e?.paymentDisplayName ?? '');
    _providerCtrl = TextEditingController(text: e?.providerCode ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _selectedType = e?.paymentType ?? PaymentType.cash;
    _selectedTypeCode = _selectedType.code;
    _isEnabled = e?.isEnabled ?? true;
    _instructionsCtrl = TextEditingController();
    _paypalClientIdCtrl = TextEditingController();
    _paypalSecretCtrl = TextEditingController();
    _stripePublishableKeyCtrl = TextEditingController();
    _stripeSecretKeyCtrl = TextEditingController();
    _visaMerchantIdCtrl = TextEditingController();
    _visaTerminalIdCtrl = TextEditingController();
    _populateConfig(e?.config);
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final repo =
          PaymentTypeRepositoryImpl(PaymentTypeApi(DioClient.ensure()));
      final types = await GetPaymentTypes(repo)();
      if (mounted) {
        setState(() {
          _availableTypes = types.where((t) => t.isActive).toList();
          _loadingTypes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  void _populateConfig(PaymentMethodConfig? config) {
    if (config == null) return;
    switch (config) {
      case CashConfig c:
        _instructionsCtrl.text = c.instructions;
      case PayPalConfig c:
        _paypalClientIdCtrl.text = c.clientId;
        _paypalSecretCtrl.text = c.secret;
        _paypalSandbox = c.sandbox;
      case StripeConfig c:
        _stripePublishableKeyCtrl.text = c.publishableKey;
        _stripeSecretKeyCtrl.text = c.secretKey;
      case VisaConfig c:
        _visaMerchantIdCtrl.text = c.merchantId;
        _visaTerminalIdCtrl.text = c.terminalId;
      case CustomConfig c:
        for (final entry in c.fields.entries) {
          _customFields.add(_KVEntry(
            keyCtrl: TextEditingController(text: entry.key),
            valueCtrl: TextEditingController(text: entry.value),
          ));
        }
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _providerCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _paypalClientIdCtrl.dispose();
    _paypalSecretCtrl.dispose();
    _stripePublishableKeyCtrl.dispose();
    _stripeSecretKeyCtrl.dispose();
    _visaMerchantIdCtrl.dispose();
    _visaTerminalIdCtrl.dispose();
    for (final f in _customFields) {
      f.keyCtrl.dispose();
      f.valueCtrl.dispose();
    }
    super.dispose();
  }

  PaymentMethodConfig _buildConfig() => switch (_selectedType) {
        PaymentType.cash =>
          CashConfig(instructions: _instructionsCtrl.text.trim()),
        PaymentType.paypal => PayPalConfig(
            clientId: _paypalClientIdCtrl.text.trim(),
            secret: _paypalSecretCtrl.text.trim(),
            sandbox: _paypalSandbox,
          ),
        PaymentType.stripe => StripeConfig(
            publishableKey: _stripePublishableKeyCtrl.text.trim(),
            secretKey: _stripeSecretKeyCtrl.text.trim(),
          ),
        PaymentType.visa => VisaConfig(
            merchantId: _visaMerchantIdCtrl.text.trim(),
            terminalId: _visaTerminalIdCtrl.text.trim(),
          ),
        _ => CustomConfig(
            fields: {
              for (final f in _customFields)
                if (f.keyCtrl.text.trim().isNotEmpty)
                  f.keyCtrl.text.trim(): f.valueCtrl.text.trim(),
            },
          ),
      };

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final method = PaymentMethod(
      id: widget.existing?.id ?? 0,
      paymentDisplayName: _displayNameCtrl.text.trim(),
      paymentType: _selectedType,
      providerCode: _providerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      isEnabled: _isEnabled,
      config: _buildConfig(),
      createdAt: widget.existing?.createdAt,
    );
    if (_isEditMode) {
      context.read<PaymentMethodBloc>().add(EditPaymentMethod(method));
    } else {
      context.read<PaymentMethodBloc>().add(AddPaymentMethod(method));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<PaymentMethodBloc, PaymentMethodState>(
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
            title:
                Text(_isEditMode ? 'Edit Payment Method' : 'Add Payment Method'),
            centerTitle: false,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SectionHeader(label: 'Basic Information'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _displayNameCtrl,
                  label: 'Display Name',
                  hint: 'e.g. Credit Card, Cash on Delivery',
                  prefix: const Icon(Icons.label_outline),
                  enabled: !busy,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.err_required
                      : null,
                ),
                const SizedBox(height: 12),
                _TypeDropdown(
                  selectedCode: _selectedTypeCode,
                  availableTypes: _availableTypes,
                  loadingTypes: _loadingTypes,
                  isEditMode: _isEditMode,
                  busy: busy,
                  onChanged: (code) {
                    if (code != null) {
                      setState(() {
                        _selectedTypeCode = code;
                        _selectedType = PaymentType.fromCode(code);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _providerCtrl,
                  label: 'Provider Code',
                  hint: 'e.g. STRIPE, PAYPAL, INTERNAL',
                  prefix: const Icon(Icons.business_outlined),
                  enabled: !busy,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.err_required
                      : null,
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
                    title: const Text('Enabled'),
                    subtitle: Text(_isEnabled ? 'This method is active' : 'This method is disabled'),
                    secondary: Icon(
                      _isEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: _isEnabled,
                    onChanged: busy ? null : (v) => setState(() => _isEnabled = v),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(label: 'Configuration'),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedType),
                    child: _buildConfigSection(l10n, busy),
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
                        label: _isEditMode ? 'Save Changes' : 'Add Method',
                        type: AppButtonType.primary,
                        isBusy: busy,
                        onPressed: busy ? null : _submit,
                        trailing: Icon(_isEditMode ? Icons.save_rounded : Icons.add_rounded),
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

  Widget _buildConfigSection(AppLocalizations l10n, bool busy) =>
      switch (_selectedType) {
        PaymentType.cash => _CashFields(ctrl: _instructionsCtrl, busy: busy),
        PaymentType.paypal => _PayPalFields(
            clientIdCtrl: _paypalClientIdCtrl,
            secretCtrl: _paypalSecretCtrl,
            sandbox: _paypalSandbox,
            onSandboxChanged: (v) => setState(() => _paypalSandbox = v),
            busy: busy,
            l10n: l10n,
          ),
        PaymentType.stripe => _StripeFields(
            publishableCtrl: _stripePublishableKeyCtrl,
            secretCtrl: _stripeSecretKeyCtrl,
            busy: busy,
            l10n: l10n,
          ),
        PaymentType.visa => _VisaFields(
            merchantCtrl: _visaMerchantIdCtrl,
            terminalCtrl: _visaTerminalIdCtrl,
            busy: busy,
            l10n: l10n,
          ),
        _ => _CustomFields(
            fields: _customFields,
            busy: busy,
            onAdd: () => setState(() => _customFields.add(_KVEntry(
                  keyCtrl: TextEditingController(),
                  valueCtrl: TextEditingController(),
                ))),
            onRemove: (i) => setState(() {
              _customFields[i].keyCtrl.dispose();
              _customFields[i].valueCtrl.dispose();
              _customFields.removeAt(i);
            }),
            l10n: l10n,
          ),
      };
}

class _TypeDropdown extends StatelessWidget {
  final String selectedCode;
  final List<ManagedPaymentType> availableTypes;
  final bool loadingTypes;
  final bool isEditMode;
  final bool busy;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({
    required this.selectedCode,
    required this.availableTypes,
    required this.loadingTypes,
    required this.isEditMode,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingTypes) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Payment Type', prefixIcon: Icon(Icons.category_outlined)),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final items = availableTypes.isNotEmpty
        ? availableTypes.map((t) => DropdownMenuItem(value: t.code, child: Text(t.typeName))).toList()
        : PaymentType.values.map((t) => DropdownMenuItem(value: t.code, child: Text(t.displayName))).toList();

    final effectiveValue = availableTypes.isNotEmpty
        ? (availableTypes.any((t) => t.code == selectedCode)
            ? selectedCode
            : availableTypes.first.code)
        : selectedCode;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: 'Payment Type',
        prefixIcon: const Icon(Icons.category_outlined),
        helperText: isEditMode ? 'Type cannot be changed after creation' : null,
      ),
      items: items,
      onChanged: (busy || isEditMode) ? null : onChanged,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _CashFields extends StatelessWidget {
  final TextEditingController ctrl;
  final bool busy;
  const _CashFields({required this.ctrl, required this.busy});
  @override
  Widget build(BuildContext context) => AppTextField(
        controller: ctrl,
        label: 'Payment Instructions',
        hint: 'Instructions shown to the customer',
        prefix: const Icon(Icons.info_outline_rounded),
        enabled: !busy,
        maxLines: 5,
        minLines: 3,
      );
}

class _PayPalFields extends StatelessWidget {
  final TextEditingController clientIdCtrl;
  final TextEditingController secretCtrl;
  final bool sandbox;
  final ValueChanged<bool> onSandboxChanged;
  final bool busy;
  final AppLocalizations l10n;
  const _PayPalFields({
    required this.clientIdCtrl,
    required this.secretCtrl,
    required this.sandbox,
    required this.onSandboxChanged,
    required this.busy,
    required this.l10n,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(controller: clientIdCtrl, label: 'Client ID', hint: 'PayPal Client ID', prefix: const Icon(Icons.badge_outlined), enabled: !busy, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null),
          const SizedBox(height: 12),
          AppPasswordField(controller: secretCtrl, label: 'Secret', prefix: const Icon(Icons.key_outlined), validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null, enabled: !busy),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Sandbox Mode'),
              subtitle: const Text('Use PayPal sandbox for testing'),
              value: sandbox,
              onChanged: busy ? null : onSandboxChanged,
            ),
          ),
        ],
      );
}

class _StripeFields extends StatelessWidget {
  final TextEditingController publishableCtrl;
  final TextEditingController secretCtrl;
  final bool busy;
  final AppLocalizations l10n;
  const _StripeFields({
    required this.publishableCtrl,
    required this.secretCtrl,
    required this.busy,
    required this.l10n,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(controller: publishableCtrl, label: 'Publishable Key', hint: 'pk_live_...', prefix: const Icon(Icons.vpn_key_outlined), enabled: !busy, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null),
          const SizedBox(height: 12),
          AppPasswordField(controller: secretCtrl, label: 'Secret Key', prefix: const Icon(Icons.key_outlined), validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null, enabled: !busy),
        ],
      );
}

class _VisaFields extends StatelessWidget {
  final TextEditingController merchantCtrl;
  final TextEditingController terminalCtrl;
  final bool busy;
  final AppLocalizations l10n;
  const _VisaFields({
    required this.merchantCtrl,
    required this.terminalCtrl,
    required this.busy,
    required this.l10n,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(controller: merchantCtrl, label: 'Merchant ID', hint: 'Your VISA Merchant ID', prefix: const Icon(Icons.store_outlined), enabled: !busy, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null),
          const SizedBox(height: 12),
          AppTextField(controller: terminalCtrl, label: 'Terminal ID', hint: 'Your VISA Terminal ID', prefix: const Icon(Icons.terminal_rounded), enabled: !busy, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null),
        ],
      );
}

class _CustomFields extends StatelessWidget {
  final List<_KVEntry> fields;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final AppLocalizations l10n;
  const _CustomFields({
    required this.fields,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
    required this.l10n,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(fields.length, (i) {
            final f = fields[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: AppTextField(controller: f.keyCtrl, label: 'Key', hint: 'field_name', enabled: !busy, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.err_required : null)),
                  const SizedBox(width: 8),
                  Expanded(child: AppTextField(controller: f.valueCtrl, label: 'Value', hint: 'field_value', enabled: !busy)),
                  IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: 'Remove', onPressed: busy ? null : () => onRemove(i)),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          OutlinedButton.icon(onPressed: busy ? null : onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add Field')),
        ],
      );
}

class _KVEntry {
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;
  _KVEntry({required this.keyCtrl, required this.valueCtrl});
}
