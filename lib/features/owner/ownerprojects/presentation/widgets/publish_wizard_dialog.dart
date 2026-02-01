import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; // for ToastType enum (we won't use AppToast here)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../publish/data/services/owner_publish_api.dart';
import '../../../publish/domain/entities/publish_draft.dart';
import 'publish_assets_uploader_sheet.dart';

import 'package:build4all_manager/core/network/url_utils.dart';
import 'package:build4all_manager/core/network/dio_client.dart';

class PublishWizardDialog extends StatefulWidget {
  final OwnerPublishApi api;
  final int aupId;
  final String appName;
  final PublishPlatform platform;
  final PublishStore store;

  final String? androidPackageName;
  final String? iosBundleId;

  const PublishWizardDialog({
    super.key,
    required this.api,
    required this.aupId,
    required this.appName,
    required this.platform,
    required this.store,
    this.androidPackageName,
    this.iosBundleId,
  });

  static Future<void> open(
    BuildContext context, {
    required OwnerPublishApi api,
    required int aupId,
    required String appName,
    required PublishPlatform platform,
    required PublishStore store,
    String? androidPackageName,
    String? iosBundleId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PublishWizardDialog(
        api: api,
        aupId: aupId,
        appName: appName,
        platform: platform,
        store: store,
        androidPackageName: androidPackageName,
        iosBundleId: iosBundleId,
      ),
    );
  }

  @override
  State<PublishWizardDialog> createState() => _PublishWizardDialogState();
}

class _PublishWizardDialogState extends State<PublishWizardDialog> {
  int step = 1;
  bool loading = true;
  bool saving = false;

  PublishDraft? draft;

  final appNameCtrl = TextEditingController();
  final shortCtrl = TextEditingController();
  final fullCtrl = TextEditingController();

  final categoryCtrl = TextEditingController();
  String country = 'United States';
  PricingType pricing = PricingType.free;
  bool contentConfirmed = false;

  final _snapshotCtrl = TextEditingController();

  // ✅ INLINE MESSAGE under steps bar
  String? _inlineMsg;
  ToastType _inlineType = ToastType.info;

  void _showInline(String msg, {ToastType type = ToastType.error}) {
    if (!mounted) return;
    setState(() {
      _inlineMsg = msg;
      _inlineType = type;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_inlineMsg == msg) {
        setState(() => _inlineMsg = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  String _fallbackSnapshot() {
    final a = (widget.androidPackageName ?? '').trim();
    final i = (widget.iosBundleId ?? '').trim();
    return widget.platform == PublishPlatform.android ? a : i;
  }

  String _title(AppLocalizations l10n) => widget.store == PublishStore.playStore
      ? l10n.owner_publish_title_play
      : l10n.owner_publish_title_appstore;

  String _platformLabel(AppLocalizations l10n) =>
      widget.platform == PublishPlatform.android
          ? l10n.owner_publish_platform_android
          : l10n.owner_publish_platform_ios;

  String _snapshotLabel(AppLocalizations l10n) =>
      widget.platform == PublishPlatform.android
          ? l10n.owner_publish_package_name
          : l10n.owner_publish_bundle_id;

  /// ✅ Extract backend errors (including your 500 trace RuntimeException)
  String _errText(Object e, AppLocalizations l10n) {
    if (e is DioException) {
      final data = e.response?.data;

      String pickString(dynamic v) => (v ?? '').toString().trim();

      if (data is Map) {
        final err = pickString(data['error']);
        if (err.isNotEmpty) return _mapKnownErrors(err, l10n);

        final msg = pickString(data['message']);
        if (msg.isNotEmpty) return _mapKnownErrors(msg, l10n);

        final trace = pickString(data['trace']);
        final extracted = _extractRuntimeException(trace);
        if (extracted.isNotEmpty) return _mapKnownErrors(extracted, l10n);
      }

      final m = (e.message ?? '').trim();
      if (m.isNotEmpty) return m;

      return l10n.common_network_error_try_again;
    }

    final raw = e.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return l10n.common_error;
    return _mapKnownErrors(raw, l10n);
  }

  String _extractRuntimeException(String trace) {
    if (trace.isEmpty) return '';
    final key = 'RuntimeException:';
    final i = trace.indexOf(key);
    if (i < 0) return '';
    var s = trace.substring(i + key.length).trim();

    final n1 = s.indexOf('\n');
    final n2 = s.indexOf('\r');
    final cut = [n1, n2].where((x) => x >= 0).toList();
    if (cut.isNotEmpty) {
      cut.sort();
      s = s.substring(0, cut.first).trim();
    }
    return s;
  }

  String _mapKnownErrors(String raw, AppLocalizations l10n) {
    final msg = raw.toLowerCase();

    if (msg.contains('short description') && msg.contains('required')) {
      return l10n.owner_publish_err_short;
    }
    if (msg.contains('full description') && msg.contains('required')) {
      return l10n.owner_publish_err_full;
    }
    if (msg.contains('category') && msg.contains('required')) {
      return l10n.owner_publish_err_category;
    }
    if (msg.contains('application') &&
        msg.contains('name') &&
        msg.contains('required')) {
      return l10n.owner_publish_err_appname;
    }

    if (msg.contains('logo') &&
        (msg.contains('required') ||
            msg.contains('missing') ||
            msg.contains('empty'))) {
      return l10n.owner_publish_err_logo_required;
    }

    if (msg.contains('icon') &&
        (msg.contains('required') ||
            msg.contains('missing') ||
            msg.contains('empty'))) {
      return l10n.owner_publish_err_icon;
    }

    if ((msg.contains('screenshot') || msg.contains('screenshots')) &&
        (msg.contains('at least') ||
            msg.contains('minimum') ||
            msg.contains('required'))) {
      return l10n.owner_publish_err_shots2;
    }

    return raw.trim().isEmpty ? l10n.common_error : raw.trim();
  }

  Future<void> _loadDraft() async {
    setState(() => loading = true);
    try {
      final d = await widget.api.getOrCreateDraft(
        aupId: widget.aupId,
        platform: widget.platform,
        store: widget.store,
      );

      draft = d;

      appNameCtrl.text = d.applicationName.trim().isNotEmpty
          ? d.applicationName
          : widget.appName;

      shortCtrl.text = d.shortDescription.trim();
      fullCtrl.text = d.fullDescription.trim();
      categoryCtrl.text = d.category.trim();

      if (d.countryAvailability.trim().isNotEmpty) {
        country = d.countryAvailability.trim();
      }

      pricing = d.pricing;
      contentConfirmed = d.contentRatingConfirmed;

      final draftSnap = widget.platform == PublishPlatform.android
          ? d.packageNameSnapshot
          : d.bundleIdSnapshot;

      final snap =
          (draftSnap.trim().isNotEmpty) ? draftSnap : _fallbackSnapshot();
      _snapshotCtrl.text = snap;
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showInline(
        '${l10n.owner_publish_err_load_draft}: ${_errText(e as Object, l10n)}',
        type: ToastType.error,
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _validateStep1(AppLocalizations l10n) {
    if (appNameCtrl.text.trim().isEmpty) {
      throw l10n.owner_publish_err_appname;
    }
    if (shortCtrl.text.trim().isEmpty) {
      throw l10n.owner_publish_err_short;
    }
    if (shortCtrl.text.trim().length > 80) {
      throw l10n.owner_publish_err_short80;
    }
    if (fullCtrl.text.trim().isEmpty) {
      throw l10n.owner_publish_err_full;
    }
  }

  void _validateStep2(AppLocalizations l10n) {
    if (categoryCtrl.text.trim().isEmpty) {
      throw l10n.owner_publish_err_category;
    }
    if (!contentConfirmed) {
      throw l10n.owner_publish_err_content_confirm;
    }
  }

  void _validateStep4Assets(AppLocalizations l10n) {
    final d = draft;
    if (d == null) return;

    final hasIcon = d.appIconUrl.trim().isNotEmpty;
    final shots = d.screenshotsUrls.where((e) => e.trim().isNotEmpty).toList();

    if (!hasIcon) throw l10n.owner_publish_err_icon;
    if (shots.length < 2) throw l10n.owner_publish_err_shots2;
    if (shots.length > 8) throw l10n.owner_publish_err_shots8;
  }

  Future<void> _saveStep() async {
    final l10n = AppLocalizations.of(context)!;
    if (draft == null) return;

    try {
      if (step == 1) _validateStep1(l10n);
      if (step == 2) _validateStep2(l10n);
      if (step == 4) _validateStep4Assets(l10n);
    } catch (msg) {
      _showInline(msg.toString(), type: ToastType.error);
      rethrow;
    }

    setState(() => saving = true);
    try {
      final updated = await widget.api.patchDraft(
        requestId: draft!.id,
        applicationName: step == 1 ? appNameCtrl.text.trim() : null,
        shortDescription: step == 1 ? shortCtrl.text.trim() : null,
        fullDescription: step == 1 ? fullCtrl.text.trim() : null,
        category: step == 2 ? categoryCtrl.text.trim() : null,
        countryAvailability: step == 2 ? country : null,
        pricing: step == 2 ? pricing : null,
        contentRatingConfirmed: step == 2 ? contentConfirmed : null,
      );

      draft = updated;

      final draftSnap = widget.platform == PublishPlatform.android
          ? updated.packageNameSnapshot
          : updated.bundleIdSnapshot;

      if (draftSnap.trim().isNotEmpty) {
        _snapshotCtrl.text = draftSnap.trim();
      }
    } catch (e) {
      _showInline(
        '${l10n.owner_publish_err_save_failed}: ${_errText(e as Object, l10n)}',
        type: ToastType.error,
      );
      rethrow;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (draft == null) return;

    try {
      _validateStep1(l10n);
      _validateStep2(l10n);
      _validateStep4Assets(l10n);
    } catch (msg) {
      _showInline(msg.toString(), type: ToastType.error);
      rethrow;
    }

    setState(() => saving = true);
    try {
      final updated = await widget.api.patchDraft(
        requestId: draft!.id,
        applicationName: appNameCtrl.text.trim(),
        shortDescription: shortCtrl.text.trim(),
        fullDescription: fullCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        countryAvailability: country,
        pricing: pricing,
        contentRatingConfirmed: contentConfirmed,
      );
      draft = updated;
    } catch (e) {
      _showInline(
        '${l10n.owner_publish_err_save_failed}: ${_errText(e as Object, l10n)}',
        type: ToastType.error,
      );
      rethrow;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (draft == null) return;

    setState(() => saving = true);
    try {
      await _saveAll();
      final res = await widget.api.submit(requestId: draft!.id);
      draft = res;

      _showInline(l10n.owner_publish_submitted, type: ToastType.success);

      // Let user see it for a tiny moment then close
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showInline(
        '${l10n.owner_publish_err_submit_failed}: ${_errText(e as Object, l10n)}',
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _openAssetsUploader() async {
    if (draft == null) return;

    final res = await PublishAssetsUploaderSheet.open(
      context,
      api: widget.api,
      requestId: draft!.id,
      platform: widget.platform,
    );

    if (!mounted) return;

    if (res is PublishDraft) {
      setState(() => draft = res);
    } else {
      await _loadDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final w = MediaQuery.of(context).size.width;
    final dialogW = w < 720 ? w * .95 : 760.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogW,
        height: 640,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.platform == PublishPlatform.android
                                ? Icons.android_rounded
                                : Icons.apple_rounded,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(l10n),
                                style: tt.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.appName} · ${_platformLabel(l10n)}',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: l10n.common_close,
                        ),
                      ],
                    ),
                  ),

                  _StepsBar(step: step),

                  // ✅ INLINE message appears HERE (under steps)
                  if (_inlineMsg != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: _InlineBanner(
                        message: _inlineMsg!,
                        type: _inlineType,
                        onClose: () => setState(() => _inlineMsg = null),
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                      child: _StepBody(
                        step: step,
                        appNameCtrl: appNameCtrl,
                        shortCtrl: shortCtrl,
                        fullCtrl: fullCtrl,
                        categoryCtrl: categoryCtrl,
                        country: country,
                        onCountryChanged: (v) => setState(() => country = v),
                        pricing: pricing,
                        onPricingChanged: (p) => setState(() => pricing = p),
                        contentConfirmed: contentConfirmed,
                        onContentConfirmChanged: (v) =>
                            setState(() => contentConfirmed = v),
                        snapshotLabel: _snapshotLabel(l10n),
                        snapshotCtrl: _snapshotCtrl,
                        draft: draft,
                        onOpenUploader: _openAssetsUploader,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: saving
                              ? null
                              : () {
                                  if (step == 1) {
                                    Navigator.pop(context);
                                  } else {
                                    setState(() => step -= 1);
                                  }
                                },
                          child: Text(step == 1
                              ? l10n.common_cancel
                              : l10n.common_back),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (step < 4) {
                                    try {
                                      await _saveStep();
                                      if (mounted) setState(() => step += 1);
                                    } catch (_) {}
                                  } else {
                                    await _submit();
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(step < 4
                                  ? l10n.common_continue
                                  : l10n.owner_publish_submit),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    appNameCtrl.dispose();
    shortCtrl.dispose();
    fullCtrl.dispose();
    categoryCtrl.dispose();
    _snapshotCtrl.dispose();
    super.dispose();
  }
}

class _StepsBar extends StatelessWidget {
  final int step;
  const _StepsBar({required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget dot(int i) {
      final done = i < step;
      final active = i == step;

      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: done
              ? cs.primary
              : (active
                  ? cs.primary.withOpacity(.10)
                  : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: done || active ? cs.primary : cs.outlineVariant,
          ),
        ),
        alignment: Alignment.center,
        child: done
            ? Icon(Icons.check_rounded, size: 18, color: cs.onPrimary)
            : Text(
                '$i',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? cs.primary : cs.onSurface.withOpacity(.55),
                ),
              ),
      );
    }

    Widget line(bool on) => Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: on ? cs.primary : cs.outlineVariant.withOpacity(.4),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          dot(1),
          const SizedBox(width: 10),
          line(step > 1),
          const SizedBox(width: 10),
          dot(2),
          const SizedBox(width: 10),
          line(step > 2),
          const SizedBox(width: 10),
          dot(3),
          const SizedBox(width: 10),
          line(step > 3),
          const SizedBox(width: 10),
          dot(4),
        ],
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback onClose;

  const _InlineBanner({
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (type) {
      case ToastType.success:
        bg = Colors.green.withOpacity(.12);
        fg = Colors.green.shade300;
        break;
      case ToastType.warning:
        bg = Colors.orange.withOpacity(.12);
        fg = Colors.orange.shade300;
        break;
      case ToastType.error:
        bg = Colors.red.withOpacity(.12);
        fg = Colors.red.shade300;
        break;
      case ToastType.info:
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.primary;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded,
                  color: cs.onSurface.withOpacity(.7)),
              splashRadius: 18,
              tooltip: 'Close',
            )
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  final int step;

  final TextEditingController appNameCtrl;
  final TextEditingController shortCtrl;
  final TextEditingController fullCtrl;

  final TextEditingController categoryCtrl;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final PricingType pricing;
  final ValueChanged<PricingType> onPricingChanged;
  final bool contentConfirmed;
  final ValueChanged<bool> onContentConfirmChanged;

  final String snapshotLabel;
  final TextEditingController snapshotCtrl;

  final PublishDraft? draft;
  final VoidCallback onOpenUploader;

  const _StepBody({
    required this.step,
    required this.appNameCtrl,
    required this.shortCtrl,
    required this.fullCtrl,
    required this.categoryCtrl,
    required this.country,
    required this.onCountryChanged,
    required this.pricing,
    required this.onPricingChanged,
    required this.contentConfirmed,
    required this.onContentConfirmChanged,
    required this.snapshotLabel,
    required this.snapshotCtrl,
    required this.draft,
    required this.onOpenUploader,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        );

    if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.owner_publish_step1_title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(l10n.owner_publish_step1_sub,
              style:
                  tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65))),
          const SizedBox(height: 18),
          Text(l10n.owner_publish_app_name,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          TextField(
            controller: appNameCtrl,
            decoration: deco(l10n.owner_publish_app_name_hint),
          ),
          const SizedBox(height: 14),
          Text(snapshotLabel,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          TextField(
            controller: snapshotCtrl,
            readOnly: true,
            decoration: deco('').copyWith(
              suffixIcon:
                  Icon(Icons.lock_rounded, color: cs.onSurface.withOpacity(.5)),
            ),
          ),
          const SizedBox(height: 14),
          Text(l10n.owner_publish_short_desc,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          TextField(
            controller: shortCtrl,
            maxLength: 80,
            decoration: deco(l10n.owner_publish_short_desc_hint),
          ),
          const SizedBox(height: 8),
          Text(l10n.owner_publish_full_desc,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          TextField(
            controller: fullCtrl,
            maxLines: 5,
            decoration: deco(l10n.owner_publish_full_desc_hint),
          ),
        ],
      );
    }

    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.owner_publish_step2_title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(l10n.owner_publish_step2_sub,
              style:
                  tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65))),
          const SizedBox(height: 18),
          Text(l10n.owner_publish_category,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          TextField(
            controller: categoryCtrl,
            decoration: deco(l10n.owner_publish_category_hint),
          ),
          const SizedBox(height: 14),
          Text(l10n.owner_publish_country,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: country,
            decoration: deco(''),
            items: [
              DropdownMenuItem(
                  value: 'United States',
                  child: Text(l10n.owner_publish_country_us)),
              DropdownMenuItem(
                  value: 'Lebanon', child: Text(l10n.owner_publish_country_lb)),
              DropdownMenuItem(
                  value: 'France', child: Text(l10n.owner_publish_country_fr)),
            ],
            onChanged: (v) => onCountryChanged(v ?? 'United States'),
          ),
          const SizedBox(height: 14),
          Text(l10n.owner_publish_pricing,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChipBtn(
                  active: pricing == PricingType.free,
                  label: l10n.owner_publish_free,
                  onTap: () => onPricingChanged(PricingType.free),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceChipBtn(
                  active: pricing == PricingType.paid,
                  label: l10n.owner_publish_paid,
                  onTap: () => onPricingChanged(PricingType.paid),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withOpacity(.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.tertiary.withOpacity(.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: contentConfirmed,
                  onChanged: (v) => onContentConfirmChanged(v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.owner_publish_content_confirm,
                      style:
                          tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (step == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.owner_publish_step3_title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(l10n.owner_publish_step3_sub,
              style:
                  tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65))),
          const SizedBox(height: 18),
          _ReadOnlyBox(
            label: l10n.owner_publish_privacy_url,
            value: l10n.owner_publish_managed_by_build4all,
          ),
          const SizedBox(height: 12),
          _ReadOnlyBox(
            label: l10n.owner_publish_dev_name,
            value: l10n.owner_publish_managed_by_build4all,
          ),
          const SizedBox(height: 12),
          _ReadOnlyBox(
            label: l10n.owner_publish_dev_email,
            value: l10n.owner_publish_managed_by_build4all,
          ),
        ],
      );
    }

    // STEP 4 preview
    final d = draft;
    final dio = DioClient.ensure();
    final serverRootNoApi = serverRootNoApiFromBaseUrl(dio.options.baseUrl);

    final rawIcon = (d?.appIconUrl ?? '').trim();
    final icon = absUrlFromServerRoot(serverRootNoApi, rawIcon);

    final rawShots =
        (d?.screenshotsUrls ?? []).where((e) => e.trim().isNotEmpty).toList();

    final shots = rawShots
        .map((e) => absUrlFromServerRoot(serverRootNoApi, e))
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.owner_publish_step4_title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(l10n.owner_publish_step4_sub,
            style:
                tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65))),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpenUploader,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text(
              l10n.owner_publish_upload_assets,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(.6)),
        const SizedBox(height: 14),
        Text(l10n.owner_publish_current_icon,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (icon.isEmpty)
          Text(
            l10n.owner_publish_no_icon_yet,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                Image.network(icon, width: 84, height: 84, fit: BoxFit.cover),
          ),
        const SizedBox(height: 18),
        Text(l10n.owner_publish_current_screenshots,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (shots.isEmpty)
          Text(
            l10n.owner_publish_no_screenshots_yet,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
          )
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(shots[i],
                    width: 140, height: 92, fit: BoxFit.cover),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.owner_publish_rule_shots_2_8,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65)),
        ),
      ],
    );
  }
}

class _ChoiceChipBtn extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _ChoiceChipBtn({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              active ? cs.primary.withOpacity(.12) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? cs.primary : cs.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? cs.primary : cs.onSurface.withOpacity(.8),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            value,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
          ),
        ),
      ],
    );
  }
}
