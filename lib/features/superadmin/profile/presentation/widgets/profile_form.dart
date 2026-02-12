import 'package:flutter/material.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import '../../domain/entities/admin_profile.dart';

class ProfileForm extends StatefulWidget {
  final AdminProfile me;
  final void Function(AdminProfile) onSubmit;
  final bool busy;

  const ProfileForm({
    super.key,
    required this.me,
    required this.onSubmit,
    this.busy = false,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first =
      TextEditingController(text: widget.me.firstName);
  late final TextEditingController _last =
      TextEditingController(text: widget.me.lastName);
  late final TextEditingController _user =
      TextEditingController(text: widget.me.username);
  late final TextEditingController _email =
      TextEditingController(text: widget.me.email);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _user.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = widget.busy;

    return Form(
      key: _form,
      child: Column(
        children: [
          AppTextField(
            label: l10n.profile_first_name,
            hint: l10n.profile_first_name_hint,
            prefix: const Icon(Icons.badge_outlined),
            controller: _first,
            enabled: !disabled,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.err_required : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l10n.profile_last_name,
            hint: l10n.profile_last_name_hint,
            prefix: const Icon(Icons.badge_rounded),
            controller: _last,
            enabled: !disabled,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.err_required : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l10n.profile_username,
            hint: l10n.profile_username_hint,
            prefix: const Icon(Icons.alternate_email),
            controller: _user,
            enabled: !disabled,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.err_required : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: l10n.profile_email,
            hint: l10n.profile_email_hint,
            prefix: const Icon(Icons.mail_outline),
            controller: _email,
            enabled: !disabled,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.err_required;
              final ok = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(v);
              return ok ? null : l10n.err_email;
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            expand: true,
            isBusy: widget.busy,
            label: l10n.profile_save_changes,
            trailing: const Icon(Icons.save_rounded),
            onPressed: widget.busy
                ? null
                : () {
                    if (_form.currentState?.validate() != true) return;
                    widget.onSubmit(
                      widget.me.copyWith(
                        firstName: _first.text.trim(),
                        lastName: _last.text.trim(),
                        username: _user.text.trim(),
                        email: _email.text.trim(),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
