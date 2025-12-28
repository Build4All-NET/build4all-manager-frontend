import 'dart:convert';
import 'dart:io';

import 'package:build4all_manager/features/owner/ownernav/presentation/controllers/owner_nav_cubit.dart';
import 'package:build4all_manager/features/owner/ownerrequests/presentation/widgets/runtime_draft.dart';
import 'package:build4all_manager/features/owner/ownerrequests/presentation/widgets/runtime_section.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/models/currency_model.dart';
import '../../data/services/owner_requests_api.dart';

class OwnerRequestScreen extends StatefulWidget {
  final String baseUrl;
  final int ownerId;
  final Dio dio;

  final int? initialProjectId;
  final String? initialAppName;

  const OwnerRequestScreen({
    super.key,
    required this.baseUrl,
    required this.ownerId,
    required this.dio,
    this.initialProjectId,
    this.initialAppName,
  });

  @override
  State<OwnerRequestScreen> createState() => _OwnerRequestScreenState();
}

class _OwnerRequestScreenState extends State<OwnerRequestScreen> {
  late final OwnerRequestApi api;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _projectIdCtrl;
  late final TextEditingController _appNameCtrl;
  final _notesCtrl = TextEditingController();
  final _apiOverrideCtrl = TextEditingController();

  bool _loading = false;

  List<CurrencyModel> _currencies = [];
  CurrencyModel? _selectedCurrency;

  File? _logoFile;

  // Palette
  String? _selectedPresetId = 'pink_pop';
  ThemeDraft _draft = ThemePresets.byId('pink_pop').draft;

  // Runtime
  RuntimeDraft _runtime = RuntimeDefaults.defaults();

  @override
  void initState() {
    super.initState();
    api = OwnerRequestApi(dio: widget.dio, baseUrl: widget.baseUrl);

    _projectIdCtrl = TextEditingController(
      text: widget.initialProjectId?.toString() ?? '',
    );

    _appNameCtrl = TextEditingController(text: widget.initialAppName ?? '');

    _loadCurrencies();
  }

  @override
  void dispose() {
    _projectIdCtrl.dispose();
    _appNameCtrl.dispose();
    _notesCtrl.dispose();
    _apiOverrideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final l = AppLocalizations.of(context)!;
    try {
      final list = await api.fetchCurrencies();
      if (!mounted) return;
      setState(() {
        _currencies = list;

        final eur = list.where((c) => c.code.toUpperCase() == 'EUR').toList();
        _selectedCurrency =
            eur.isNotEmpty ? eur.first : (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l.owner_request_err_load_currencies);
    }
  }

  Future<void> _pickLogo() async {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    final picker = ImagePicker();
    final res =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (res == null) return;

    if (!mounted) return;
    setState(() => _logoFile = File(res.path));
    AppToast.success(context, l.owner_request_logo_selected);
  }

  void _removeLogo() {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    setState(() => _logoFile = null);
    AppToast.success(context, l.owner_request_logo_removed);
  }

  String? _validateInt(String? v) {
    final l = AppLocalizations.of(context)!;

    final s = (v ?? '').trim();
    if (s.isEmpty) return l.err_required;
    final n = int.tryParse(s);
    if (n == null || n <= 0) return l.owner_request_err_valid_number;
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context)!;

    if (_selectedCurrency == null) {
      AppToast.error(context, l.owner_request_err_select_currency);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      AppToast.error(context, l.owner_request_err_fix_fields);
      return;
    }

    final projectId = int.parse(_projectIdCtrl.text.trim());
    final appName = _appNameCtrl.text.trim();
    if (appName.isEmpty) {
      AppToast.error(context, l.owner_request_err_app_name_required);
      return;
    }

    setState(() => _loading = true);

    try {
      final primaryHex = _hex(_draft.primary);
      final secondaryHex = _hex(_draft.secondary);
      final bgHex = _hex(_draft.background);
      final onBgHex = _hex(_draft.onBackground);
      final errorHex = _hex(_draft.error);

      final out = _runtime.toJsonOut();

      await api.submitOwnerRequest(
        ownerId: widget.ownerId,
        projectId: projectId,
        appName: appName,
        notes: _notesCtrl.text.trim(),
        primaryColor: primaryHex,
        secondaryColor: secondaryHex,
        backgroundColor: bgHex,
        onBackgroundColor: onBgHex,
        errorColor: errorHex,
        currencyId: _selectedCurrency!.id,
        navJson: out.navJson,
        homeJson: out.homeJson,
        enabledFeaturesJson: out.enabledFeaturesJson,
        brandingJson: out.brandingJson,
        apiBaseUrlOverride: _apiOverrideCtrl.text.trim().isEmpty
            ? null
            : _apiOverrideCtrl.text.trim(),
        logoFile: _logoFile,
      );

      if (!mounted) return;

      AppToast.success(context, l.owner_request_submit_success);
      try {
        context.read<OwnerNavCubit>().setIndex(1);
      } catch (_) {}

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      final l2 = AppLocalizations.of(context)!;

      String msg = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          msg = data['error'].toString();
        } else if (data is String && data.isNotEmpty) {
          msg = data;
        }
      }

      AppToast.error(context, l2.owner_request_submit_failed(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.owner_request_title),
        actions: [
          IconButton(
            tooltip: l.refresh,
            onPressed: _loading ? null : _loadCurrencies,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        loading: _loading,
        onSubmit: _submit,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final maxW = isWide ? 820.0 : double.infinity;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                    children: [
                      _ProHero(
                        title: l.owner_request_hero_title,
                        subtitle: l.owner_request_hero_subtitle,
                        icon: Icons.rocket_launch_rounded,
                      ),
                      const SizedBox(height: 14),
                      _SectionTitle(
                        title: l.owner_request_basics_title,
                        subtitle: l.owner_request_basics_subtitle,
                        icon: Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _ProCard(
                        child: Column(
                          children: [
                            _ProField(
                              enabled: false,
                              child: TextFormField(
                                controller: _projectIdCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: l.owner_request_project_id,
                                  hintText: l.owner_request_project_id_hint,
                                  prefixIcon: const Icon(Icons.numbers_rounded),
                                ),
                                validator: _validateInt,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ProField(
                              enabled: !_loading,
                              child: TextFormField(
                                controller: _appNameCtrl,
                                decoration: InputDecoration(
                                  labelText: l.owner_request_app_name,
                                  hintText: l.owner_request_app_name_hint,
                                  prefixIcon: const Icon(Icons.apps_rounded),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? l.err_required
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ProField(
                              enabled: !_loading,
                              child: TextFormField(
                                controller: _notesCtrl,
                                decoration: InputDecoration(
                                  labelText: l.owner_request_notes,
                                  hintText: l.owner_request_notes_hint,
                                  prefixIcon: const Icon(Icons.notes_rounded),
                                ),
                                maxLines: 3,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? l.err_required
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: l.owner_request_settings_title,
                        subtitle: l.owner_request_settings_subtitle,
                        icon: Icons.tune_rounded,
                      ),
                      const SizedBox(height: 10),
                      _ProCard(
                        child: Column(
                          children: [
                            IgnorePointer(
                              ignoring: _loading,
                              child: Opacity(
                                opacity: _loading ? 0.55 : 1,
                                child: _currencyPickerTile(cs),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ProField(
                              enabled: !_loading,
                              child: TextFormField(
                                controller: _apiOverrideCtrl,
                                decoration: InputDecoration(
                                  labelText: l.owner_request_api_override,
                                  hintText: l.owner_request_api_override_hint,
                                  prefixIcon: const Icon(Icons.link_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: l.owner_request_palette_title,
                        subtitle: l.owner_request_palette_subtitle,
                        icon: Icons.palette_outlined,
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: _loading,
                        child: Opacity(
                          opacity: _loading ? 0.55 : 1,
                          child: _ProCard(
                            child: PaletteSection(
                              draft: _draft,
                              selectedPresetId: _selectedPresetId,
                              onChanged: (d) => setState(() => _draft = d),
                              onPresetChanged: (id) =>
                                  setState(() => _selectedPresetId = id),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: l.owner_request_runtime_title,
                        subtitle: l.owner_request_runtime_subtitle,
                        icon: Icons.dashboard_customize_rounded,
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: _loading,
                        child: Opacity(
                          opacity: _loading ? 0.55 : 1,
                          child: _ProCard(
                            child: RuntimeSection(
                              draft: _runtime,
                              onChanged: (d) => setState(() => _runtime = d),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: l.owner_request_branding_title,
                        subtitle: l.owner_request_branding_subtitle,
                        icon: Icons.image_outlined,
                      ),
                      const SizedBox(height: 10),
                      _ProCard(child: _logoPicker(cs)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _currencyPickerTile(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;

    final label = _selectedCurrency?.label ?? l.owner_request_select_currency;
    final subtitle = _selectedCurrency == null
        ? l.owner_request_tap_to_choose
        : '${_selectedCurrency!.code} • id=${_selectedCurrency!.id}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        if (_currencies.isEmpty) await _loadCurrencies();
        if (!mounted) return;

        final picked = await _showCurrencySearchSheet(context, _currencies);
        if (picked != null) {
          setState(() => _selectedCurrency = picked);
          AppToast.success(context, l.owner_request_currency_set(picked.code));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.65),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _logoPicker(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: _logoFile == null
              ? Icon(Icons.image_outlined, color: cs.onSurfaceVariant)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_logoFile!, fit: BoxFit.cover),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _logoFile == null
                ? l.owner_request_no_logo
                : _logoFile!.path.split(Platform.pathSeparator).last,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        if (_logoFile != null)
          IconButton(
            tooltip: l.common_remove,
            onPressed: _loading ? null : _removeLogo,
            icon: const Icon(Icons.delete_outline),
          ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickLogo,
          icon: const Icon(Icons.upload_rounded),
          label: Text(l.owner_request_pick_logo),
        ),
      ],
    );
  }

  Future<CurrencyModel?> _showCurrencySearchSheet(
    BuildContext context,
    List<CurrencyModel> all,
  ) async {
    return showModalBottomSheet<CurrencyModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final l = AppLocalizations.of(ctx)!;

        final controller = TextEditingController();
        List<CurrencyModel> filtered = List.of(all);

        void apply(String q) {
          final s = q.trim().toLowerCase();
          if (s.isEmpty) {
            filtered = List.of(all);
          } else {
            filtered = all.where((c) {
              final hay = '${c.label} ${c.code} ${c.id}'.toLowerCase();
              return hay.contains(s);
            }).toList();
          }
        }

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.owner_request_pick_currency,
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ),
                        Icon(Icons.payments_outlined, color: cs.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l.owner_request_currency_search_hint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  controller.clear();
                                  setSheet(() => apply(''));
                                },
                              ),
                      ),
                      onChanged: (q) => setSheet(() => apply(q)),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: cs.outlineVariant,
                        ),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final selected = _selectedCurrency?.id == c.id;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              c.label,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${c.code} • id=${c.id}'),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: cs.primary)
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(ctx, c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ✅ Fixed submit pinned at bottom
class _SubmitBar extends StatelessWidget {
  final bool loading;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.owner_request_submit_ready,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.owner_request_submit_desc,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(loading ? l.owner_request_submitting : l.submit),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// PRO UI helpers
/// ===============================================================

class _ProHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ProHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: t.bodySmall
                      ?.copyWith(color: cs.onSurface.withOpacity(.65))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProCard extends StatelessWidget {
  final Widget child;
  const _ProCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ProField extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _ProField({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme:
                Theme.of(context).inputDecorationTheme.copyWith(
                      filled: true,
                      fillColor: cs.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ===============================================================
/// Palette UI (FULLY localized)
/// ===============================================================

class ThemeDraft {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color onBackground;
  final Color error;

  const ThemeDraft({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.onBackground,
    required this.error,
  });

  ThemeDraft copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? onBackground,
    Color? error,
  }) {
    return ThemeDraft(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
    );
  }
}

class ThemePreset {
  final String id;
  final String label;
  final ThemeDraft draft;

  const ThemePreset({
    required this.id,
    required this.label,
    required this.draft,
  });
}

class ThemePresets {
  static const presets = <ThemePreset>[
    ThemePreset(
      id: 'pink_pop',
      label: 'Pink Pop',
      draft: ThemeDraft(
        primary: Color(0xFFEC4899),
        secondary: Color(0xFF111827),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF374151),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'ocean_blue',
      label: 'Ocean Blue',
      draft: ThemeDraft(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF0F172A),
        background: Color(0xFFF8FAFC),
        onBackground: Color(0xFF0F172A),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'forest',
      label: 'Forest',
      draft: ThemeDraft(
        primary: Color(0xFF16A34A),
        secondary: Color(0xFF064E3B),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF14532D),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'sunset',
      label: 'Sunset',
      draft: ThemeDraft(
        primary: Color(0xFFF97316),
        secondary: Color(0xFF7C2D12),
        background: Color(0xFFFFFBEB),
        onBackground: Color(0xFF1F2937),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'midnight',
      label: 'Midnight',
      draft: ThemeDraft(
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFFE5E7EB),
        background: Color(0xFF0B0F14),
        onBackground: Color(0xFFE5E7EB),
        error: Color(0xFFEF4444),
      ),
    ),
  ];

  static ThemePreset byId(String id) =>
      presets.firstWhere((p) => p.id == id, orElse: () => presets.first);
}

class PaletteSection extends StatelessWidget {
  final ThemeDraft draft;
  final String? selectedPresetId;
  final ValueChanged<ThemeDraft> onChanged;
  final ValueChanged<String?> onPresetChanged;

  const PaletteSection({
    super.key,
    required this.draft,
    required this.selectedPresetId,
    required this.onChanged,
    required this.onPresetChanged,
  });

  static List<Color> _defaultSwatches() => [
        const Color(0xFFEC4899),
        const Color(0xFF2563EB),
        const Color(0xFF16A34A),
        const Color(0xFFF97316),
        const Color(0xFF8B5CF6),
        const Color(0xFFDC2626),
        const Color(0xFF0F172A),
        const Color(0xFFFFFFFF),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.owner_request_palette_title,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ThemePresets.presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final p = ThemePresets.presets[i];
              final selected = p.id == selectedPresetId;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  onPresetChanged(p.id);
                  onChanged(p.draft);
                },
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? cs.primary : cs.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniSwatches(draft: p.draft),
                      const SizedBox(height: 10),
                      Text(
                        p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected
                            ? l.owner_request_selected
                            : l.owner_request_tap_to_apply,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(.6),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _TileRow(
          label: l.owner_request_primary,
          color: draft.primary,
          onTap: () => _showColorPicker(
            context,
            title: l.owner_request_pick_primary,
            start: draft.primary,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(primary: c));
            },
          ),
        ),
        _TileRow(
          label: l.owner_request_secondary,
          color: draft.secondary,
          onTap: () => _showColorPicker(
            context,
            title: l.owner_request_pick_secondary,
            start: draft.secondary,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(secondary: c));
            },
          ),
        ),
        _TileRow(
          label: l.owner_request_background,
          color: draft.background,
          onTap: () => _showColorPicker(
            context,
            title: l.owner_request_pick_background,
            start: draft.background,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(background: c));
            },
          ),
        ),
        _TileRow(
          label: l.owner_request_text_on_background,
          color: draft.onBackground,
          onTap: () => _showColorPicker(
            context,
            title: l.owner_request_pick_text_color,
            start: draft.onBackground,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(onBackground: c));
            },
          ),
        ),
        _TileRow(
          label: l.owner_request_error,
          color: draft.error,
          onTap: () => _showColorPicker(
            context,
            title: l.owner_request_pick_error,
            start: draft.error,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(error: c));
            },
          ),
        ),
        const SizedBox(height: 12),
        _ThemePreview(draft: draft),
      ],
    );
  }

  static Future<void> _showColorPicker(
    BuildContext context, {
    required String title,
    required Color start,
    required ValueChanged<Color> onPicked,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    Color temp = start;
    final hexCtrl = TextEditingController(text: _hex(start));
    String? errorText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final swatches = _defaultSwatches();

            void setFromHex(String v) {
              final parsed = _tryParseHex(v);
              if (parsed == null) {
                setSheet(() => errorText = l.owner_request_err_hex_format);
                return;
              }
              setSheet(() {
                errorText = null;
                temp = parsed;
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: Theme.of(ctx).textTheme.titleMedium),
                        ),
                        Icon(Icons.palette_outlined, color: cs.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.owner_request_quick_colors,
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in swatches)
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setSheet(() {
                                temp = c;
                                hexCtrl.text = _hex(c);
                                errorText = null;
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Theme.of(ctx).colorScheme.outlineVariant,
                                ),
                              ),
                              child: temp.value == c.value
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: c.computeLuminance() > 0.6
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: hexCtrl,
                      decoration: InputDecoration(
                        labelText: l.owner_request_hex_optional,
                        hintText: l.owner_request_hex_hint,
                        errorText: errorText,
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () => setFromHex(hexCtrl.text),
                        ),
                      ),
                      onSubmitted: setFromHex,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: temp,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _hex(temp),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: temp.computeLuminance() > 0.55
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l.cancel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onPicked(temp);
                            },
                            child: Text(l.use),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniSwatches extends StatelessWidget {
  final ThemeDraft draft;
  const _MiniSwatches({required this.draft});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );

    return Row(
      children: [
        dot(draft.primary),
        const SizedBox(width: 6),
        dot(draft.secondary),
        const SizedBox(width: 6),
        dot(draft.background),
        const SizedBox(width: 6),
        dot(draft.onBackground),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.bodyLarge),
              ),
              Container(
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final ThemeDraft draft;
  const _ThemePreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.preview, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: draft.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.apps_rounded, color: _on(draft.primary), size: 18),
                const SizedBox(width: 8),
                Text(
                  l.owner_request_your_app,
                  style: TextStyle(
                    color: _on(draft.primary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.notifications_none_rounded,
                    color: _on(draft.primary), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: draft.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.owner_request_preview_hello_owner,
                  style: TextStyle(
                    color: draft.onBackground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.owner_request_preview_desc,
                  style: TextStyle(color: draft.onBackground.withOpacity(.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _on(Color bg) =>
      bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

/// ===============================================================
/// Helpers (hex)
/// ===============================================================

String _hex(Color c) {
  final r = c.red.toRadixString(16).padLeft(2, '0');
  final g = c.green.toRadixString(16).padLeft(2, '0');
  final b = c.blue.toRadixString(16).padLeft(2, '0');
  return '#${r}${g}${b}'.toUpperCase();
}

Color? _tryParseHex(String hex) {
  try {
    final s = hex.trim();
    if (!s.startsWith('#')) return null;
    final val = int.tryParse(s.substring(1), radix: 16);
    if (val == null) return null;
    return Color(val | 0xFF000000);
  } catch (_) {
    return null;
  }
}
