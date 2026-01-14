import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

class PublisherProfilesScreen extends StatefulWidget {
  final Dio dio;
  const PublisherProfilesScreen({super.key, required this.dio});

  @override
  State<PublisherProfilesScreen> createState() =>
      _PublisherProfilesScreenState();
}

class _PublisherProfilesScreenState extends State<PublisherProfilesScreen> {
  bool loading = true;
  bool saving = false;

  final stores = const ['PLAY_STORE', 'APP_STORE'];
  String selectedStore = 'PLAY_STORE';

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final ppCtrl = TextEditingController();

  // store -> {developerName, developerEmail, privacyPolicyUrl}
  final Map<String, Map<String, String>> cache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    ppCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await widget.dio.get('/superadmin/publisher-profiles');
      final data = res.data;
      final list = (data is Map ? data['data'] : null);

      cache.clear();

      if (list is List) {
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final store = (m['store'] ?? '').toString();

          cache[store] = {
            'developerName': (m['developerName'] ?? '').toString(),
            'developerEmail': (m['developerEmail'] ?? '').toString(),
            'privacyPolicyUrl': (m['privacyPolicyUrl'] ?? '').toString(),
          };
        }
      }

      // pick a safe store to show
      if (!cache.containsKey(selectedStore) && cache.isNotEmpty) {
        selectedStore = cache.keys.first;
      }

      _applySelectedToFields();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profiles: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _applySelectedToFields() {
    final p = cache[selectedStore] ?? {};
    nameCtrl.text = p['developerName'] ?? '';
    emailCtrl.text = p['developerEmail'] ?? '';
    ppCtrl.text = p['privacyPolicyUrl'] ?? '';
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pp = ppCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await widget.dio.post(
        '/superadmin/publisher-profiles/upsert',
        data: {
          'store': selectedStore,
          'developerName': name,
          'developerEmail': email,
          'privacyPolicyUrl': pp,
        },
      );

      cache[selectedStore] = {
        'developerName': name,
        'developerEmail': email,
        'privacyPolicyUrl': pp,
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _seed() async {
    setState(() => saving = true);
    try {
      await widget.dio.post(
        '/superadmin/publisher-profiles/seed',
        data: {
          'developerName': 'Build4All',
          'developerEmail': 'support@build4all.com',
          'privacyPolicyUrl': 'https://example.com/privacy',
        },
      );

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeded ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l10n)),
        actions: [
          TextButton.icon(
            onPressed: saving ? null : _seed,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Seed'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                // store selector
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: stores.map((s) {
                    final selected = selectedStore == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => selectedStore = s);
                        _applySelectedToFields();
                      },
                      selectedColor: cs.primary.withOpacity(.14),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                      side:
                          BorderSide(color: cs.outlineVariant.withOpacity(.6)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Publisher Profile',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _Field(label: 'Developer name', controller: nameCtrl),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'Developer email',
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'Privacy policy URL',
                        controller: ppCtrl,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Owners can’t submit publish requests unless this is configured.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(.65),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(saving ? 'Saving...' : 'Save'),
              onPressed: saving ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    try {
      return l10n.publish_manage_publisher_profiles;
    } catch (_) {
      return 'Publisher Profiles';
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
