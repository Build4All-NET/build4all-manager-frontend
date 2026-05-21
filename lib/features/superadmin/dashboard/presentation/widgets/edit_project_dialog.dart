import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/project_summary.dart';

// ─── Icon options — keys must match ProjectTemplateCard._iconMap exactly ─────

class _IconOption {
  final String key;
  final IconData icon;
  final String label;
  const _IconOption(this.key, this.icon, this.label);
}

const List<_IconOption> _kIcons = [
  _IconOption('apps_rounded', Icons.apps_rounded, 'Default'),
  _IconOption('shopping_bag_rounded', Icons.shopping_bag_rounded,
      'Shopping Bag'),
  _IconOption('shopping_cart_rounded', Icons.shopping_cart_rounded,
      'Shopping Cart'),
  _IconOption('store_rounded', Icons.store_rounded, 'Store'),
  _IconOption('restaurant_rounded', Icons.restaurant_rounded, 'Restaurant'),
  _IconOption(
      'fitness_center_rounded', Icons.fitness_center_rounded, 'Fitness'),
  _IconOption('sports_gymnastics', Icons.sports_gymnastics, 'Sports'),
  _IconOption(
      'inventory_2_rounded', Icons.inventory_2_rounded, 'Inventory'),
  _IconOption('warehouse_rounded', Icons.warehouse_rounded, 'Warehouse'),
  _IconOption(
      'location_city_rounded', Icons.location_city_rounded, 'City'),
  _IconOption('account_balance_rounded', Icons.account_balance_rounded,
      'Municipality'),
  _IconOption('event_rounded', Icons.event_rounded, 'Events'),
  _IconOption(
      'local_activity_rounded', Icons.local_activity_rounded, 'Activities'),
  _IconOption('miscellaneous_services_rounded',
      Icons.miscellaneous_services_rounded, 'Services'),
  _IconOption(
      'construction_rounded', Icons.construction_rounded, 'Construction'),
  _IconOption(
      'medical_services_rounded', Icons.medical_services_rounded, 'Medical'),
  _IconOption('school_rounded', Icons.school_rounded, 'School'),
];

// ─── Predefined card colors ────────────────────────────────────────────────

class _ColorOption {
  final String hex;
  final String label;
  const _ColorOption(this.hex, this.label);
}

const List<_ColorOption> _kColors = [
  _ColorOption('#2563EB', 'Blue'),
  _ColorOption('#16A34A', 'Green'),
  _ColorOption('#7C3AED', 'Purple'),
  _ColorOption('#EC4899', 'Pink'),
  _ColorOption('#F97316', 'Orange'),
  _ColorOption('#DC2626', 'Red'),
  _ColorOption('#0D9488', 'Teal'),
  _ColorOption('#475569', 'Slate'),
  _ColorOption('#D97706', 'Amber'),
  _ColorOption('#4F46E5', 'Indigo'),
];

// ─── Dialog ───────────────────────────────────────────────────────────────────

class EditProjectDialog extends StatefulWidget {
  final ProjectSummary project;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.onSave,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayTitleCtrl;
  late final TextEditingController _displayDescriptionCtrl;
  late final TextEditingController _displayOrderCtrl;

  String? _selectedIconName;
  String? _selectedColor;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayTitleCtrl =
        TextEditingController(text: widget.project.displayTitle ?? '');
    _displayDescriptionCtrl =
        TextEditingController(text: widget.project.displayDescription ?? '');
    _displayOrderCtrl = TextEditingController(
      text: widget.project.displayOrder?.toString() ?? '',
    );

    // Only pre-select icon if it is in the known list
    final existingIcon = widget.project.iconName?.trim() ?? '';
    _selectedIconName = existingIcon.isNotEmpty &&
            _kIcons.any((o) => o.key == existingIcon)
        ? existingIcon
        : null;

    // Keep whatever colour the backend has (even if not in the palette)
    final existingColor = widget.project.cardColor?.trim() ?? '';
    _selectedColor = existingColor.isNotEmpty ? existingColor : null;
  }

  @override
  void dispose() {
    _displayTitleCtrl.dispose();
    _displayDescriptionCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return Colors.grey;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'displayTitle': _displayTitleCtrl.text.trim(),
      'displayDescription': _displayDescriptionCtrl.text.trim(),
      if (_selectedIconName != null) 'iconName': _selectedIconName,
      if (_selectedColor != null) 'cardColor': _selectedColor,
      if (_displayOrderCtrl.text.trim().isNotEmpty)
        'displayOrder': int.parse(_displayOrderCtrl.text.trim()),
    };

    try {
      await widget.onSave(data);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      rethrow;
    }
  }

  InputDecoration _fieldDeco(ColorScheme cs) => InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final labelStyle = tt.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return AlertDialog(
      title: Text('Edit "${widget.project.name}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _displayTitleCtrl,
                  decoration: _fieldDeco(cs).copyWith(
                    labelText: 'Display Title',
                    hintText: 'Shown on the card',
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _displayDescriptionCtrl,
                  decoration: _fieldDeco(cs).copyWith(
                    labelText: 'Display Description',
                    hintText: 'Short subtitle on the card',
                    prefixIcon: const Icon(Icons.short_text_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // ── Icon selector ──────────────────────────────────────
                Text('Card Icon', style: labelStyle),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedIconName,
                  isExpanded: true,
                  decoration: _fieldDeco(cs).copyWith(
                    hintText: 'Select an icon',
                  ),
                  items: _kIcons
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt.key,
                          child: Row(
                            children: [
                              Icon(opt.icon,
                                  size: 20, color: cs.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (_) => _kIcons
                      .map(
                        (opt) => Row(
                          children: [
                            Icon(opt.icon,
                                size: 20, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                opt.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedIconName = v),
                ),

                const SizedBox(height: 16),

                // ── Color selector ─────────────────────────────────────
                Text('Card Color', style: labelStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kColors.map((opt) {
                    final color = _hexToColor(opt.hex);
                    final isSelected = _selectedColor == opt.hex;
                    return Tooltip(
                      message: opt.label,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = opt.hex),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 150),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? cs.onSurface.withOpacity(0.9)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.45),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayOrderCtrl,
                  decoration: _fieldDeco(cs).copyWith(
                    labelText: 'Display Order',
                    hintText: 'Lower = shown first',
                    prefixIcon: const Icon(Icons.sort_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
