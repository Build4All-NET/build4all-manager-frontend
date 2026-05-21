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
  final _countryDisplay = TextEditingController();

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
    _countryDisplay.dispose();
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

  void _goToLogin() => context.go('/owner/login');

  void _openCountryPicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        countries: _countries,
        selectedId: _selectedCountryId,
        onSelected: (country) {
          setState(() {
            _selectedCountryId = country.id;
            _countryDisplay.text = country.name;
          });
        },
      ),
    );
  }

  InputDecoration _inputDeco(
    BuildContext context, {
    required String label,
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _username,
                          label: l10n.lblUsername,
                          hint: l10n.hintUsername,
                          prefix: const Icon(Icons.alternate_email),
                          validator: (v) =>
                              _required(v, l10n.errUsernameRequired),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _first,
                          label: l10n.lblFirstName,
                          hint: l10n.hintFirstName,
                          prefix: const Icon(Icons.person_outline),
                          validator: (v) =>
                              _required(v, l10n.errFirstNameRequired),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _last,
                          label: l10n.lblLastName,
                          hint: l10n.hintLastName,
                          prefix: const Icon(Icons.person_outline),
                          validator: (v) =>
                              _required(v, l10n.errLastNameRequired),
                        ),
                        const SizedBox(height: 14),

                        // Phone field
                        IntlPhoneField(
                          initialCountryCode: 'LB',
                          decoration: _inputDeco(
                            context,
                            label: l10n.lblPhone,
                            hint: l10n.hintPhone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          onChanged: (phone) {
                            _fullPhone = phone.completeNumber;
                          },
                          validator: (phone) {
                            if (phone == null ||
                                phone.number.trim().isEmpty) {
                              return l10n.errPhoneRequired;
                            }
                            if (phone.number.trim().length < 6) {
                              return l10n.errPhoneInvalid;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Searchable country picker trigger
                        TextFormField(
                          controller: _countryDisplay,
                          readOnly: true,
                          onTap: _loadingCountries
                              ? null
                              : () => _openCountryPicker(l10n),
                          decoration: _inputDeco(
                            context,
                            label: l10n.lblCountry,
                            hint: l10n.hintSelectCountry,
                            prefixIcon:
                                const Icon(Icons.public_outlined),
                            suffixIcon: _loadingCountries
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_drop_down_rounded),
                          ),
                          validator: (_) => _selectedCountryId == null
                              ? l10n.errCountryRequired
                              : null,
                        ),

                        const SizedBox(height: 24),
                        AppButton(
                          label: l10n.btnCreateAccount,
                          isBusy: state.loading,
                          expand: true,
                          trailing:
                              const Icon(Icons.check_circle_rounded),
                          onPressed: state.loading
                              ? null
                              : () => _submit(l10n),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _goToLogin,
                          child: Text(l10n.alreadyHaveAccountLogin),
                        ),
                        const SizedBox(height: 16),
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

// ─── Country Picker Bottom Sheet ─────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final List<CountryModel> countries;
  final int? selectedId;
  final ValueChanged<CountryModel> onSelected;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<CountryModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.countries);
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(widget.countries)
          : widget.countries
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search country…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: cs.primary, width: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No countries found',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      final isSelected = c.id == widget.selectedId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        leading: Icon(
                          Icons.public_outlined,
                          color: isSelected
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          size: 22,
                        ),
                        title: Text(
                          c.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: isSelected
                                    ? cs.primary
                                    : cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded,
                                color: cs.primary, size: 20)
                            : null,
                        onTap: () {
                          widget.onSelected(c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
