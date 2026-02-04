import 'package:build4all_manager/features/auth/presentation/bloc/register/OwnerRegisterBloc.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_event.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_state.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_button.dart';

class OwnerRegisterEmailScreen extends StatefulWidget {
  const OwnerRegisterEmailScreen({super.key});

  @override
  State<OwnerRegisterEmailScreen> createState() =>
      _OwnerRegisterEmailScreenState();
}

class _OwnerRegisterEmailScreenState extends State<OwnerRegisterEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailNode = FocusNode();
  final _pwNode = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailNode
      ..unfocus()
      ..dispose();
    _pwNode
      ..unfocus()
      ..dispose();
    super.dispose();
  }

  // ✅ Back should return to Login
  void _goBackToLogin() {
    // pop if possible (normal navigation)
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    // fallback for deep links / direct open
    context.go('/owner/login');
  }

  String? _emailValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.errEmailRequired;
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    if (!ok) return l10n.errEmailInvalid;
    return null;
  }

  String? _passwordValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.errPasswordRequired;
    if (v.length < 6) return l10n.errPasswordMin;
    return null;
  }

  void _submit(AppLocalizations l10n) {
    final form = _form.currentState;
    if (form == null) return;

    if (!form.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<OwnerRegisterBloc>().add(
          OwnerSendOtp(_email.text.trim(), _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OwnerRegisterBloc, OwnerRegisterState>(
      // ✅ only react when:
      // - error changes
      // - loading changes (especially true -> false after submit)
      listenWhen: (p, c) => p.error != c.error || p.loading != c.loading,
      listener: (context, state) {
        // ✅ show error toast
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }
      },

      // ✅ use buildWhen for UI refresh only when needed
      buildWhen: (p, c) => p.loading != c.loading || p.error != c.error,
      builder: (context, state) {
        return BlocListener<OwnerRegisterBloc, OwnerRegisterState>(
          // ✅ navigate ONLY after request finishes:
          // loading: true -> false AND no error
          listenWhen: (p, c) => p.loading == true && c.loading == false,
          listener: (context, st) {
            if (st.error != null && st.error!.isNotEmpty) return;

            AppToast.success(context, l10n.msgCodeSent);

            context.push('/owner/register/otp', extra: {
              'email': _email.text.trim(),
              'password': _password.text,
            });
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.signUpOwnerTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _goBackToLogin,
                tooltip: l10n.common_back,
              ),
            ),
            body: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextField(
                          controller: _email,
                          focusNode: _emailNode,
                          label: l10n.lblEmail,
                          hint: l10n.hintEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefix: const Icon(Icons.mail_outline),
                          validator: (v) => _emailValidator(v, l10n),
                          onSubmitted: (_) => _pwNode.requestFocus(),
                        ),
                        const SizedBox(height: 14),
                        AppPasswordField(
                          controller: _password,
                          focusNode: _pwNode,
                          label: l10n.lblPassword,
                          hint: l10n.hintPassword,
                          prefix: const Icon(Icons.lock_outline),
                          textInputAction: TextInputAction.done,
                          validator: (v) => _passwordValidator(v, l10n),
                          onSubmitted: (_) => _submit(l10n),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: l10n.btnSendCode,
                          expand: true,
                          isBusy: state.loading,
                          trailing: const Icon(Icons.send_rounded),
                          onPressed: state.loading ? null : () => _submit(l10n),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.msgWeWillSendCodeEmail,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
