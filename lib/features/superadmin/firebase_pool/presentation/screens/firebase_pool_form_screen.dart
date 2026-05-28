import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import '../../data/services/firebase_pool_remote_ds.dart';
import '../../domain/entities/firebase_project_account.dart';

class FirebasePoolFormScreen extends StatefulWidget {
  final FirebaseProjectAccount? existing;

  const FirebasePoolFormScreen({super.key, this.existing});

  @override
  State<FirebasePoolFormScreen> createState() => _FirebasePoolFormScreenState();
}

class _FirebasePoolFormScreenState extends State<FirebasePoolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _projectId;
  late final TextEditingController _displayName;
  late final TextEditingController _credentialsJson;
  late final TextEditingController _priority;
  late final TextEditingController _maxAndroid;
  late final TextEditingController _maxIos;
  late bool _isDefault;
  bool _saving = false;
  bool _obscureJson = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _projectId = TextEditingController(text: e?.firebaseProjectId ?? '');
    _displayName = TextEditingController(text: e?.displayName ?? '');
    _credentialsJson = TextEditingController();
    _priority = TextEditingController(text: (e?.priority ?? 10).toString());
    _maxAndroid =
        TextEditingController(text: (e?.maxAndroidApps ?? 30).toString());
    _maxIos = TextEditingController(text: (e?.maxIosApps ?? 30).toString());
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _projectId.dispose();
    _displayName.dispose();
    _credentialsJson.dispose();
    _priority.dispose();
    _maxAndroid.dispose();
    _maxIos.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ds = FirebasePoolRemoteDs(dio: DioClient.ensure());
      if (_isEdit) {
        await ds.update(
          widget.existing!.id,
          displayName: _displayName.text.trim(),
          serviceAccountCredentialsJson:
              _credentialsJson.text.trim().isNotEmpty
                  ? _credentialsJson.text.trim()
                  : null,
          priority: int.tryParse(_priority.text.trim()) ?? 10,
          maxAndroidApps: int.tryParse(_maxAndroid.text.trim()) ?? 30,
          maxIosApps: int.tryParse(_maxIos.text.trim()) ?? 30,
          isDefault: _isDefault,
        );
      } else {
        await ds.create(
          firebaseProjectId: _projectId.text.trim(),
          displayName: _displayName.text.trim(),
          serviceAccountCredentialsJson: _credentialsJson.text.trim(),
          priority: int.tryParse(_priority.text.trim()) ?? 10,
          maxAndroidApps: int.tryParse(_maxAndroid.text.trim()) ?? 30,
          maxIosApps: int.tryParse(_maxIos.text.trim()) ?? 30,
          isDefault: _isDefault,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        AppToast.error(context, ApiErrorHandler.message(err));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Firebase Account' : 'Add Firebase Account'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionHeader(label: 'Project Identity'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _projectId,
              readOnly: _isEdit,
              decoration: InputDecoration(
                labelText: 'Firebase Project ID *',
                hintText: 'my-app-firebase-prod',
                helperText: _isEdit ? 'Project ID cannot be changed after creation' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: _isEdit,
                fillColor: _isEdit ? cs.surfaceContainerHighest : null,
              ),
              validator: (v) {
                if (!_isEdit && (v == null || v.trim().isEmpty)) {
                  return 'Project ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _displayName,
              decoration: InputDecoration(
                labelText: 'Display Name *',
                hintText: 'Production Firebase Project',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Display name is required';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              label: 'Service Account Credentials',
              subtitle: _isEdit
                  ? 'Leave empty to keep existing credentials'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _credentialsJson,
              maxLines: _obscureJson ? 1 : 8,
              minLines: _obscureJson ? 1 : 3,
              decoration: InputDecoration(
                labelText: _isEdit
                    ? 'Service Account JSON (optional update)'
                    : 'Service Account JSON *',
                hintText: '{"type": "service_account", ...}',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureJson ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureJson = !_obscureJson),
                  tooltip: _obscureJson ? 'Show JSON' : 'Hide JSON',
                ),
              ),
              obscureText: _obscureJson,
              validator: (v) {
                if (!_isEdit && (v == null || v.trim().isEmpty)) {
                  return 'Service account JSON is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Capacity & Priority'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxAndroid,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Max Android Apps',
                      prefixIcon: const Icon(Icons.android_rounded,
                          color: Color(0xFF16A34A)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxIos,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Max iOS Apps',
                      prefixIcon: const Icon(Icons.apple_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priority,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Priority (lower = preferred)',
                hintText: '10',
                helperText: 'Accounts with lower priority values are selected first',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Must be a non-negative number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Settings'),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text(
                'Set as default account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'The default account is used when no specific account is selected during approval',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? 'Save Changes' : 'Add Account',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? subtitle;

  const _SectionHeader({required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: .8,
          ),
        ),
        if (subtitle != null) ...
          [
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(.6),
              ),
            ),
          ],
      ],
    );
  }
}
