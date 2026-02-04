import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
import '../../presentation/bloc/profile_bloc.dart';
import '../../presentation/bloc/profile_state.dart';


class ChangePasswordSheet extends StatefulWidget {
  final bool busy; // from parent state
  final Future<void> Function(String current, String next) onSubmit;

  const ChangePasswordSheet({
    super.key,
    required this.busy,
    required this.onSubmit,
  });

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtl = TextEditingController();
  final _nextCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtl.dispose();
    _nextCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) async {
    if (_formKey.currentState?.validate() != true) return;
    // Dispatch event via onSubmit; DO NOT close here.
    await widget.onSubmit(_currentCtl.text.trim(), _nextCtl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (p, c) =>
          p.savingPassword != c.savingPassword ||
          p.error != c.error ||
          p.success != c.success,
      listener: (ctx, st) {
        // Show any backend error as toast (keeps sheet open)
        if (st.error?.isNotEmpty == true) {
          
        }
        // Close only on success
        if (!st.savingPassword && st.success?.isNotEmpty == true) {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(true);
        }
      },
      builder: (context, state) {
        final disabled = state.savingPassword;

        return SafeArea(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: kElevationToShadow[3],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Text(l10n.profile_change_password,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    // Current
                    AppTextField(
                      label: l10n.profile_current_password,
                      controller: _currentCtl,
                      obscure: !_showCurrent,
                      prefix: const Icon(Icons.lock_clock_outlined),
                      suffix: IconButton(
                        icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: disabled
                            ? null
                            : () =>
                                setState(() => _showCurrent = !_showCurrent),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l10n.err_required : null,
                      enabled: !disabled,
                    ),
                    const SizedBox(height: 12),

                    // New
                    AppTextField(
                      label: l10n.profile_new_password,
                      controller: _nextCtl,
                      obscure: !_showNext,
                      prefix: const Icon(Icons.lock_outline),
                      suffix: IconButton(
                        icon: Icon(
                          _showNext
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: disabled
                            ? null
                            : () => setState(() => _showNext = !_showNext),
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return l10n.err_required;
                        if (t.length < 6) return l10n.errPasswordRequired;
                        return null;
                      },
                      enabled: !disabled,
                    ),
                    const SizedBox(height: 12),

                    // Confirm
                    AppTextField(
                      label: l10n.profile_confirm_password,
                      controller: _confirmCtl,
                      obscure: !_showConfirm,
                      prefix: const Icon(Icons.lock_outline),
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: disabled
                            ? null
                            : () =>
                                setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return l10n.err_required;
                        if (v != _nextCtl.text) {
                          return l10n.errPasswordMismatch;
                        }
                        return null;
                      },
                      enabled: !disabled,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: l10n.common_cancel,
                            type: AppButtonType.text,
                            onPressed: disabled
                                ? null
                                : () => Navigator.pop(context, false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: l10n.common_save,
                            type: AppButtonType.primary,
                            isBusy: disabled,
                            onPressed: disabled ? null : () => _submit(l10n),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
