import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

class PublisherProfilesScreen extends StatefulWidget {
  const PublisherProfilesScreen({super.key});

  @override
  State<PublisherProfilesScreen> createState() =>
      _PublisherProfilesScreenState();
}

class _PublisherProfilesScreenState extends State<PublisherProfilesScreen> {
  final Dio dio = DioClient.ensure();

  bool loading = true;
  bool saving = false;

  static const stores = ['PLAY_STORE', 'APP_STORE'];
  String selectedStore = 'PLAY_STORE';

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final ppCtrl = TextEditingController();

  final Map<String, Map<String, String>> cache = {};

  // ✅ Prevent text clipping on some fonts/devices
  static const _strut = StrutStyle(forceStrutHeight: true, height: 1.2);
  static const _thb = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

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
      final res = await dio.get('/superadmin/publisher-profiles');
      final data = res.data;
      final list = (data is Map ? data['data'] : null);

      cache.clear();

      if (list is List) {
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final store = (m['store'] ?? '').toString().trim();
          if (store.isEmpty) continue;

          cache[store] = {
            'developerName': (m['developerName'] ?? '').toString(),
            'developerEmail': (m['developerEmail'] ?? '').toString(),
            'privacyPolicyUrl': (m['privacyPolicyUrl'] ?? '').toString(),
          };
        }
      }

      if (!cache.containsKey(selectedStore) && cache.isNotEmpty) {
        selectedStore = cache.keys.first;
      }

      _applySelectedToFields();
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppToast.error(context, l10n.err_unknown);
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

  bool _looksLikeEmail(String s) {
    final x = s.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
  }

  bool _looksLikeUrl(String s) {
    final x = s.trim();
    final uri = Uri.tryParse(x);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pp = ppCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pp.isEmpty) {
      AppToast.warn(context, l10n.common_fill_all_fields);
      return;
    }
    if (!_looksLikeEmail(email)) {
      AppToast.warn(context, l10n.errEmailInvalid);
      return;
    }
    if (!_looksLikeUrl(pp)) {
      AppToast.warn(context, l10n.publish_err_invalid_privacy_url);
      return;
    }

    setState(() => saving = true);
    try {
      await dio.post(
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

      if (mounted) AppToast.success(context, l10n.common_saved);
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.common_save_failed);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _seed() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => saving = true);
    try {
      await dio.post(
        '/superadmin/publisher-profiles/seed',
        data: {
          'developerName': 'Build4All',
          'developerEmail': 'support@build4all.com',
          'privacyPolicyUrl': 'https://example.com/privacy',
        },
      );

      await _load();
      if (mounted) AppToast.success(context, l10n.publish_seeded_success);
    } catch (_) {
      if (mounted) AppToast.error(context, l10n.publish_seed_failed);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _storeLabel(AppLocalizations l10n, String store) {
    return store == 'PLAY_STORE'
        ? l10n.publish_store_play
        : l10n.publish_store_app;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    final pad = tokens?.pagePad ?? const EdgeInsets.all(16);
    final rLg = tokens?.radiusLg ?? 18.0;
    final shadow = tokens?.cardShadow ?? const <BoxShadow>[];

    const bottomBarHeight = 72.0;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = bottomBarHeight + 16 + keyboard;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: pad.left,
        title: Text(
          l10n.publish_manage_publisher_profiles,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          strutStyle: _strut,
          textHeightBehavior: _thb,
        ),

      
        actions: [
          IconButton(
            tooltip: l10n.common_seed,
            onPressed: saving ? null : _seed,
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ScrollConfiguration(
              behavior: const _NoGlowScroll(),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                    pad.left, pad.top, pad.right, bottomPadding),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Pro header (no clipped text)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(rLg),
                              border: Border.all(
                                  color: cs.outlineVariant.withOpacity(.35)),
                              boxShadow: shadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.publish_store_publisher_profile,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1.15,
                                      ),
                                  strutStyle: _strut,
                                  textHeightBehavior: _thb,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.publish_profiles_required_hint,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurface.withOpacity(.65),
                                        height: 1.25,
                                      ),
                                  strutStyle: _strut,
                                  textHeightBehavior: _thb,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ✅ Store chips (no clipping, no overflow)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: stores.map((s) {
                              final selected = selectedStore == s;

                              return ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => selectedStore = s);
                                  _applySelectedToFields();
                                },
                                selectedColor: cs.primary.withOpacity(.14),
                                side: BorderSide(
                                    color: cs.outlineVariant.withOpacity(.6)),
                                label: Text(
                                  _storeLabel(l10n, s),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  strutStyle: _strut,
                                  textHeightBehavior: _thb,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: selected ? cs.primary : cs.onSurface,
                                    height: 1.15,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          // ✅ Form card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(rLg),
                              border: Border.all(
                                  color: cs.outlineVariant.withOpacity(.35)),
                              boxShadow: shadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  controller: nameCtrl,
                                  label: l10n.publish_developer_name,
                                  filled: true,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: emailCtrl,
                                  label: l10n.publish_developer_email,
                                  keyboardType: TextInputType.emailAddress,
                                  filled: true,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: ppCtrl,
                                  label: l10n.publish_privacy_policy_url,
                                  keyboardType: TextInputType.url,
                                  filled: true,
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(height: bottomBarHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad.left, 8, pad.right, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: AppButton(
                  expand: true,
                  isBusy: saving,
                  onPressed: saving ? null : _save,
                  leading: const Icon(Icons.save_rounded),
                  label: saving ? l10n.common_saving : l10n.common_save,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
