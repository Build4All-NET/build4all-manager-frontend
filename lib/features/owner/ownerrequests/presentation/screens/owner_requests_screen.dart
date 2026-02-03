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
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/models/currency_model.dart';
import '../../data/services/owner_requests_api.dart';

import '../widgets/preview_phone.dart';
import '../widgets/palette_builder.dart';

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

  late final TextEditingController
      _projectIdCtrl; // hidden in UI but used in submit
  late final TextEditingController _appNameCtrl;
  final _notesCtrl = TextEditingController();

  bool _loading = false;

  List<CurrencyModel> _currencies = [];
  CurrencyModel? _selectedCurrency;

  File? _logoFile;

  // Palette
  String? _selectedPresetId = 'pink_pop';
  ThemeDraft _draft = ThemePresets.byId('pink_pop').draft;

  // Runtime
  RuntimeDraft _runtime = RuntimeDefaults.defaults();

  // UI panel selection (tabs)
  _Panel _panel = _Panel.identity;

  // ✅ Submit enabled ONLY if AppName + Logo
  bool get _canSubmit {
    final appOk = _appNameCtrl.text.trim().isNotEmpty;
    final logoOk = _logoFile != null;
    return !_loading && appOk && logoOk;
  }

  // ✅ Always fallback USD if currency not chosen
  void _ensureUsdSelected() {
    if (_selectedCurrency != null) return;
    if (_currencies.isEmpty) return;

    final usd =
        _currencies.where((c) => c.code.toUpperCase() == 'USD').toList();
    _selectedCurrency = usd.isNotEmpty ? usd.first : _currencies.first;
  }

  @override
  void initState() {
    super.initState();
    api = OwnerRequestApi(dio: widget.dio, baseUrl: widget.baseUrl);

    _projectIdCtrl = TextEditingController(
      text: widget.initialProjectId?.toString() ?? '',
    );
    _appNameCtrl = TextEditingController(text: widget.initialAppName ?? '');

    // ✅ so submit button updates live as user types
    _appNameCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _loadCurrencies();
  }

  @override
  void dispose() {
    _projectIdCtrl.dispose();
    _appNameCtrl.dispose();
    _notesCtrl.dispose();
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

        // ✅ default USD (no need to open dropdown)
        final usd = list.where((c) => c.code.toUpperCase() == 'USD').toList();
        if (usd.isNotEmpty) {
          _selectedCurrency = usd.first;
          return;
        }

        // fallback EUR if USD missing
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
  /// pick logo from gallery
  /// ------------------------------------------------------------
  Future<void> _pickLogo() async {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    final picker = ImagePicker();
    final res = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // keep original, we will re-encode ourselves
    );
    if (res == null) return;

    try {
      final bytes = await res.readAsBytes();

      // decode (handles iOS P3/HDR better after re-encode)
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception("Could not decode image");

      // optional: mild brightness bump if you still feel it’s darker
      // final adjusted = img.adjustColor(decoded, brightness: 1.03);
      final adjusted = decoded;

      // re-encode to PNG (or JPG) => normalizes color profile
      final outBytes = img.encodePng(adjusted);

      final dir = await getTemporaryDirectory();
      final outPath =
          p.join(dir.path, 'logo_${DateTime.now().millisecondsSinceEpoch}.png');
      final outFile = File(outPath);
      await outFile.writeAsBytes(outBytes, flush: true);

      if (!mounted) return;
      setState(() => _logoFile = outFile);

      AppToast.success(context, l.owner_request_logo_selected);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, "Failed to process logo: $e");
    }
  }

  void _removeLogo() {
    if (_loading) return;
    final l = AppLocalizations.of(context)!;

    setState(() => _logoFile = null);
    AppToast.success(context, l.owner_request_logo_removed);
  }

  /// ------------------------------------------------------------
  /// Submit
  /// ------------------------------------------------------------
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context)!;

    // ✅ currency auto-load + auto USD (no dropdown needed)
    if (_currencies.isEmpty) {
      await _loadCurrencies();
    }
    _ensureUsdSelected();

    // ✅ hard requirements: App name + Logo فقط
    if (_appNameCtrl.text.trim().isEmpty) {
      AppToast.error(context, l.owner_request_err_app_name_required);
      return;
    }
    if (_logoFile == null) {
      // you can add a localization key later; for now:
      AppToast.error(context, 'Logo is required. Please upload a logo.');
      return;
    }

    // ✅ keep formKey only for fields that are truly required in UI.
    // Notes are optional so no validator.
    if (!_formKey.currentState!.validate()) {
      AppToast.error(context, l.owner_request_err_fix_fields);
      return;
    }

    // Project ID hidden from UI but backend needs it
    final projectIdStr = _projectIdCtrl.text.trim();
    final projectId = int.tryParse(projectIdStr);
    if (projectId == null || projectId <= 0) {
      AppToast.error(context, l.owner_request_err_valid_number);
      return;
    }

    // Currency must exist (but we default USD)
    if (_selectedCurrency == null) {
      AppToast.error(context, l.owner_request_err_select_currency);
      return;
    }

    setState(() => _loading = true);

    try {
      final primaryHex = hexOf(_draft.primary);
      final secondaryHex = hexOf(_draft.secondary);
      final bgHex = hexOf(_draft.background);
      final onBgHex = hexOf(_draft.onBackground);
      final errorHex = hexOf(_draft.error);

      final out = _runtime.toJsonOut();

      await api.submitOwnerRequest(
        ownerId: widget.ownerId,
        projectId: projectId,
        appName: _appNameCtrl.text.trim(),
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

    final previewSubtitle = l.owner_request_hero_subtitle;

    final appName = _appNameCtrl.text.trim().isEmpty
        ? l.owner_request_app_name_hint
        : _appNameCtrl.text.trim();

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
        enabled: _canSubmit, // ✅ only app name + logo
        onSubmit: _submit,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                context, _currencies);
                            if (picked != null) {
                              setState(() => _selectedCurrency = picked);
                            }
                          },
                          projectIdCtrl: _projectIdCtrl,
                          appNameCtrl: _appNameCtrl,
                          notesCtrl: _notesCtrl,
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
              final hay =
                  '${c.fullLabel} ${c.code} ${c.symbol} ${c.currencyType} ${c.id}'
                      .toLowerCase();
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
                              c.shortLabel,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(c.currencyType),
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
/// ===============================================================
enum _Panel { identity, palette, runtime }

class _CustomizeColumn extends StatelessWidget {
  final TextStyle? titleStyle;
  final bool loading;

  final List<CurrencyModel> currencies;
  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl;
  final TextEditingController appNameCtrl;
  final TextEditingController notesCtrl;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _PillTabs(selected: panel, onChanged: onPanelChanged),
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
                logoFile: logoFile,
                onPickLogo: onPickLogo,
                onRemoveLogo: onRemoveLogo,
              ),
            _Panel.palette => IgnorePointer(
                key: const ValueKey('palette'),
                ignoring: loading,
                child: Opacity(
                  opacity: loading ? .55 : 1,
                  child: _PanelCard(
                    child: PaletteSection(
                      draft: draft,
                      selectedPresetId: presetId,
                      onChanged: onDraftChanged,
                      onPresetChanged: onPresetChanged,
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
                  child: _PanelCard(
                    child: RuntimeSection(
                      draft: runtime,
                      onChanged: onRuntimeChanged,
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

class _PillTabs extends StatelessWidget {
  final _Panel selected;
  final ValueChanged<_Panel> onChanged;

  const _PillTabs({required this.selected, required this.onChanged});

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget tab({
      required _Panel value,
      required String label,
      required IconData icon,
    }) {
      final active = selected == value;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? _green : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? Colors.white : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          tab(
              value: _Panel.identity,
              label: 'Identity',
              icon: Icons.badge_outlined),
          tab(
              value: _Panel.palette,
              label: 'Palette',
              icon: Icons.palette_outlined),
          tab(
              value: _Panel.runtime,
              label: 'Runtime',
              icon: Icons.tune_rounded),
        ],
      ),
    );
  }
}

/// ===============================================================
/// Identity Panel (ONLY AppName required visually + Logo required by submit)
/// Currency always shows USD fallback even if not opened
/// ===============================================================
class _IdentityPanel extends StatelessWidget {
  final bool loading;

  final CurrencyModel? selectedCurrency;
  final VoidCallback onPickCurrency;

  final TextEditingController projectIdCtrl;
  final TextEditingController appNameCtrl;
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
    required this.notesCtrl,
    required this.logoFile,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = cs.onSurface.withOpacity(.45);

    return _PanelCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              borderSide:
                  const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name (required)
            Text(
              'App name',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: appNameCtrl,
              enabled: !loading,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.apps_rounded, size: 18, color: hint),
                hintText: 'My Shop',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 14),

            // Logo (required but handled by submit button logic)
            Text(
              'App Logo *',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: logoFile == null
                      ? Icon(Icons.image_outlined, color: hint)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(logoFile!, fit: BoxFit.cover),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      // ✅ Upload button stays enabled unless loading
                      onPressed: loading ? null : onPickLogo,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Upload',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                if (logoFile != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: loading ? null : onRemoveLogo,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    tooltip: 'Remove',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // Currency (NOT required; always shows USD fallback)
            Text(
              'Select currency',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: loading ? null : onPickCurrency,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 18, color: hint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedCurrency == null
                            ? 'USD (\$)'
                            : selectedCurrency!.shortLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.search_rounded, color: hint, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Notes optional
            Text(
              'Notes',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: notesCtrl,
              enabled: !loading,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any additional notes...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// Submit bar (disabled unless AppName + Logo)
/// ===============================================================
class _SubmitBar extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.loading,
    required this.enabled,
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
                    enabled ? 'Ready to submit ✅' : 'App name + logo required',
                    style: t.bodySmall
                        ?.copyWith(color: cs.onSurface.withOpacity(.65)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: (!enabled || loading) ? null : onSubmit,
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
                    borderRadius: BorderRadius.circular(14)),
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

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
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
                style:
                    t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
