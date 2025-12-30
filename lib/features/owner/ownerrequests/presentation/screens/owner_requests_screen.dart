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
/// OwnerRequestScreen (FIGMA-STYLE "Preview & Customize")
///
/// Layout:
/// - Wide: left = live phone preview, right = customize panels
/// - Mobile: preview first, then customize panels
///
/// Tabs:
/// ✅ App Identity
/// ✅ Palette
/// ✅ Runtime Config
///
/// USER REQUESTS IMPLEMENTED:
/// ✅ Branding tab removed (no longer exists)
/// ✅ App Identity:
///    - Project ID hidden (still required & submitted)
///    - App Logo added inside App Identity after App Name
///    - Notes moved to the END (after API Base URL) and NOT mandatory
/// ✅ Palette:
///    - Remove bottom internal preview section ("Your App / Hello owner...")
///      via PaletteSection(showPreview: false)
/// ✅ Runtime Config:
///    - Blue accent styling
///    - Menu Type + Enabled Features + Home Sections DO affect preview mobile
///      (we pass runtime JSON to PhonePreview)
///
/// IMPORTANT:
/// - White page / RenderBox errors usually happen when a large Column is placed
///   inside a constrained area without scrolling.
///   ✅ Fix: Right side customize area is wrapped in SingleChildScrollView (wide layout).
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

  final _formKey = GlobalKey<FormState>();

  // Project ID is hidden from UI but required for submit.
  late final TextEditingController _projectIdCtrl;

  late final TextEditingController _appNameCtrl;

  // Notes is optional (not mandatory)
  final _notesCtrl = TextEditingController();

  // Optional API base URL override
  final _apiOverrideCtrl = TextEditingController();

  bool _loading = false;

  List<CurrencyModel> _currencies = [];
  CurrencyModel? _selectedCurrency;

  // App Logo (moved into App Identity)
  File? _logoFile;

  // Palette
  String? _selectedPresetId = 'pink_pop';
  ThemeDraft _draft = ThemePresets.byId('pink_pop').draft;

  // Runtime Config
  RuntimeDraft _runtime = RuntimeDefaults.defaults();

  // Tabs / Panels
  _Panel _panel = _Panel.identity;

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

  /// ------------------------------------------------------------
  /// Loads currencies from backend
  /// ------------------------------------------------------------
  Future<void> _loadCurrencies() async {
    final l = AppLocalizations.of(context)!;
    try {
      final list = await api.fetchCurrencies();
      if (!mounted) return;

      setState(() {
        _currencies = list;

        // Prefer EUR by default
        final eur = list.where((c) => c.code.toUpperCase() == 'EUR').toList();
        _selectedCurrency =
            eur.isNotEmpty ? eur.first : (list.isNotEmpty ? list.first : null);
      });
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l.owner_request_err_load_currencies);
    }
  }

  /// ------------------------------------------------------------
  /// App Logo: pick from gallery
  /// ------------------------------------------------------------
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

  /// ------------------------------------------------------------
  /// App Logo: remove selected
  /// ------------------------------------------------------------
  void _removeLogo() {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    setState(() => _logoFile = null);
    AppToast.success(context, l.owner_request_logo_removed);
  }

  /// ------------------------------------------------------------
  /// Validation helper for integer
  /// ------------------------------------------------------------
  String? _validateInt(String? v) {
    final l = AppLocalizations.of(context)!;

    final s = (v ?? '').trim();
    if (s.isEmpty) return l.err_required;
    final n = int.tryParse(s);
    if (n == null || n <= 0) return l.owner_request_err_valid_number;
    return null;
  }

  /// ------------------------------------------------------------
  /// Submit (same backend contract)
  /// ------------------------------------------------------------
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

    // Project ID is hidden, but still required.
    final projectIdStr = _projectIdCtrl.text.trim();
    final projectId = int.tryParse(projectIdStr);
    if (projectId == null || projectId <= 0) {
      AppToast.error(context, l.owner_request_err_valid_number);
      return;
    }

    final appName = _appNameCtrl.text.trim();
    if (appName.isEmpty) {
      AppToast.error(context, l.owner_request_err_app_name_required);
      return;
    }

    setState(() => _loading = true);

    try {
      // Colors sent to backend
      final primaryHex = hexOf(_draft.primary);
      final secondaryHex = hexOf(_draft.secondary);
      final bgHex = hexOf(_draft.background);
      final onBgHex = hexOf(_draft.onBackground);
      final errorHex = hexOf(_draft.error);

      // Runtime JSON payloads submitted to backend
      final out = _runtime.toJsonOut();

      await api.submitOwnerRequest(
        ownerId: widget.ownerId,
        projectId: projectId,
        appName: appName,

        // ✅ Notes optional (can be empty)
        notes: _notesCtrl.text.trim(),

        primaryColor: primaryHex,
        secondaryColor: secondaryHex,
        backgroundColor: bgHex,
        onBackgroundColor: onBgHex,
        errorColor: errorHex,

        currencyId: _selectedCurrency!.id,

        // ✅ runtime submitted as-is
        navJson: out.navJson,
        homeJson: out.homeJson,
        enabledFeaturesJson: out.enabledFeaturesJson,
        brandingJson: out.brandingJson,

        apiBaseUrlOverride: _apiOverrideCtrl.text.trim().isEmpty
            ? null
            : _apiOverrideCtrl.text.trim(),

        // ✅ App Logo still submitted
        logoFile: _logoFile,
      );

      if (!mounted) return;

      AppToast.success(context, l.owner_request_submit_success);

      // Navigate back or update owner nav
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
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final previewSubtitle = l.owner_request_hero_subtitle;

    // App name placeholder in preview
    final appName = _appNameCtrl.text.trim().isEmpty
        ? l.owner_request_app_name_hint
        : _appNameCtrl.text.trim();

    // ✅ Runtime affects preview now
    final previewOut = _runtime.toJsonOut();

    // Keep branding/logo decision as you prefer:
    // - If you want logo to affect preview, set previewLogoFile = _logoFile
    // - If you want logo NOT affect preview, keep it null
    final File? previewLogoFile = _logoFile;

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
              final isWide = constraints.maxWidth >= 980;

              // =========================================================
              // WIDE LAYOUT: Preview left, Customize right
              // =========================================================
              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Preview phone
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
                              const SizedBox(height: 12),
                              Center(
                                child: PhonePreview(
                                  appName: appName,
                                  draft: _draft,
                                  logoFile: previewLogoFile,
                                  currency: _selectedCurrency,

                                  // ✅ Runtime affects preview
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

                      // RIGHT: Customize panels (must be scrollable to avoid white page)
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 20),
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
                                // ignore: use_build_context_synchronously
                                setState(() => _selectedCurrency = picked);
                              }
                            },
                            projectIdCtrl: _projectIdCtrl,
                            appNameCtrl: _appNameCtrl,
                            notesCtrl: _notesCtrl,
                            apiOverrideCtrl: _apiOverrideCtrl,
                            validateInt: _validateInt,
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
                      ),
                    ],
                  ),
                );
              }

              // =========================================================
              // MOBILE LAYOUT: Preview then Customize (ListView scroll)
              // =========================================================
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
                        const SizedBox(height: 12),
                        Center(
                          child: PhonePreview(
                            appName: appName,
                            draft: _draft,
                            logoFile: previewLogoFile,
                            currency: _selectedCurrency,

                            // ✅ Runtime affects preview
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
                        // ignore: use_build_context_synchronously
                        setState(() => _selectedCurrency = picked);
                      }
                    },
                    projectIdCtrl: _projectIdCtrl,
                    appNameCtrl: _appNameCtrl,
                    notesCtrl: _notesCtrl,
                    apiOverrideCtrl: _apiOverrideCtrl,
                    validateInt: _validateInt,
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

  /// ==========================================================
  /// Currency bottom sheet (search + pick)
  /// ==========================================================
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
/// Tabs / Panels
/// ✅ Branding removed
/// ===============================================================
enum _Panel { identity, palette, runtime }

class _CustomizeColumn extends StatelessWidget {
  final TextStyle? titleStyle;

  final bool loading;

  final List<CurrencyModel> currencies;
  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl; // hidden
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
    super.key,
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

    final customizeTitle = l.owner_request_settings_title;

    const tabIdentity = 'App Identity';
    const tabPalette = 'Palette';
    const tabRuntime = 'Runtime Config';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(customizeTitle, style: titleStyle),
        const SizedBox(height: 8),

        /// ✅ Compact tabs
        Theme(
          data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
          child: SegmentedButton<_Panel>(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(
                value: _Panel.identity,
                label: Text(
                  tabIdentity,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              ButtonSegment(
                value: _Panel.palette,
                label: Text(
                  tabPalette,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              ButtonSegment(
                value: _Panel.runtime,
                label: Text(
                  tabRuntime,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            selected: {panel},
            onSelectionChanged: (set) => onPanelChanged(set.first),
          ),
        ),
        const SizedBox(height: 10),

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
                apiOverrideCtrl: apiOverrideCtrl,
                notesCtrl: notesCtrl,
                logoFile: logoFile,
                onPickLogo: onPickLogo,
                onRemoveLogo: onRemoveLogo,
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

                      // ✅ remove bottom preview block
                      showPreview: false,
                    ),
                  ),
                ),
              ),

            _Panel.runtime => IgnorePointer(
                key: const ValueKey('runtime'),
                ignoring: loading,
                child: Opacity(
                  opacity: loading ? .55 : 1,
                  child: _BlueAccentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderRow(
                          title: 'Runtime Config',
                          subtitle: l.owner_request_runtime_subtitle,
                          icon: Icons.tune_rounded,
                          forceIconColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 10),
                        RuntimeSection(
                          draft: runtime,
                          onChanged: onRuntimeChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          },
        ),
      ],
    );
  }
}

/// ===============================================================
/// App Identity Panel
///
/// ✅ Project ID hidden
/// ✅ App Logo added after App Name
/// ✅ Notes moved after API Base URL and NOT mandatory
/// ===============================================================
class _IdentityPanel extends StatelessWidget {
  final bool loading;

  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl; // hidden
  final TextEditingController appNameCtrl;
  final TextEditingController apiOverrideCtrl;
  final TextEditingController notesCtrl;

  final File? logoFile;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  const _IdentityPanel({
    super.key,
    required this.loading,
    required this.selectedCurrency,
    required this.onPickCurrency,
    required this.projectIdCtrl,
    required this.appNameCtrl,
    required this.apiOverrideCtrl,
    required this.notesCtrl,
    required this.logoFile,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final labelStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13);

    return _Card(
      child: Theme(
        data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              title: 'App Identity',
              subtitle: l.owner_request_basics_subtitle,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 10),

            // Project ID hidden (still used on submit)
            // (keep controller; no UI field)

            // App Name (mandatory)
            _FieldWrap(
              enabled: !loading,
              child: TextFormField(
                controller: appNameCtrl,
                style: labelStyle,
                decoration: InputDecoration(
                  labelText: l.owner_request_app_name,
                  hintText: l.owner_request_app_name_hint,
                  prefixIcon: const Icon(Icons.apps_rounded, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.err_required : null,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ App Logo right after App Name
            _AppLogoRow(
              loading: loading,
              logoFile: logoFile,
              onPick: onPickLogo,
              onRemove: onRemoveLogo,
            ),
            const SizedBox(height: 10),

            // Currency picker (mandatory by submit check)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: loading ? null : onPickCurrency,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedCurrency?.label ??
                            l.owner_request_select_currency,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.search_rounded,
                        color: cs.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // API base URL override (optional)
            _FieldWrap(
              enabled: !loading,
              child: TextFormField(
                controller: apiOverrideCtrl,
                style: labelStyle,
                decoration: InputDecoration(
                  labelText: l.owner_request_api_override,
                  hintText: l.owner_request_api_override_hint,
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Notes moved to the end, and NOT mandatory (no validator)
            _FieldWrap(
              enabled: !loading,
              child: TextFormField(
                controller: notesCtrl,
                maxLines: 3,
                style: labelStyle,
                decoration: InputDecoration(
                  labelText: l.owner_request_notes,
                  hintText: l.owner_request_notes_hint,
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                ),
                // no validator -> optional
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLogoRow extends StatelessWidget {
  final bool loading;
  final File? logoFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _AppLogoRow({
    required this.loading,
    required this.logoFile,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              logoFile == null
                  ? 'App Logo'
                  : logoFile!.path.split(Platform.pathSeparator).last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          if (logoFile != null)
            IconButton(
              tooltip: l.common_remove,
              onPressed: loading ? null : onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          OutlinedButton.icon(
            onPressed: loading ? null : onPick,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: Text('Upload', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
/// UI helpers
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

/// ✅ Runtime uses a blue accent stripe card
class _BlueAccentCard extends StatelessWidget {
  final Widget child;
  const _BlueAccentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const blue = Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: blue.withOpacity(.9), width: 5),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  final Color? forceIconColor;

  const _HeaderRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.forceIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final iconColor = forceIconColor ?? cs.primary;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 20),
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
                      isDense: true,
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
/// Color helper
/// (kept here to avoid "hexOf isn't defined" errors)
/// ===============================================================
String hexOf(Color c) {
  final r = c.red.toRadixString(16).padLeft(2, '0');
  final g = c.green.toRadixString(16).padLeft(2, '0');
  final b = c.blue.toRadixString(16).padLeft(2, '0');
  return '#${r}${g}${b}'.toUpperCase();
}
