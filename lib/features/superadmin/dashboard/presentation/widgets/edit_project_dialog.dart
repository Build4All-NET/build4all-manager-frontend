import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/project_summary.dart';

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
  late final TextEditingController _iconNameCtrl;
  late final TextEditingController _cardColorCtrl;
  late final TextEditingController _displayOrderCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayTitleCtrl =
        TextEditingController(text: widget.project.displayTitle ?? '');
    _displayDescriptionCtrl =
        TextEditingController(text: widget.project.displayDescription ?? '');
    _iconNameCtrl =
        TextEditingController(text: widget.project.iconName ?? '');
    _cardColorCtrl =
        TextEditingController(text: widget.project.cardColor ?? '');
    _displayOrderCtrl = TextEditingController(
      text: widget.project.displayOrder?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _displayTitleCtrl.dispose();
    _displayDescriptionCtrl.dispose();
    _iconNameCtrl.dispose();
    _cardColorCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'displayTitle': _displayTitleCtrl.text.trim(),
      'displayDescription': _displayDescriptionCtrl.text.trim(),
      'iconName': _iconNameCtrl.text.trim(),
      'cardColor': _cardColorCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit "${widget.project.name}"'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _displayTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Title',
                  hintText: 'Shown on the card',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayDescriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Description',
                  hintText: 'Short subtitle on the card',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iconNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Icon Name',
                  hintText: 'e.g. shopping_cart',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardColorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card Color',
                  hintText: 'e.g. #FF5722',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayOrderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  hintText: 'Lower = shown first',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
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
