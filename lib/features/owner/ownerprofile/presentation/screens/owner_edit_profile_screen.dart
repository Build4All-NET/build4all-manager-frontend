import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/shared/state/owner_me_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../data/repositories/owner_profile_repository_impl.dart';
import '../../data/services/owner_profile_api.dart';
import '../../domain/entities/owner_profile.dart';
import '../../domain/usecases/update_owner_profile_usecase.dart';
import '../cubit/owner_profile_edit_cubit.dart';

class OwnerEditProfileScreen extends StatefulWidget {
  final Dio dio;
  final OwnerProfile initial;

  const OwnerEditProfileScreen({
    super.key,
    required this.dio,
    required this.initial,
  });

  @override
  State<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends State<OwnerEditProfileScreen> {
  late final TextEditingController _username =
      TextEditingController(text: widget.initial.username);
  late final TextEditingController _firstName =
      TextEditingController(text: widget.initial.firstName);
  late final TextEditingController _lastName =
      TextEditingController(text: widget.initial.lastName);
  late final TextEditingController _email =
      TextEditingController(text: widget.initial.email);

  // ✅ Phone as real phone input
  late final TextEditingController _phoneCtrl = TextEditingController();
  String _initialCountryCode = 'LB';
  String _originalPhone = '';
  String? _fullPhone; // ex: +96170123456 ("" means clear)

  // ✅ Password change
  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;

  @override
  void initState() {
    super.initState();

    _originalPhone = (widget.initial.phoneNumber ?? '').trim();
    _fullPhone = _originalPhone;

    // Try to parse existing phone into IntlPhoneField (country + national number)
    if (_originalPhone.isNotEmpty) {
      try {
        final parsed =
            PhoneNumber.fromCompleteNumber(completeNumber: _originalPhone);
        _initialCountryCode = parsed.countryISOCode;
        _phoneCtrl.text = parsed.number; // national part
        _fullPhone = parsed.completeNumber;
      } catch (_) {
        // fallback: keep LB + put whatever we have as "number"
        _initialCountryCode = 'LB';
        _phoneCtrl.text = _originalPhone.replaceAll('+', '');
      }
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phoneCtrl.dispose();
    _currentPass.dispose();
    _newPass.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final x = s.trim();
    if (x.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
  }

  String _extractBackendMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      final msg = (data['error'] ?? data['message'] ?? '').toString().trim();
      if (msg.isNotEmpty) return msg;
    }

    if (data is String && data.trim().isNotEmpty) return data.trim();

    return (e.message ?? '').trim();
  }

  String _friendlyError(AppLocalizations l10n, Object err) {
    if (err is DioException) {
      final code = err.response?.statusCode;
      final msgRaw = _extractBackendMessage(err);
      final msg = msgRaw.toLowerCase();

      // ✅ username already used
      if (code == 409 && (msg.contains('username') || msg.contains('user name'))) {
        return l10n.owner_profile_edit_username_used ?? 'Username already used';
      }

      // ✅ email already used
      if (code == 409 && msg.contains('email')) {
        return l10n.owner_profile_edit_email_used ?? 'Email already used';
      }

      // ✅ wrong current/old password
      if ((code == 400 || code == 401) &&
          (msg.contains('current password') ||
              msg.contains('old password') ||
              msg.contains('wrong password') ||
              msg.contains('invalid password'))) {
        return l10n.owner_profile_edit_wrong_current_password ??
            'Current password is not correct';
      }

      // ✅ show backend message if it's already clear
      if (msgRaw.isNotEmpty) return msgRaw;

      return l10n.common_error ?? 'Something went wrong';
    }

    final s = err.toString().trim();
    return s.isEmpty ? (l10n.common_error ?? 'Something went wrong') : s;
  }

  Map<String, dynamic> _buildBody() {
    final p = widget.initial;

    String t(String s) => s.trim();
    final body = <String, dynamic>{};

    final u = t(_username.text);
    if (u.isNotEmpty && u != p.username.trim()) body['username'] = u;

    final fn = t(_firstName.text);
    if (fn.isNotEmpty && fn != p.firstName.trim()) body['firstName'] = fn;

    final ln = t(_lastName.text);
    if (ln.isNotEmpty && ln != p.lastName.trim()) body['lastName'] = ln;

    final em = t(_email.text);
    if (em.isNotEmpty && em != p.email.trim()) body['email'] = em;

    // phone: allow clearing by sending empty string
    final newPhone = (_fullPhone ?? _originalPhone).trim();
    if (newPhone != _originalPhone) {
      body['phoneNumber'] = newPhone; // "" => clear
    }

    // password change (optional)
    final newPw = _newPass.text.trim();
    if (newPw.isNotEmpty) {
      body['currentPassword'] = _currentPass.text;
      body['newPassword'] = newPw;
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final repo = OwnerProfileRepositoryImpl(OwnerProfileApi(widget.dio));
    final updateUc = UpdateOwnerProfileUseCase(repo);

    return BlocProvider(
      create: (_) => OwnerProfileEditCubit(update: updateUc),
   child: BlocListener<OwnerProfileEditCubit, OwnerProfileEditState>(
  listenWhen: (prev, curr) {
    // فقط لما تتغير error أو updated فعليًا
    return prev.error != curr.error || prev.updated != curr.updated;
  },
  listener: (context, s) async {
    if (!context.mounted) return;

    // ✅ ERROR FIRST
    if (s.error != null) {
      AppToast.error(context, _friendlyError(l10n, s.error!));
      return;
    }

    // ✅ SUCCESS (only once)
    if (s.updated != null) {
      final up = s.updated!;

      final first = up.firstName.trim();
      final last = up.lastName.trim();
      final full = [first, last].where((e) => e.isNotEmpty).join(' ').trim();

      OwnerMeStore.I.setName(full.isNotEmpty ? full : up.username.trim());

    
      AppToast.success(context, l10n.owner_profile_edit_saved ?? 'Profile updated');

      await Future.delayed(const Duration(milliseconds: 50));
      if (!context.mounted) return;

      Navigator.of(context).pop(true);
    }
  },
  child: BlocBuilder<OwnerProfileEditCubit, OwnerProfileEditState>(

          builder: (context, s) {
            final saving = s.saving;

            Future<void> onSave() async {
              final em = _email.text.trim();
              if (em.isNotEmpty && !_looksLikeEmail(em)) {
                AppToast.error(
                  context,
                  l10n.owner_profile_edit_invalid_email ?? 'Invalid email',
                );
                return;
              }

              // if user tries password change without current pass -> block
              if (_newPass.text.trim().isNotEmpty &&
                  _currentPass.text.trim().isEmpty) {
                AppToast.error(
                  context,
                  l10n.owner_profile_edit_need_current_password ??
                      'Enter current password to change it',
                );
                return;
              }

              // phone guard (optional): if they typed something too short
              final phoneNumberOnly = _phoneCtrl.text.trim();
              if (phoneNumberOnly.isNotEmpty && phoneNumberOnly.length < 6) {
                AppToast.error(
                  context,
                  l10n.errPhoneInvalid ?? 'Invalid phone number',
                );
                return;
              }

              final body = _buildBody();
              if (body.isEmpty) {
                AppToast.success(context, l10n.common_saved ?? 'Saved');
                Navigator.of(context).pop(false);
                return;
              }

              await context.read<OwnerProfileEditCubit>().save(body);
            }

            InputDecoration deco(String hint, {Widget? suffix}) => InputDecoration(
                  hintText: hint,
                  suffixIcon: suffix,
                );

            Widget sectionTitle(String text) => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                  child: AutoSizeText(
                    text,
                    maxLines: 1,
                    minFontSize: 14,
                    stepGranularity: .5,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                );

            Widget card({required Widget child}) => Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
                  ),
                  child: child,
                );

            InputDecoration phoneDeco() {
              return InputDecoration(
                labelText: l10n.owner_profile_phone ?? 'Phone',
                hintText: l10n.hintPhone ?? '70 123 456',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
                suffixIcon: IconButton(
                  tooltip: l10n.common_clear ?? 'Clear',
                  onPressed: saving
                      ? null
                      : () {
                          _phoneCtrl.clear();
                          setState(() => _fullPhone = ''); // ✅ clear
                        },
                  icon: const Icon(Icons.close_rounded),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: AutoSizeText(
                  l10n.owner_profile_edit_title ?? 'Edit profile',
                  maxLines: 1,
                  minFontSize: 14,
                  stepGranularity: .5,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : AutoSizeText(
                            l10n.owner_profile_edit_save ?? 'Save',
                            maxLines: 1,
                            minFontSize: 12,
                            stepGranularity: .5,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    // ✅ BASIC INFO (no preferences anymore)
                    card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionTitle(l10n.owner_profile_edit_basic ?? 'Basic info'),
                            TextField(
                              controller: _username,
                              textInputAction: TextInputAction.next,
                              decoration: deco(l10n.owner_profile_username ?? 'Username'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _firstName,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(l10n.owner_profile_first_name ?? 'First name'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _lastName,
                                    textInputAction: TextInputAction.next,
                                    decoration: deco(l10n.owner_profile_last_name ?? 'Last name'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: deco(l10n.owner_profile_email ?? 'Email'),
                            ),
                            const SizedBox(height: 12),

                            // ✅ PHONE FIELD (IntlPhoneField)
                            IntlPhoneField(
                              controller: _phoneCtrl,
                              initialCountryCode: _initialCountryCode,
                              disableLengthCheck: true,
                              decoration: phoneDeco(),
                             onChanged: (phone) {
  if (!mounted) return;
  setState(() {
    _fullPhone = phone.number.trim().isEmpty ? '' : phone.completeNumber;
  });
},
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ SECURITY
                    card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionTitle(l10n.owner_profile_edit_security ?? 'Security'),
                            TextField(
                              controller: _currentPass,
                              obscureText: _hideCurrent,
                              decoration: deco(
                                l10n.owner_profile_edit_current_password ?? 'Current password',
                                suffix: IconButton(
                                  onPressed: saving
                                      ? null
                                      : () => setState(() => _hideCurrent = !_hideCurrent),
                                  icon: Icon(_hideCurrent ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPass,
                              obscureText: _hideNew,
                              decoration: deco(
                                l10n.owner_profile_edit_new_password ?? 'New password',
                                suffix: IconButton(
                                  onPressed: saving
                                      ? null
                                      : () => setState(() => _hideNew = !_hideNew),
                                  icon: Icon(_hideNew ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.owner_profile_edit_password_hint ??
                                  'Leave blank to keep your password.',
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving ? null : onSave,
                        child: AutoSizeText(
                          l10n.owner_profile_edit_save ?? 'Save',
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: .5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
