import 'dart:convert';
import 'dart:io';

import 'package:build4all_manager/features/owner/ownerrequests/data/models/currency_model.dart';
import 'package:build4all_manager/features/owner/ownerrequests/data/services/owner_requests_api.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class OwnerRequestScreen extends StatefulWidget {
  final String baseUrl; // ex: http://192.168.1.3:8080
  const OwnerRequestScreen({super.key, required this.baseUrl});

  @override
  State<OwnerRequestScreen> createState() => _OwnerRequestScreenState();
}

class _OwnerRequestScreenState extends State<OwnerRequestScreen> {
  late final OwnerRequestApi api;

  // Controllers
  final _formKey = GlobalKey<FormState>();

  final _notesCtrl = TextEditingController();

  final _primaryCtrl = TextEditingController(text: '#EC4899');
  final _secondaryCtrl = TextEditingController(text: '#111827');
  final _bgCtrl = TextEditingController(text: '#FFFFFF');
  final _onBgCtrl = TextEditingController(text: '#374151');
  final _errorCtrl = TextEditingController(text: '#DC2626');

  final _apiOverrideCtrl = TextEditingController();

  final _navCtrl = TextEditingController(
    text: jsonEncode([
      {"id": "home", "label": "Home", "icon": "home"},
      {"id": "explore", "label": "Explore", "icon": "search"},
      {"id": "cart", "label": "Cart", "icon": "shopping_cart"},
      {"id": "profile", "label": "Profile", "icon": "person"},
    ]),
  );

  final _homeCtrl = TextEditingController(
    text: jsonEncode({
      "sections": [
        {"id": "header", "type": "HEADER", "layout": "full", "limit": 1},
        {"id": "search", "type": "SEARCH", "layout": "full", "limit": 1},
        {"id": "hero_banner", "type": "BANNER", "layout": "full", "limit": 1},
        {
          "id": "categories",
          "type": "CATEGORY_CHIPS",
          "layout": "horizontal",
          "limit": 10
        },
        {
          "id": "flash_sale",
          "type": "ITEM_LIST",
          "feature": "ITEMS",
          "layout": "horizontal",
          "limit": 10
        },
      ]
    }),
  );

  final _featuresCtrl = TextEditingController(
    text: jsonEncode(["ITEMS", "BOOKING", "REVIEWS", "ORDERS"]),
  );

  final _brandingCtrl = TextEditingController(
    text: jsonEncode({"splashColor": "#FFFFFF"}),
  );

  // State
  bool _loading = false;
  String? _error;
  String? _success;

  List<CurrencyModel> _currencies = [];
  CurrencyModel? _selectedCurrency;

  File? _logoFile;

  @override
  void initState() {
    super.initState();
    api = OwnerRequestApi(
      dio: Dio(BaseOptions(connectTimeout: const Duration(seconds: 15))),
      baseUrl: widget.baseUrl,
    );
    _loadCurrencies();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    _bgCtrl.dispose();
    _onBgCtrl.dispose();
    _errorCtrl.dispose();
    _apiOverrideCtrl.dispose();
    _navCtrl.dispose();
    _homeCtrl.dispose();
    _featuresCtrl.dispose();
    _brandingCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _error = null;
      _success = null;
    });

    try {
      final list = await api.fetchCurrencies();
      setState(() {
        _currencies = list;
        // default select: EUR if exists else first
        _selectedCurrency =
            list.where((c) => c.code.toUpperCase() == 'EUR').isNotEmpty
                ? list.firstWhere((c) => c.code.toUpperCase() == 'EUR')
                : (list.isNotEmpty ? list.first : null);
      });
    } catch (e) {
      setState(() => _error = 'Failed to load currencies: $e');
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final res =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (res == null) return;
    setState(() {
      _logoFile = File(res.path);
      _success = null;
      _error = null;
    });
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _success = null;
      _error = null;
    });
  }

  // ---------- validation helpers ----------
  String? _validateHex(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final ok = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(s);
    if (!ok) return 'Use hex like #RRGGBB (or #AARRGGBB)';
    return null;
  }

  String? _validateJson(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    try {
      jsonDecode(s);
      return null;
    } catch (_) {
      return 'Invalid JSON (fix brackets/quotes)';
    }
  }

  Color _hexToColor(String hex, {Color fallback = Colors.transparent}) {
    try {
      var h = hex.trim().replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      final val = int.parse(h, radix: 16);
      return Color(val);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _success = null;
    });

    if (_selectedCurrency == null) {
      setState(() => _error = 'Select a currency first');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Fix the highlighted fields first');
      return;
    }

    setState(() => _loading = true);

    try {
      await api.submitOwnerRequest(
        // themeId: null, // keep null unless you enable it
        notes: _notesCtrl.text.trim(),
        primaryColor: _primaryCtrl.text.trim(),
        secondaryColor: _secondaryCtrl.text.trim(),
        backgroundColor: _bgCtrl.text.trim(),
        onBackgroundColor: _onBgCtrl.text.trim(),
        errorColor: _errorCtrl.text.trim(),
        currencyId: _selectedCurrency!.id,
        navJson: _navCtrl.text.trim(),
        homeJson: _homeCtrl.text.trim(),
        enabledFeaturesJson: _featuresCtrl.text.trim(),
        brandingJson: _brandingCtrl.text.trim(),
        apiBaseUrlOverride: _apiOverrideCtrl.text.trim().isEmpty
            ? null
            : _apiOverrideCtrl.text.trim(),
        logoFile: _logoFile,
      );

      setState(() {
        _success = 'Request submitted ✅ (backend will base64 the JSON)';
      });
    } catch (e) {
      setState(() => _error = 'Submit failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner App Request'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCurrencies,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload currencies',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BannerNote(
                icon: Icons.info_outline,
                color: cs.primary,
                text:
                    'We send RAW JSON strings in form-data. Backend does the base64. '
                    'So don’t encode anything here. Just valid JSON.',
              ),

              const SizedBox(height: 12),

              if (_error != null) _StatusBox(text: _error!, isError: true),
              if (_success != null) _StatusBox(text: _success!, isError: false),

              const SizedBox(height: 8),

              // Notes
              AppTextField(
                controller: _notesCtrl,
                label: 'Notes',
                hint: 'Explain what app you want (type, features, vibe...)',
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                filled: true,
                margin: const EdgeInsets.only(bottom: 12),
              ),

              // Currency dropdown (IMPORTANT)
              _CurrencyDropdown(
                currencies: _currencies,
                value: _selectedCurrency,
                onChanged: _loading
                    ? null
                    : (c) => setState(() {
                          _selectedCurrency = c;
                          _success = null;
                          _error = null;
                        }),
              ),

              const SizedBox(height: 16),

              // Palette section
              Text('Palette', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              _ColorRow(
                label: 'Primary',
                controller: _primaryCtrl,
                validator: _validateHex,
                preview: _hexToColor(_primaryCtrl.text),
                onChanged: (_) => setState(() {}),
              ),
              _ColorRow(
                label: 'Secondary',
                controller: _secondaryCtrl,
                validator: _validateHex,
                preview: _hexToColor(_secondaryCtrl.text),
                onChanged: (_) => setState(() {}),
              ),
              _ColorRow(
                label: 'Background',
                controller: _bgCtrl,
                validator: _validateHex,
                preview: _hexToColor(_bgCtrl.text),
                onChanged: (_) => setState(() {}),
              ),
              _ColorRow(
                label: 'On Background',
                controller: _onBgCtrl,
                validator: _validateHex,
                preview: _hexToColor(_onBgCtrl.text),
                onChanged: (_) => setState(() {}),
              ),
              _ColorRow(
                label: 'Error',
                controller: _errorCtrl,
                validator: _validateHex,
                preview: _hexToColor(_errorCtrl.text),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Optional API override
              AppTextField(
                controller: _apiOverrideCtrl,
                label: 'apiBaseUrlOverride (optional)',
                hint: 'Leave empty unless you want runtime override',
                filled: true,
                margin: const EdgeInsets.only(bottom: 12),
              ),

              // JSON payloads
              Text('Runtime JSON (raw)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              AppTextField(
                controller: _navCtrl,
                label: 'navJson',
                hint: '[{...}]',
                minLines: 4,
                maxLines: 10,
                validator: _validateJson,
                filled: true,
                margin: const EdgeInsets.only(bottom: 12),
              ),
              AppTextField(
                controller: _homeCtrl,
                label: 'homeJson',
                hint: '{ "sections": [...] }',
                minLines: 4,
                maxLines: 12,
                validator: _validateJson,
                filled: true,
                margin: const EdgeInsets.only(bottom: 12),
              ),
              AppTextField(
                controller: _featuresCtrl,
                label: 'enabledFeaturesJson',
                hint: '["ITEMS","ORDERS"]',
                minLines: 2,
                maxLines: 6,
                validator: _validateJson,
                filled: true,
                margin: const EdgeInsets.only(bottom: 12),
              ),
              AppTextField(
                controller: _brandingCtrl,
                label: 'brandingJson',
                hint: '{ "splashColor": "#FFFFFF" }',
                minLines: 2,
                maxLines: 6,
                validator: _validateJson,
                filled: true,
                margin: const EdgeInsets.only(bottom: 16),
              ),

              // Logo
              Text('Logo (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _LogoPicker(
                file: _logoFile,
                onPick: _loading ? null : _pickLogo,
                onRemove: _loading ? null : _removeLogo,
              ),

              const SizedBox(height: 20),

              AppButton(
                onPressed: _loading ? null : _submit,
                label: _loading ? 'Submitting…' : 'Submit Request',
                expand: true,
                isBusy: _loading,
              ),

              const SizedBox(height: 10),
              Text(
                'FYI: If Postman works but Flutter fails → it’s usually endpoint path or field name mismatch. '
                'This screen matches your screenshot keys exactly.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- widgets -----------------

class _CurrencyDropdown extends StatelessWidget {
  final List<CurrencyModel> currencies;
  final CurrencyModel? value;
  final ValueChanged<CurrencyModel?>? onChanged;

  const _CurrencyDropdown({
    required this.currencies,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CurrencyModel>(
                value: value,
                isExpanded: true,
                hint: const Text('Select currency'),
                items: currencies
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final Color preview;
  final ValueChanged<String> onChanged;

  const _ColorRow({
    required this.label,
    required this.controller,
    required this.validator,
    required this.preview,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            label: '$label Color',
            hint: '#RRGGBB',
            validator: validator,
            filled: true,
            margin: const EdgeInsets.only(bottom: 10),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: preview,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
        ),
      ],
    );
  }
}

class _LogoPicker extends StatelessWidget {
  final File? file;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  const _LogoPicker(
      {required this.file, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: file == null
                ? Icon(Icons.image_outlined, color: cs.onSurfaceVariant)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(file!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              file == null
                  ? 'No logo selected'
                  : file!.path.split(Platform.pathSeparator).last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          if (file != null)
            IconButton(
                onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
          AppButton(
            onPressed: onPick,
            label: 'Pick',
            type: AppButtonType.outline,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

class _BannerNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BannerNote(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String text;
  final bool isError;
  const _StatusBox({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isError ? cs.errorContainer : cs.secondaryContainer;
    final fg = isError ? cs.onErrorContainer : cs.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ],
      ),
    );
  }
}
