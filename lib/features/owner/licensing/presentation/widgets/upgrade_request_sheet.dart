import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';

import '../../data/models/upgrade_plan_option_model.dart';
import '../../data/services/owner_licensing_api.dart';

/// Shows the upgrade-request bottom sheet.
/// Returns true if the request was submitted successfully.
Future<bool?> showUpgradeRequestSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _UpgradeRequestSheet(),
  );
}

class _UpgradeRequestSheet extends StatefulWidget {
  const _UpgradeRequestSheet();

  @override
  State<_UpgradeRequestSheet> createState() => _UpgradeRequestSheetState();
}

class _UpgradeRequestSheetState extends State<_UpgradeRequestSheet> {
  final _api = OwnerLicensingApi(DioClient.ensure());

  List<UpgradePlanOptionModel> _plans = const [];
  bool _loadingPlans = true;
  String? _plansError;

  String? _selectedPlanCode;
  String _billingCycle = 'MONTHLY';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loadingPlans = true;
      _plansError = null;
    });
    try {
      final plans = await _api.getUpgradePlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loadingPlans = false;
        if (_selectedPlanCode == null && plans.isNotEmpty) {
          _selectedPlanCode = plans.first.code;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlans = false;
        _plansError = ApiErrorHandler.message(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPlanCode == null) return;
    setState(() => _submitting = true);
    try {
      await _api.sendUpgradeRequest(
        planCode: _selectedPlanCode!,
        billingCycle: _billingCycle,
      );
      if (!mounted) return;
      AppToast.success(context, 'Upgrade request sent successfully');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ApiErrorHandler.message(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmtPrice(double? price, String? currency) {
    if (price == null) return '—';
    final c = currency ?? 'USD';
    final formatted = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '$formatted $c';
  }

  String _planPrice(UpgradePlanOptionModel plan) {
    final p = plan.pricing;
    if (p == null) return '—';
    if (_billingCycle == 'YEARLY') {
      return _fmtPrice(p.effectiveYearlyPrice, p.currency);
    }
    return _fmtPrice(p.monthlyPrice, p.currency);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bool canSubmit =
        !_loadingPlans && !_submitting && _selectedPlanCode != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.upgrade_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade request',
                              style: tt.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Choose a plan to send a request.',
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Plans section
                  if (_loadingPlans)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_plansError != null)
                    _ErrorRetry(message: _plansError!, onRetry: _loadPlans)
                  else if (_plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No upgrade plans available.',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    ..._plans.map((plan) => _PlanTile(
                          plan: plan,
                          price: _planPrice(plan),
                          selected: _selectedPlanCode == plan.code,
                          onTap: plan.available
                              ? () => setState(
                                  () => _selectedPlanCode = plan.code)
                              : null,
                        )),

                  const SizedBox(height: 20),

                  // Billing cycle toggle
                  Text(
                    'BILLING CYCLE',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BillingCycleToggle(
                    selected: _billingCycle,
                    onChanged: (v) => setState(() => _billingCycle = v),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Send request'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan tile ─────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final UpgradePlanOptionModel plan;
  final String price;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanTile({
    required this.plan,
    required this.price,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final available = plan.available;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant.withOpacity(.6),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? cs.primaryContainer.withOpacity(.18)
                : cs.surfaceContainerHighest.withOpacity(.3),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: plan.code,
                groupValue: selected ? plan.code : null,
                onChanged: onTap != null ? (_) => onTap!() : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: available
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(.4),
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Text(
                        plan.description!,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (!available && plan.unavailableReason != null)
                      Text(
                        plan.unavailableReason!,
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                  ],
                ),
              ),
              Text(
                price,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: available
                      ? cs.onSurface
                      : cs.onSurface.withOpacity(.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Billing cycle toggle ──────────────────────────────────────────────────────

class _BillingCycleToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _BillingCycleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Monthly',
            active: selected == 'MONTHLY',
            onTap: () => onChanged('MONTHLY'),
            cs: cs,
            tt: tt,
          ),
          _Tab(
            label: 'Yearly',
            active: selected == 'YEARLY',
            onTap: () => onChanged('YEARLY'),
            cs: cs,
            tt: tt,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: active ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error + retry ─────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
