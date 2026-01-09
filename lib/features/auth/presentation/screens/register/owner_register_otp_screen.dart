import 'package:build4all_manager/features/auth/presentation/bloc/register/OwnerRegisterBloc.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_event.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/register/owner_register_state.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; // ✅ common toast
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../widgets/otp_code_field.dart';

class OwnerRegisterOtpScreen extends StatefulWidget {
  final String email;
  final String password;

  const OwnerRegisterOtpScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OwnerRegisterOtpScreen> createState() => _OwnerRegisterOtpScreenState();
}

class _OwnerRegisterOtpScreenState extends State<OwnerRegisterOtpScreen> {
  String _code = '';

  void _verify(AppLocalizations l10n) {
    if (_code.length != 6) {
      AppToast.info(context, l10n.errCodeSixDigits);
      return;
    }

    FocusScope.of(context).unfocus();

    context
        .read<OwnerRegisterBloc>()
        .add(OwnerVerifyOtp(widget.email, widget.password, _code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OwnerRegisterBloc, OwnerRegisterState>(
      listenWhen: (p, c) =>
          p.error != c.error || p.registrationToken != c.registrationToken,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }

        if (state.registrationToken != null &&
            state.registrationToken!.isNotEmpty) {
          AppToast.success(context, l10n.msgVerified); // if you have it
          context.push('/owner/register/profile',
              extra: state.registrationToken);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.verifyCode)),
          body: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.msgEnterCodeForEmail(widget.email),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OtpCodeField(onCompleted: (c) => _code = c),
                    const SizedBox(height: 20),
                    AppButton(
                      label: l10n.btnVerify,
                      isBusy: state.loading,
                      expand: true,
                      trailing: const Icon(Icons.verified_rounded),
                      onPressed: state.loading ? null : () => _verify(l10n),
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
