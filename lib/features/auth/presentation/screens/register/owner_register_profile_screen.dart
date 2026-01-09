import 'package:build4all_manager/features/auth/presentation/bloc/register/OwnerRegisterBloc.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_event.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_state.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; // ✅ common toast
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_button.dart';

class OwnerRegisterProfileScreen extends StatefulWidget {
  final String registrationToken;
  const OwnerRegisterProfileScreen({
    super.key,
    required this.registrationToken,
  });

  @override
  State<OwnerRegisterProfileScreen> createState() =>
      _OwnerRegisterProfileScreenState();
}

class _OwnerRegisterProfileScreenState
    extends State<OwnerRegisterProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  void _submit(AppLocalizations l10n) {
    final form = _form.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<OwnerRegisterBloc>().add(
          OwnerCompleteProfile(
            widget.registrationToken,
            _username.text.trim(),
            _first.text.trim(),
            _last.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OwnerRegisterBloc, OwnerRegisterState>(
      listenWhen: (p, c) => p.error != c.error || p.completed != c.completed,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }

        if (state.completed) {
          AppToast.success(context, l10n.msgOwnerRegistered);
          context.go('/home'); // adjust if needed
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.completeProfile)),
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
                        controller: _username,
                        label: l10n.lblUsername,
                        hint: l10n.hintUsername,
                        prefix: const Icon(Icons.alternate_email),
                        validator: (v) => _required(v, l10n.errUsernameRequired),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _first,
                        label: l10n.lblFirstName,
                        hint: l10n.hintFirstName,
                        prefix: const Icon(Icons.person_outline),
                        validator: (v) => _required(v, l10n.errFirstNameRequired),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _last,
                        label: l10n.lblLastName,
                        hint: l10n.hintLastName,
                        prefix: const Icon(Icons.person_outline),
                        validator: (v) => _required(v, l10n.errLastNameRequired),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: l10n.btnCreateAccount,
                        isBusy: state.loading,
                        expand: true,
                        trailing: const Icon(Icons.check_circle_rounded),
                        onPressed: state.loading ? null : () => _submit(l10n),
                      ),
                    ],
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
