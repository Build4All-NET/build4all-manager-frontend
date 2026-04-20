import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/license_plan_pricing_repository_impl.dart';
import '../../data/services/license_plan_pricing_api.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/license_plan_pricing.dart';
import '../../domain/entities/pricing_currency.dart';
import '../../domain/usecases/create_license_plan_pricing.dart';
import '../../domain/usecases/get_license_plan_pricings.dart';
import '../../domain/usecases/get_pricing_currencies.dart';
import '../../domain/usecases/toggle_license_plan_pricing.dart';
import '../../domain/usecases/update_license_plan_pricing.dart';
import '../bloc/license_plan_pricing_bloc.dart';
import '../bloc/license_plan_pricing_event.dart';
import '../bloc/license_plan_pricing_state.dart';

class LicensePlanPricingFormScreen extends StatelessWidget {
  final LicensePlanPricing? existing;
  const LicensePlanPricingFormScreen({super.key, this.existing});

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
      ),
      child: _FormView(existing: existing),
    );
  }
}

class _FormView extends StatefulWidget {
  final LicensePlanPricing? existing;
  const _FormView({this.existing});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _discountedPriceCtrl = TextEditingController();
  final _discountPercentCtrl = TextEditingController();
  final _discountLabelCtrl = TextEditingController();

  String _selectedPlanCode = 'PRO_HOSTEDB';
  PricingBillingCycle _selectedCycle = PricingBillingCycle.monthly;
  bool _isActive = true;
  String _selectedCurrencyCode = 'USD';

  List<PricingCurrency> _currencies = const [];
  bool _loadingCurrencies = true;
  String? _currenciesError;

  bool get _isEditMode => widget.existing != null;

  static const _availablePlanCodes = ['PRO_HOSTEDB', 'DEDICATED'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedPlanCode = e.planCode;
      _selectedCycle = e.billingCycle;
      _isActive = e.isActive;
      _selectedCurrencyCode = e.currency;
      _priceCtrl.text = _fmtNumber(e.price);
      if (e.discountedPrice != null) {
        _discountedPriceCtrl.text = _fmtNumber(e.discountedPrice!);
      }
      if (e.discountPercent != null) {
        _discountPercentCtrl.text = e.discountPercent.toString();
      }
      if (e.discountLabel != null) {
        _discountLabelCtrl.text = e.discountLabel!;
      }
    }
    _loadCurrencies();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _discountPercentCtrl.dispose();
    _discountLabelCtrl.dispose();
    super.dispose();
  }

  String _fmtNumber(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  Future<void> _loadCurrencies() async {
    final api = LicensePlanPricingApi(DioClient.ensure());
    final repo = LicensePlanPricingRepositoryImpl(api);
    try {
      final list = await GetPricingCurrencies(repo).call();
      if (!mounted) return;
      setState(() {
        _currencies = list;
        _loadingCurrencies = false;
        // If the existing currency code isn't in the list, default to first.
        if (list.isNotEmpty &&
            !list.any((c) =>
                c.code.toUpperCase() == _selectedCurrencyCode.toUpperCase())) {
          _selectedCurrencyCode = list.first.code;
        }
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loadingCurrencies = false;
        _currenciesError = ApiErrorHandler.message(err);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) return;

    final discountedPrice = _discountedPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_discountedPriceCtrl.text.trim());
    final discountPercent = _discountPercentCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_discountPercentCtrl.text.trim());
    final discountLabel = _discountLabelCtrl.text.trim().isEmpty
        ? null
        : _discountLabelCtrl.text.trim();

    final pricing = LicensePlanPricing(
      id: widget.existing?.id ?? 0,
      planCode: _selectedPlanCode,
      billingCycle: _selectedCycle,
      price: price,
      discountedPrice: discountedPrice,
      currency: _selectedCurrencyCode,
      discountPercent: discountPercent,
      discountLabel: discountLabel,
      isActive: _isActive,
      createdAt: widget.existing?.createdAt,
    );

    final bloc = context.read<LicensePlanPricingBloc>();
    if (_isEditMode) {
      bloc.add(EditLicensePlanPricing(pricing));
    } else {
      bloc.add(AddLicensePlanPricing(pricing));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LicensePlanPricingBloc, LicensePlanPricingState>(
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
            title: Text(_isEditMode ? 'Edit Pricing' : 'Add Pricing'),
            centerTitle: false,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'Plan & billing cycle',
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPlanCode,
                  items: _availablePlanCodes
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (_isEditMode || busy)
                      ? null
                      : (v) => setState(
                          () => _selectedPlanCode = v ?? _selectedPlanCode),
                  decoration: const InputDecoration(
                    labelText: 'Plan code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PricingBillingCycle>(
                  value: _selectedCycle,
                  items: PricingBillingCycle.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (_isEditMode || busy)
                      ? null
                      : (v) =>
                          setState(() => _selectedCycle = v ?? _selectedCycle),
                  decoration: const InputDecoration(
                    labelText: 'Billing cycle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  icon: Icons.attach_money_rounded,
                  title: 'Price',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Regular price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sell_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Invalid number';
                    if (n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildCurrencyDropdown(busy),
                const SizedBox(height: 20),
                _SectionHeader(
                  icon: Icons.local_offer_rounded,
                  title: 'Discount (optional)',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _discountedPriceCtrl,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Discounted price',
                    helperText: 'Leave empty to disable the discount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.discount_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Invalid number';
                    if (n < 0) return 'Must be ≥ 0';
                    final regular = double.tryParse(_priceCtrl.text.trim());
                    if (regular != null && n >= regular) {
                      return 'Must be lower than the regular price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountPercentCtrl,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Discount percent',
                    helperText: 'Display only (e.g. 17)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountLabelCtrl,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Discount label',
                    helperText: 'e.g. "Save 17%"',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('Active'),
                  subtitle: const Text(
                      'When active, this row replaces the previous active pricing for the same plan and cycle.'),
                  onChanged:
                      busy ? null : (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: (busy || _loadingCurrencies) ? null : _submit,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isEditMode ? 'Save changes' : 'Create pricing'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyDropdown(bool busy) {
    if (_loadingCurrencies) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Loading currencies…'),
          ],
        ),
      );
    }
    if (_currenciesError != null && _currencies.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Currency',
          errorText: _currenciesError,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCurrencyCode,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loadingCurrencies = true;
                  _currenciesError = null;
                });
                _loadCurrencies();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCurrencyCode,
      items: _currencies
          .map((c) => DropdownMenuItem(
                value: c.code,
                child: Text(c.displayLabel),
              ))
          .toList(),
      onChanged: busy
          ? null
          : (v) => setState(
              () => _selectedCurrencyCode = v ?? _selectedCurrencyCode),
      decoration: const InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
