// lib/features/owner/ownerprofile/presentation/screens/owner_edit_profile_screen.dart

import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/request_owner_phone_change_usecase.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/resend_owner_phone_change_usecase.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/verify_owner_phone_change_usecase.dart';
import 'package:build4all_manager/shared/state/owner_me_store.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
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
import '../../domain/usecases/request_owner_email_change_usecase.dart';
import '../../domain/usecases/verify_owner_email_change_usecase.dart';
import '../../domain/usecases/resend_owner_email_change_usecase.dart';
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

  // ✅ Phone
  late final TextEditingController _phoneCtrl = TextEditingController();
  String _initialCountryCode = 'LB';
  String _originalPhone = '';
  String? _fullPhone;
  bool _phoneWasManuallyEdited = false;
  late final FocusNode _phoneFocusNode = FocusNode();

  // ✅ Password change
  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;

  // ✅ Phone OTP pending state
  bool _phoneOtpPending = false;
  String? _pendingNewPhone;

  // ✅ Email OTP pending state
  bool _emailOtpPending = false;
  String? _pendingNewEmail;

  // ✅ Clean architecture instances
  late final OwnerProfileApi _api = OwnerProfileApi(widget.dio);
  late final OwnerProfileRepositoryImpl _repo = OwnerProfileRepositoryImpl(_api);

  late final UpdateOwnerProfileUseCase _updateUc =
      UpdateOwnerProfileUseCase(_repo);
  late final RequestOwnerEmailChangeUseCase _requestEmailUc =
      RequestOwnerEmailChangeUseCase(_repo);
  late final VerifyOwnerEmailChangeUseCase _verifyEmailUc =
      VerifyOwnerEmailChangeUseCase(_repo);
  late final ResendOwnerEmailChangeUseCase _resendEmailUc =
      ResendOwnerEmailChangeUseCase(_repo);

  late final RequestOwnerPhoneChangeUseCase _requestPhoneUc =
      RequestOwnerPhoneChangeUseCase(_repo);
  late final VerifyOwnerPhoneChangeUseCase _verifyPhoneUc =
      VerifyOwnerPhoneChangeUseCase(_repo);
  late final ResendOwnerPhoneChangeUseCase _resendPhoneUc =
      ResendOwnerPhoneChangeUseCase(_repo);

  @override
  void initState() {
    super.initState();

    _originalPhone = (widget.initial.phoneNumber ?? '').trim();
    _fullPhone = _originalPhone;

    if (_originalPhone.isNotEmpty) {
      try {
        final parsed =
            PhoneNumber.fromCompleteNumber(completeNumber: _originalPhone);
        _initialCountryCode = parsed.countryISOCode;
        _phoneCtrl.text = parsed.number;
        _fullPhone = parsed.completeNumber;
      } catch (_) {
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
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String t(String s) => s.trim();
  bool changed(String a, String b) => t(a) != t(b);

  bool _emailChanged() =>
      t(_email.text).toLowerCase() != t(widget.initial.email).toLowerCase();

  bool _looksLikeEmail(String s) {
    final x = s.trim();
    if (x.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
  }

  String _normalizePhoneForCompare(String? raw) {
    var v = (raw ?? '').trim();
    if (v.isEmpty) return '';

    v = v
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('.', '');

    if (v.startsWith('00')) {
      v = '+${v.substring(2)}';
    }

    // local Lebanese format -> normalize to +961
    if (!v.startsWith('+')) {
      if (RegExp(r'^(3|70|71|76|78|79|81)\d{6}$').hasMatch(v)) {
        v = '+961$v';
      }
    }

    if (v.startsWith('+9610')) {
      v = '+961${v.substring(5)}';
    }

    return v;
  }

  bool _isValidFullPhone(String raw) {
    final v = _normalizePhoneForCompare(raw);
    if (v.isEmpty) return false;
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);
  }

  /// ✅ If IntlPhoneField clears/changes its internal value unexpectedly,
  /// fallback to controller text instead of treating phone as invalid.
  String _effectivePhoneValue() {
    final full = (_fullPhone ?? '').trim();
    if (full.isNotEmpty) return full;
    return _phoneCtrl.text.trim();
  }

  /// ✅ Only consider phone changed if user actually interacted with phone field.
  bool _phoneChanged() {
    if (!_phoneWasManuallyEdited) return false;

    return _normalizePhoneForCompare(_effectivePhoneValue()) !=
        _normalizePhoneForCompare(_originalPhone);
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

      if (code == 409 &&
          (msg.contains('username') || msg.contains('user name'))) {
        return l10n.owner_profile_edit_username_used ?? 'Username already used';
      }

      if (code == 409 && msg.contains('email')) {
        return l10n.owner_profile_edit_email_used ?? 'Email already used';
      }

      if (code == 409 && msg.contains('phone')) {
        return 'Phone number already used';
      }

      if ((code == 400 || code == 401) &&
          (msg.contains('current password') ||
              msg.contains('old password') ||
              msg.contains('wrong password') ||
              msg.contains('invalid password'))) {
        return l10n.owner_profile_edit_wrong_current_password ??
            'Current password is not correct';
      }

      if (msg.contains('email change') && msg.contains('verification')) {
        return l10n.owner_profile_edit_email_requires_verification ??
            'Email change requires verification';
      }

      if (msg.contains('phone change') && msg.contains('verification')) {
        return 'Phone change requires verification';
      }
    }

    final fallback = ApiErrorHandler.message(err).trim();
    return fallback.isEmpty
        ? (l10n.common_error ?? 'Something went wrong')
        : fallback;
  }
  
  // ✅ Build PATCH body (email optional, phone NEVER included anymore)
  Map<String, dynamic> _buildBody({required bool includeEmail}) {
    final p = widget.initial;
    final body = <String, dynamic>{};

    final u = t(_username.text);
    if (u.isNotEmpty && u != p.username.trim()) body['username'] = u;

    final fn = t(_firstName.text);
    if (fn.isNotEmpty && fn != p.firstName.trim()) body['firstName'] = fn;

    final ln = t(_lastName.text);
    if (ln.isNotEmpty && ln != p.lastName.trim()) body['lastName'] = ln;

    if (includeEmail) {
      final em = t(_email.text);
      if (em.isNotEmpty && em != p.email.trim()) body['email'] = em;
    }

    final newPw = _newPass.text.trim();
    if (newPw.isNotEmpty) {
      body['currentPassword'] = _currentPass.text;
      body['newPassword'] = newPw;
    }

    return body;
  }

  bool _validateProfileInputs(AppLocalizations l10n) {
    void min3RequiredIfChanged({
      required String newValue,
      required String oldValue,
      required String requiredMsg,
      required String minMsg,
    }) {
      if (!changed(newValue, oldValue)) return;

      final v = t(newValue);
      if (v.isEmpty) throw requiredMsg;
      if (v.length < 3) throw minMsg;
    }

    try {
      min3RequiredIfChanged(
        newValue: _username.text,
        oldValue: widget.initial.username,
        requiredMsg:
            l10n.owner_profile_edit_username_required ?? 'Username is required',
        minMsg: l10n.owner_profile_edit_username_min3 ??
            'Username must be at least 3 characters',
      );

      min3RequiredIfChanged(
        newValue: _firstName.text,
        oldValue: widget.initial.firstName,
        requiredMsg: l10n.owner_profile_edit_first_name_required ??
            'First name is required',
        minMsg: l10n.owner_profile_edit_first_name_min3 ??
            'First name must be at least 3 characters',
      );

      min3RequiredIfChanged(
        newValue: _lastName.text,
        oldValue: widget.initial.lastName,
        requiredMsg:
            l10n.owner_profile_edit_last_name_required ?? 'Last name is required',
        minMsg: l10n.owner_profile_edit_last_name_min3 ??
            'Last name must be at least 3 characters',
      );

      final em = t(_email.text);
      if (_emailChanged()) {
        if (em.isEmpty) {
          throw l10n.owner_profile_edit_email_required ?? 'Email is required';
        }
        if (!_looksLikeEmail(em)) {
          throw l10n.owner_profile_edit_invalid_email ?? 'Invalid email';
        }
      }

      final newPw = _newPass.text.trim();
      if (newPw.isNotEmpty && newPw.length < 6) {
        throw l10n.owner_profile_edit_new_password_length ??
            'New password must be at least 6 characters';
      }

      if (newPw.isNotEmpty && _currentPass.text.trim().isEmpty) {
        throw l10n.owner_profile_edit_need_current_password ??
            'Enter current password to change it';
      }

      final normalizedPhone =
          _normalizePhoneForCompare(_effectivePhoneValue());

      if (_phoneChanged()) {
        if (normalizedPhone.isEmpty || !_isValidFullPhone(normalizedPhone)) {
          throw l10n.errPhoneInvalid ?? 'Invalid phone number';
        }
      }

      return true;
    } catch (msg) {
      AppToast.error(context, msg.toString());
      return false;
    }
  }

  Future<bool> _emailOtpFlow(AppLocalizations l10n, String newEmail) async {
    try {
      await _requestEmailUc(newEmail);
      if (!mounted) return false;

      AppToast.success(
        context,
        l10n.owner_profile_edit_email_change_sent ?? 'Verification code sent',
      );

      final codeCtrl = TextEditingController();

      final bool? verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final bool narrow = c.maxWidth < 380;

                  Widget resendBtn() => OutlinedButton(
                        onPressed: () async {
                          try {
                            await _resendEmailUc();
                            if (!ctx.mounted) return;
                            AppToast.success(
                              ctx,
                              l10n.owner_profile_edit_email_change_resend_ok ??
                                  'Code resent',
                            );
                          } catch (_) {
                            if (!ctx.mounted) return;
                            AppToast.error(
                              ctx,
                              l10n.owner_profile_edit_email_change_resend_fail ??
                                  'Failed to resend',
                            );
                          }
                        },
                        child: AutoSizeText(
                          l10n.owner_profile_edit_email_change_resend ?? 'Resend',
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );

                  Widget verifyBtn() => FilledButton(
                        onPressed: () async {
                          final code = codeCtrl.text.trim();
                          if (code.length < 4) {
                            AppToast.error(
                              ctx,
                              l10n.owner_profile_edit_email_change_invalid_code ??
                                  'Enter the code',
                            );
                            return;
                          }
                          try {
                            await _verifyEmailUc(code);
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop(true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            AppToast.error(
                              ctx,
                              l10n.owner_profile_edit_email_change_invalid_code ??
                                  'Invalid code',
                            );
                          }
                        },
                        child: AutoSizeText(
                          l10n.owner_profile_edit_email_change_verify ?? 'Verify',
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: AutoSizeText(
                            l10n.owner_profile_edit_email_change_title ??
                                'Verify new email',
                            maxLines: 2,
                            minFontSize: 12,
                            stepGranularity: 0.5,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          subtitle: AutoSizeText(
                            newEmail,
                            maxLines: 2,
                            minFontSize: 11,
                            stepGranularity: 0.5,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primary.withOpacity(.12),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: codeCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText:
                                l10n.owner_profile_edit_email_change_code_hint ??
                                    '6-digit code',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (narrow) ...[
                          SizedBox(width: double.infinity, child: resendBtn()),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: verifyBtn()),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: resendBtn()),
                              const SizedBox(width: 12),
                              Expanded(child: verifyBtn()),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

      return verified == true;
    } catch (e) {
      if (!mounted) return false;
      AppToast.error(context, _friendlyError(l10n, e));
      return false;
    }
  }

  Future<bool> _phoneOtpFlow(AppLocalizations l10n, String newPhone) async {
    try {
      await _requestPhoneUc(newPhone);
      if (!mounted) return false;

      AppToast.success(
        context,
        'Verification code sent',
      );

      final codeCtrl = TextEditingController();

      final bool? verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final bool narrow = c.maxWidth < 380;

                  Widget resendBtn() => OutlinedButton(
                        onPressed: () async {
                          try {
                            await _resendPhoneUc();
                            if (!ctx.mounted) return;
                            AppToast.success(ctx, 'Code resent');
                          } catch (_) {
                            if (!ctx.mounted) return;
                            AppToast.error(ctx, 'Failed to resend');
                          }
                        },
                        child: const AutoSizeText(
                          'Resend',
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );

                  Widget verifyBtn() => FilledButton(
                        onPressed: () async {
                          final code = codeCtrl.text.trim();
                          if (code.length < 4) {
                            AppToast.error(ctx, 'Enter the code');
                            return;
                          }
                          try {
                            await _verifyPhoneUc(code);
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop(true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            AppToast.error(ctx, 'Invalid code');
                          }
                        },
                        child: const AutoSizeText(
                          'Verify',
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: AutoSizeText(
                            'Verify new phone',
                            maxLines: 2,
                            minFontSize: 12,
                            stepGranularity: 0.5,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          subtitle: AutoSizeText(
                            newPhone,
                            maxLines: 2,
                            minFontSize: 11,
                            stepGranularity: 0.5,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primary.withOpacity(.12),
                            child: Icon(Icons.sms_outlined, color: cs.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: codeCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '6-digit code',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (narrow) ...[
                          SizedBox(width: double.infinity, child: resendBtn()),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: verifyBtn()),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: resendBtn()),
                              const SizedBox(width: 12),
                              Expanded(child: verifyBtn()),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

      return verified == true;
    } catch (e) {
      if (!mounted) return false;
      AppToast.error(context, _friendlyError(l10n, e));
      return false;
    }
  }

  Widget _topHint(AppLocalizations l10n, String text) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AutoSizeText(
        text,
        maxLines: 1,
        minFontSize: 11,
        stepGranularity: 0.5,
        overflow: TextOverflow.ellipsis,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocProvider(
      create: (_) => OwnerProfileEditCubit(update: _updateUc),
      child: BlocListener<OwnerProfileEditCubit, OwnerProfileEditState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error || prev.updated != curr.updated,
        listener: (context, s) async {
          if (!context.mounted) return;

          if (s.error != null) {
            AppToast.error(context, _friendlyError(l10n, s.error!));
            return;
          }

          if (s.updated != null) {
            final up = s.updated!;

            final first = up.firstName.trim();
            final last = up.lastName.trim();
            final full =
                [first, last].where((e) => e.isNotEmpty).join(' ').trim();
            OwnerMeStore.I.setName(full.isNotEmpty ? full : up.username.trim());

            // ✅ After profile save, run pending OTP flows (email then phone)
            if (_emailOtpPending || _phoneOtpPending) {
              if (_emailOtpPending && _pendingNewEmail != null) {
                final ok = await _emailOtpFlow(l10n, _pendingNewEmail!);
                if (!context.mounted) return;
                if (!ok) return;

                _emailOtpPending = false;
                _pendingNewEmail = null;

                AppToast.success(
                  context,
                  l10n.owner_profile_edit_email_change_verified ??
                      'Email updated',
                );
              }

              if (_phoneOtpPending && _pendingNewPhone != null) {
                final ok = await _phoneOtpFlow(l10n, _pendingNewPhone!);
                if (!context.mounted) return;
                if (!ok) return;

                _phoneOtpPending = false;
                _pendingNewPhone = null;

                AppToast.success(
                  context,
                  'Phone number updated',
                );
              }

              await Future.delayed(const Duration(milliseconds: 50));
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
              return;
            }

            AppToast.success(
              context,
              l10n.owner_profile_edit_saved ?? 'Profile updated',
            );

            await Future.delayed(const Duration(milliseconds: 50));
            if (!context.mounted) return;

            Navigator.of(context).pop(true);
          }
        },
        child: BlocBuilder<OwnerProfileEditCubit, OwnerProfileEditState>(
          builder: (context, s) {
            final saving = s.saving;

            Future<void> onSave() async {
              if (!_validateProfileInputs(l10n)) return;

              final newEmail = t(_email.text);
              final emailChanged = _emailChanged();

              final newPhone =
                  _normalizePhoneForCompare(_effectivePhoneValue());
              final phoneChanged = _phoneChanged();

              // email changed => exclude email from PATCH
              // phone changed => NEVER include phone in PATCH
              final body = _buildBody(includeEmail: !emailChanged);

              // nothing changed
              if (body.isEmpty && !emailChanged && !phoneChanged) {
                AppToast.success(context, l10n.common_saved ?? 'Saved');
                Navigator.of(context).pop(false);
                return;
              }

              // only OTP flows changed (no normal profile fields)
              if (body.isEmpty) {
                if (emailChanged) {
                  final ok = await _emailOtpFlow(l10n, newEmail);
                  if (!mounted || !ok) return;

                  AppToast.success(
                    context,
                    l10n.owner_profile_edit_email_change_verified ??
                        'Email updated',
                  );
                }

                if (phoneChanged) {
                  final ok = await _phoneOtpFlow(l10n, newPhone);
                  if (!mounted || !ok) return;

                  AppToast.success(context, 'Phone number updated');
                }

                if (!mounted) return;
                Navigator.of(context).pop(true);
                return;
              }

              // save normal profile fields first, then OTP flows in listener
              if (emailChanged) {
                _emailOtpPending = true;
                _pendingNewEmail = newEmail;
              } else {
                _emailOtpPending = false;
                _pendingNewEmail = null;
              }

              if (phoneChanged) {
                _phoneOtpPending = true;
                _pendingNewPhone = newPhone;
              } else {
                _phoneOtpPending = false;
                _pendingNewPhone = null;
              }

              await context.read<OwnerProfileEditCubit>().save(body);
            }

            InputDecoration deco({String? hint, Widget? suffix}) =>
                InputDecoration(
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
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
                hintText: l10n.hintPhone ?? '70 123 456',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
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
                    card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionTitle(
                              l10n.owner_profile_edit_basic ?? 'Basic info',
                            ),

                            _topHint(
                              l10n,
                              l10n.owner_profile_username ?? 'Username',
                            ),
                            TextField(
                              controller: _username,
                              textInputAction: TextInputAction.next,
                              decoration: deco(),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _topHint(
                                        l10n,
                                        l10n.owner_profile_first_name ??
                                            'First name',
                                      ),
                                      TextField(
                                        controller: _firstName,
                                        textInputAction: TextInputAction.next,
                                        decoration: deco(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _topHint(
                                        l10n,
                                        l10n.owner_profile_last_name ??
                                            'Last name',
                                      ),
                                      TextField(
                                        controller: _lastName,
                                        textInputAction: TextInputAction.next,
                                        decoration: deco(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _topHint(l10n, l10n.owner_profile_email ?? 'Email'),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: deco(),
                            ),

                            const SizedBox(height: 12),

                            _topHint(l10n, l10n.owner_profile_phone ?? 'Phone'),
                            IntlPhoneField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocusNode,
                              initialCountryCode: _initialCountryCode,
                              disableLengthCheck: false,
                              decoration: phoneDeco(),
                              onChanged: (phone) {
                                if (!mounted) return;

                                final nextFullPhone =
                                    phone.number.trim().isEmpty
                                        ? ''
                                        : phone.completeNumber;

                                setState(() {
                                  _fullPhone = nextFullPhone;

                                  if (_phoneFocusNode.hasFocus) {
                                    _phoneWasManuallyEdited = true;
                                  }
                                });
                              },
                              onCountryChanged: (country) {
                                if (!mounted) return;

                                setState(() {
                                  _phoneWasManuallyEdited = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionTitle(
                              l10n.owner_profile_edit_security ?? 'Security',
                            ),

                            _topHint(
                              l10n,
                              l10n.owner_profile_edit_current_password ??
                                  'Current password',
                            ),
                            TextField(
                              controller: _currentPass,
                              obscureText: _hideCurrent,
                              decoration: deco(
                                suffix: IconButton(
                                  onPressed: saving
                                      ? null
                                      : () => setState(
                                            () => _hideCurrent = !_hideCurrent,
                                          ),
                                  icon: Icon(
                                    _hideCurrent
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _topHint(
                              l10n,
                              l10n.owner_profile_edit_new_password ??
                                  'New password',
                            ),
                            TextField(
                              controller: _newPass,
                              obscureText: _hideNew,
                              decoration: deco(
                                suffix: IconButton(
                                  onPressed: saving
                                      ? null
                                      : () =>
                                          setState(() => _hideNew = !_hideNew),
                                  icon: Icon(
                                    _hideNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              l10n.owner_profile_edit_password_hint ??
                                  'Leave blank to keep your password.',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
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