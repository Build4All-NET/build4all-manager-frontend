// lib/features/owner/ownerrequests/presentation/screens/owner_requests_screen.dart

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

import '../widgets/preview_phone.dart';
import '../widgets/palette_builder.dart';

/// ===============================================================
/// OwnerRequestScreen
///
/// ✅ FIGMA "Preview & Customize" design approach:
/// - Left/Top: Live phone preview (updates instantly)
/// - Right/Bottom: App Settings tabs (App Identity / Palette / Runtime Config / Branding)
/// - Pinned submit bar at bottom
///
/// Notes:
/// - Backend contract remains the same.
/// - UI is updated to match Figma behavior.
/// - Project ID is hidden (still used internally for submission).
/// ===============================================================
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

  // Form key used for text fields validation (App name + Notes etc.)
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _projectIdCtrl; // hidden in UI (still used)
  late final TextEditingController _appNameCtrl;
  final _notesCtrl = TextEditingController();
  final _apiOverrideCtrl = TextEditingController();

  // Screen loading state (prevents multiple submits / actions)
  bool _loading = false;

  // Currency list
  List<CurrencyModel> _currencies = [];
  CurrencyModel? _selectedCurrency;

  // Branding
  File? _logoFile;

  // Palette
  String? _selectedPresetId = 'pink_pop';
  ThemeDraft _draft = ThemePresets.byId('pink_pop').draft;

  // Runtime config
  RuntimeDraft _runtime = RuntimeDefaults.defaults();

  // UI tab selection
  _Panel _panel = _Panel.identity;

  @override
  void initState() {
    super.initState();
    api = OwnerRequestApi(dio: widget.dio, baseUrl: widget.baseUrl);

    // Keep project id (hidden field) for submission.
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

  /// --------------------------------------------------------------
  /// Load currencies from backend
  /// --------------------------------------------------------------
  Future<void> _loadCurrencies() async {
    final l = AppLocalizations.of(context)!;
    try {
      final list = await api.fetchCurrencies();
      if (!mounted) return;
      setState(() {
        _currencies = list;

        // Default preference: EUR (if exists), otherwise first available
        final eur = list.where((c) => c.code.toUpperCase() == 'EUR').toList();
        _selectedCurrency =
            eur.isNotEmpty ? eur.first : (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l.owner_request_err_load_currencies);
    }
  }

  /// --------------------------------------------------------------
  /// Pick logo image from gallery
  /// --------------------------------------------------------------
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

  /// --------------------------------------------------------------
  /// Remove logo
  /// --------------------------------------------------------------
  void _removeLogo() {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    setState(() => _logoFile = null);
    AppToast.success(context, l.owner_request_logo_removed);
  }

  /// --------------------------------------------------------------
  /// Validator helper
  /// --------------------------------------------------------------
  String? _validateInt(String? v) {
    final l = AppLocalizations.of(context)!;
    final s = (v ?? '').trim();
    if (s.isEmpty) return l.err_required;
    final n = int.tryParse(s);
    if (n == null || n <= 0) return l.owner_request_err_valid_number;
    return null;
  }

  /// --------------------------------------------------------------
  /// Submit owner request
  /// --------------------------------------------------------------
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context)!;

    // Must pick currency
    if (_selectedCurrency == null) {
      AppToast.error(context, l.owner_request_err_select_currency);
      return;
    }

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      AppToast.error(context, l.owner_request_err_fix_fields);
      return;
    }

    // Project id (hidden) must exist
    final projectIdText = _projectIdCtrl.text.trim();
    final projectId = int.tryParse(projectIdText);
    if (projectId == null || projectId <= 0) {
      AppToast.error(context, l.owner_request_err_valid_number);
      return;
    }

    // App name must exist
    final appName = _appNameCtrl.text.trim();
    if (appName.isEmpty) {
      AppToast.error(context, l.owner_request_err_app_name_required);
      return;
    }

    setState(() => _loading = true);

    try {
      // Theme colors (hex strings)
      final primaryHex = _hexOf(_draft.primary);
      final secondaryHex = _hexOf(_draft.secondary);
      final bgHex = _hexOf(_draft.background);
      final onBgHex = _hexOf(_draft.onBackground);
      final errorHex = _hexOf(_draft.error);

      // Runtime JSON output (nav/home/features/branding)
      final out = _runtime.toJsonOut();

      // Submit request (backend contract unchanged)
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

      // Optionally switch nav index after success
      try {
        context.read<OwnerNavCubit>().setIndex(1);
      } catch (_) {}

      // Close screen returning success
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      String msg = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          msg = data['error'].toString();
        } else if (data is String && data.isNotEmpty) {
          msg = data;
        }
      }

      AppToast.error(context, l.owner_request_submit_failed(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    // ✅ Use existing keys to avoid missing localization getters
    final previewSubtitle = l.owner_request_hero_subtitle;

    // Preview app name:
    // - If empty: show hint (safe existing key)
    // - If filled: show exact value
    final appNameForPreview = _appNameCtrl.text.trim().isEmpty
        ? l.owner_request_app_name_hint
        : _appNameCtrl.text.trim();

    // Runtime output for preview
    final previewOut = _runtime.toJsonOut();

    return Scaffold(
      backgroundColor: cs.background,
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
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Wide layout: Preview left, Settings right (like Figma desktop)
              final isWide = constraints.maxWidth >= 980;

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Preview
                      Expanded(
                        flex: 4,
                        child: _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeaderRow(
                                title: l.preview,
                                subtitle: previewSubtitle,
                                icon: Icons.remove_red_eye_outlined,
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: PhonePreview(
                                  appName: appNameForPreview,
                                  draft: _draft,
                                  logoFile: _logoFile,
                                  currency: _selectedCurrency,
                                  navJson: previewOut.navJson,
                                  homeJson: previewOut.homeJson,
                                  enabledFeaturesJson:
                                      previewOut.enabledFeaturesJson,
                                  brandingJson: previewOut.brandingJson,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // RIGHT: App Settings
                      Expanded(
                        flex: 5,
                        child: _CustomizeColumn(
                          titleStyle: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                          loading: _loading,
                          currencies: _currencies,
                          selectedCurrency: _selectedCurrency,
                          onPickCurrency: () async {
                            if (_currencies.isEmpty) await _loadCurrencies();
                            if (!mounted) return;
                            final picked = await _showCurrencySearchSheet(
                              context,
                              _currencies,
                            );
                            if (picked != null) {
                              setState(() => _selectedCurrency = picked);
                            }
                          },
                          projectIdCtrl: _projectIdCtrl,
                          appNameCtrl: _appNameCtrl,
                          notesCtrl: _notesCtrl,
                          apiOverrideCtrl: _apiOverrideCtrl,
                          validateInt: _validateInt, // ✅ REQUIRED
                          presetId: _selectedPresetId,
                          draft: _draft,
                          runtime: _runtime,
                          logoFile: _logoFile,
                          onPresetChanged: (id) =>
                              setState(() => _selectedPresetId = id),
                          onDraftChanged: (d) => setState(() => _draft = d),
                          onRuntimeChanged: (d) => setState(() => _runtime = d),
                          onPickLogo: _pickLogo,
                          onRemoveLogo: _removeLogo,
                          panel: _panel,
                          onPanelChanged: (p) => setState(() => _panel = p),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Mobile layout: Preview on top, Settings below (scroll)
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderRow(
                          title: l.preview,
                          subtitle: previewSubtitle,
                          icon: Icons.remove_red_eye_outlined,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: PhonePreview(
                            appName: appNameForPreview,
                            draft: _draft,
                            logoFile: _logoFile,
                            currency: _selectedCurrency,
                            navJson: previewOut.navJson,
                            homeJson: previewOut.homeJson,
                            enabledFeaturesJson: previewOut.enabledFeaturesJson,
                            brandingJson: previewOut.brandingJson,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CustomizeColumn(
                    titleStyle:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    loading: _loading,
                    currencies: _currencies,
                    selectedCurrency: _selectedCurrency,
                    onPickCurrency: () async {
                      if (_currencies.isEmpty) await _loadCurrencies();
                      if (!mounted) return;
                      final picked =
                          await _showCurrencySearchSheet(context, _currencies);
                      if (picked != null) {
                        setState(() => _selectedCurrency = picked);
                      }
                    },
                    projectIdCtrl: _projectIdCtrl,
                    appNameCtrl: _appNameCtrl,
                    notesCtrl: _notesCtrl,
                    apiOverrideCtrl: _apiOverrideCtrl,
                    validateInt: _validateInt, // ✅ REQUIRED
                    presetId: _selectedPresetId,
                    draft: _draft,
                    runtime: _runtime,
                    logoFile: _logoFile,
                    onPresetChanged: (id) =>
                        setState(() => _selectedPresetId = id),
                    onDraftChanged: (d) => setState(() => _draft = d),
                    onRuntimeChanged: (d) => setState(() => _runtime = d),
                    onPickLogo: _pickLogo,
                    onRemoveLogo: _removeLogo,
                    panel: _panel,
                    onPanelChanged: (p) => setState(() => _panel = p),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Currency bottom sheet (search + pick)
  // ==========================================================
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              c.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('${c.code} • id=${c.id}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
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

/// ===============================================================
/// App Settings tabs (Figma-like)
///
/// Requested order:
/// 1) App Identity
/// 2) Palette
/// 3) Runtime Config
/// 4) Branding
/// ===============================================================
enum _Panel { identity, palette, runtime, branding }

class _CustomizeColumn extends StatelessWidget {
  final TextStyle? titleStyle;

  final bool loading;

  final List<CurrencyModel> currencies;
  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl; // hidden (kept for submission)
  final TextEditingController appNameCtrl;
  final TextEditingController notesCtrl;
  final TextEditingController apiOverrideCtrl;

  final String? Function(String?) validateInt;

  final String? presetId;
  final ThemeDraft draft;
  final RuntimeDraft runtime;

  final File? logoFile;

  final ValueChanged<String?> onPresetChanged;
  final ValueChanged<ThemeDraft> onDraftChanged;
  final ValueChanged<RuntimeDraft> onRuntimeChanged;

  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  final _Panel panel;
  final ValueChanged<_Panel> onPanelChanged;

  const _CustomizeColumn({
    required this.titleStyle,
    required this.loading,
    required this.currencies,
    required this.selectedCurrency,
    required this.onPickCurrency,
    required this.projectIdCtrl,
    required this.appNameCtrl,
    required this.notesCtrl,
    required this.apiOverrideCtrl,
    required this.validateInt,
    required this.presetId,
    required this.draft,
    required this.runtime,
    required this.logoFile,
    required this.onPresetChanged,
    required this.onDraftChanged,
    required this.onRuntimeChanged,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.panel,
    required this.onPanelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Existing localization key (safe)
    final settingsTitle = l.owner_request_settings_title;

    // Requested labels (explicit)
    const tabAppIdentity = 'App Identity';
    const tabPalette = 'Palette';
    const tabRuntime = 'Runtime Config';
    const tabBranding = 'Branding';

    // Smaller + cleaner segmented style
    final segTheme = SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        textStyle: MaterialStateProperty.all(
          t.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        side: MaterialStateProperty.all(BorderSide(color: cs.outlineVariant)),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return cs.primary;
          return cs.surface;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return cs.onPrimary;
          return cs.onSurface.withOpacity(.80);
        }),
        overlayColor: MaterialStateProperty.all(cs.primary.withOpacity(.08)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(settingsTitle, style: titleStyle),
        const SizedBox(height: 10),

        Theme(
          data: Theme.of(context).copyWith(segmentedButtonTheme: segTheme),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: SegmentedButton<_Panel>(
              segments: const [
                ButtonSegment(value: _Panel.identity, label: Text(tabAppIdentity)),
                ButtonSegment(value: _Panel.palette, label: Text(tabPalette)),
                ButtonSegment(value: _Panel.runtime, label: Text(tabRuntime)),
                ButtonSegment(value: _Panel.branding, label: Text(tabBranding)),
              ],
              selected: {panel},
              showSelectedIcon: false,
              onSelectionChanged:
                  loading ? null : (set) => onPanelChanged(set.first),
            ),
          ),
        ),

        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (panel) {
            _Panel.identity => _IdentityPanel(
                key: const ValueKey('identity'),
                loading: loading,
                selectedCurrency: selectedCurrency,
                onPickCurrency: onPickCurrency,
                projectIdCtrl: projectIdCtrl,
                appNameCtrl: appNameCtrl,
                notesCtrl: notesCtrl,
                apiOverrideCtrl: apiOverrideCtrl,
                validateInt: validateInt,
              ),

            _Panel.palette => IgnorePointer(
                key: const ValueKey('palette'),
                ignoring: loading,
                child: Opacity(
                  opacity: loading ? .55 : 1,
                  child: _Card(
                    child: PaletteSection(
                      draft: draft,
                      selectedPresetId: presetId,
                      onChanged: onDraftChanged,
                      onPresetChanged: onPresetChanged,
                    ),
                  ),
                ),
              ),

            _Panel.runtime => IgnorePointer(
                key: const ValueKey('runtime'),
                ignoring: loading,
                child: Opacity(
                  opacity: loading ? .55 : 1,
                  child: _Card(
                    child: RuntimeSection(
                      draft: runtime,
                      onChanged: onRuntimeChanged,
                    ),
                  ),
                ),
              ),

            _Panel.branding => _Card(
                key: const ValueKey('branding'),
                child: _BrandingPanel(
                  loading: loading,
                  logoFile: logoFile,
                  onPickLogo: onPickLogo,
                  onRemoveLogo: onRemoveLogo,
                ),
              ),
          },
        ),
      ],
    );
  }
}

/// ===============================================================
/// App Identity panel
///
/// ✅ Renamed from "Basics" to "App Identity"
/// ✅ Project ID is hidden (still stored in controller for submission)
/// ===============================================================
class _IdentityPanel extends StatelessWidget {
  final bool loading;

  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl; // hidden
  final TextEditingController appNameCtrl;
  final TextEditingController notesCtrl;
  final TextEditingController apiOverrideCtrl;

  final String? Function(String?) validateInt;

  const _IdentityPanel({
    super.key,
    required this.loading,
    required this.selectedCurrency,
    required this.onPickCurrency,
    required this.projectIdCtrl,
    required this.appNameCtrl,
    required this.notesCtrl,
    required this.apiOverrideCtrl,
    required this.validateInt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            title: 'App Identity',
            subtitle: l.owner_request_basics_subtitle,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),

          // ✅ Project ID is hidden by request.
          // We still keep projectIdCtrl value for submission.
          // If you ever need it for debugging, you can temporarily show it again.
          const SizedBox.shrink(),

          // App name
          _FieldWrap(
            enabled: !loading,
            child: TextFormField(
              controller: appNameCtrl,
              decoration: InputDecoration(
                labelText: l.owner_request_app_name,
                hintText: l.owner_request_app_name_hint,
                prefixIcon: const Icon(Icons.apps_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.err_required : null,
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          _FieldWrap(
            enabled: !loading,
            child: TextFormField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.owner_request_notes,
                hintText: l.owner_request_notes_hint,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.err_required : null,
            ),
          ),
          const SizedBox(height: 12),

          // Currency picker
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: loading ? null : onPickCurrency,
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
                    child: Text(
                      selectedCurrency?.label ?? l.owner_request_select_currency,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // API override
          _FieldWrap(
            enabled: !loading,
            child: TextFormField(
              controller: apiOverrideCtrl,
              decoration: InputDecoration(
                labelText: l.owner_request_api_override,
                hintText: l.owner_request_api_override_hint,
                prefixIcon: const Icon(Icons.link_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// Branding panel (logo upload/remove)
/// ===============================================================
class _BrandingPanel extends StatelessWidget {
  final bool loading;
  final File? logoFile;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  const _BrandingPanel({
    required this.loading,
    required this.logoFile,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(
          title: l.owner_request_branding_title,
          subtitle: l.owner_request_branding_subtitle,
          icon: Icons.image_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: logoFile == null
                  ? Icon(Icons.image_outlined, color: cs.onSurfaceVariant)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(logoFile!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                logoFile == null
                    ? l.owner_request_no_logo
                    : logoFile!.path.split(Platform.pathSeparator).last,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            if (logoFile != null)
              IconButton(
                tooltip: l.common_remove,
                onPressed: loading ? null : onRemoveLogo,
                icon: const Icon(Icons.delete_outline),
              ),
            OutlinedButton.icon(
              onPressed: loading ? null : onPickLogo,
              icon: const Icon(Icons.upload_rounded),
              label: Text(l.owner_request_pick_logo),
            ),
          ],
        ),
      ],
    );
  }
}

/// ===============================================================
/// Pinned submit bar
/// ===============================================================
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
/// Small UI helpers
/// ===============================================================
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderRow({
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
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _FieldWrap({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.60,
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
/// Helpers (hex)
/// ===============================================================
/// Converts a Flutter [Color] to "#RRGGBB" (uppercase) without alpha.
String _hexOf(Color c) {
  final r = c.red.toRadixString(16).padLeft(2, '0');
  final g = c.green.toRadixString(16).padLeft(2, '0');
  final b = c.blue.toRadixString(16).padLeft(2, '0');
  return '#${r}${g}${b}'.toUpperCase();
}
