
import 'package:build4all_manager/features/auth/data/models/country_model.dart';
import 'package:build4all_manager/features/auth/data/services/country_api.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../bloc/register/OwnerRegisterBloc.dart';
import '../../bloc/register/owner_register_event.dart';
import '../../bloc/register/owner_register_state.dart';

class OwnerRegisterProfileScreen extends StatefulWidget {
  final String registrationToken;
  final Dio dio;

  const OwnerRegisterProfileScreen({
    super.key,
    required this.registrationToken,
    required this.dio,
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

  String? _fullPhone;
  int? _selectedCountryId;
  List<CountryModel> _countries = [];
  bool _loadingCountries = true;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  @override
  void dispose() {
    _username.dispose();
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    try {
      final countries = await CountryApi(widget.dio).getActiveCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCountries = false);
    }
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  void _submit(AppLocalizations l10n) {
    final form = _form.currentState;
    if (form == null) return;

    if (!form.validate()) return;

    final phone = (_fullPhone ?? '').trim();
    if (phone.isEmpty) {
      AppToast.info(context, l10n.errPhoneRequired);
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<OwnerRegisterBloc>().add(
          OwnerCompleteProfile(
            widget.registrationToken,
            _username.text.trim(),
            _first.text.trim(),
            _last.text.trim(),
            phone,
            countryId: _selectedCountryId,
          ),
        );
  }

  void _goToLogin() {
    context.go('/owner/login');
  }

  InputDecoration _phoneDecoration(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: l10n.lblPhone,
      hintText: l10n.hintPhone,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<OwnerRegisterBloc, OwnerRegisterState>(
      listenWhen: (p, c) => p.error != c.error || p.completed != c.completed,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }

        if (state.completed) {
          AppToast.success(context, l10n.msgOwnerRegistered);
          _goToLogin();
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
                      const SizedBox(height: 14),

                      // Phone field with country code
                      IntlPhoneField(
                        initialCountryCode: 'LB',
                        decoration: _phoneDecoration(context, l10n),
                        onChanged: (phone) {
                          _fullPhone = phone.completeNumber;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.trim().isEmpty) {
                            return l10n.errPhoneRequired;
                          }
                          if (phone.number.trim().length < 6) {
                            return l10n.errPhoneInvalid;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Country dropdown
                      if (_loadingCountries)
                        const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedCountryId,
                          decoration: InputDecoration(
                            labelText: l10n.lblCountry,
                            hintText: l10n.hintSelectCountry,
                            prefixIcon: const Icon(Icons.public_outlined),
                            filled: true,
                            fillColor: cs.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: cs.outlineVariant.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: cs.outlineVariant.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 1.4),
                            ),
                          ),
                          isExpanded: true,
                          items: _countries
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCountryId = v),
                          validator: (_) => _selectedCountryId == null
                              ? l10n.errCountryRequired
                              : null,
                        ),

                      const SizedBox(height: 20),
                      AppButton(
                        label: l10n.btnCreateAccount,
                        isBusy: state.loading,
                        expand: true,
                        trailing: const Icon(Icons.check_circle_rounded),
                        onPressed: state.loading ? null : () => _submit(l10n),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(l10n.alreadyHaveAccountLogin),
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
