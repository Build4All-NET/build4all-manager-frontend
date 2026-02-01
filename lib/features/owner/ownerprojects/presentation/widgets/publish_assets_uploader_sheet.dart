import 'dart:io';

import 'package:build4all_manager/features/owner/publish/data/services/owner_publish_api.dart';
import 'package:build4all_manager/features/owner/publish/domain/entities/publish_draft.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PublishAssetsUploaderSheet extends StatefulWidget {
  final OwnerPublishApi api;
  final int requestId;
  final PublishPlatform platform;

  const PublishAssetsUploaderSheet({
    super.key,
    required this.api,
    required this.requestId,
    required this.platform,
  });

  static Future<dynamic> open(
    BuildContext context, {
    required OwnerPublishApi api,
    required int requestId,
    required PublishPlatform platform,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PublishAssetsUploaderSheet(
        api: api,
        requestId: requestId,
        platform: platform,
      ),
    );
  }

  @override
  State<PublishAssetsUploaderSheet> createState() =>
      _PublishAssetsUploaderSheetState();
}

class _PublishAssetsUploaderSheetState
    extends State<PublishAssetsUploaderSheet> {
  final _picker = ImagePicker();

  File? _icon;
  final List<File> _shots = [];
  bool _uploading = false;

  String _errText(dynamic e, AppLocalizations l10n) {
    // ✅ Best effort extraction from backend
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map) {
        final err = (data['error'] ?? data['message'] ?? '').toString().trim();
        if (err.isNotEmpty) return err;
      }

      final msg = e.message?.trim() ?? '';
      if (msg.isNotEmpty) return msg;

      return l10n.common_network_error_try_again;
    }

    final s = e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  Future<void> _pickIcon() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (x == null) return;
    setState(() => _icon = File(x.path));
  }

  Future<void> _pickScreenshots() async {
    final xs = await _picker.pickMultiImage(imageQuality: 90);
    if (xs.isEmpty) return;

    setState(() {
      for (final x in xs) {
        final f = File(x.path);
        if (_shots.any((e) => e.path == f.path)) continue;
        _shots.add(f);
      }
    });
  }

  void _removeShot(int index) {
    setState(() => _shots.removeAt(index));
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;

    // ✅ clear, specific validation
    if (_icon == null && _shots.isEmpty) {
      AppToast.error(
          context, l10n.owner_publish_assets_err_pick_icon_or_screens);
      return;
    }

    if (_shots.isNotEmpty && _shots.length < 2) {
      AppToast.error(context, l10n.owner_publish_assets_err_screens_min2);
      return;
    }

    if (_shots.length > 8) {
      AppToast.error(context, l10n.owner_publish_assets_err_screens_max8);
      return;
    }

    setState(() => _uploading = true);
    try {
      final updated = await widget.api.uploadAssets(
        requestId: widget.requestId,
        appIcon: _icon,
        screenshots: _shots.isEmpty ? null : _shots,
      );

      if (!mounted) return;
      AppToast.success(context, l10n.owner_publish_assets_uploaded);
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _errText(e, l10n));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final title = widget.platform == PublishPlatform.android
        ? l10n.owner_publish_assets_title_android
        : l10n.owner_publish_assets_title_ios;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withOpacity(.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.common_close,
                  )
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.owner_publish_assets_app_icon,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(.5),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: cs.outlineVariant.withOpacity(.6)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _icon == null
                        ? Icon(Icons.image_rounded,
                            color: cs.onSurface.withOpacity(.6))
                        : Image.file(_icon!, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickIcon,
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(l10n.owner_publish_assets_choose_icon),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (_icon != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _uploading
                          ? null
                          : () => setState(() => _icon = null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: cs.error,
                      tooltip: l10n.owner_publish_assets_remove_icon,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: cs.outlineVariant.withOpacity(.6)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.owner_publish_assets_screenshots_2_8,
                      style:
                          tt.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickScreenshots,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(l10n.common_add),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_shots.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(.35),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(.6)),
                  ),
                  child: Text(
                    l10n.owner_publish_assets_no_screenshots,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(.7),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shots.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final f = _shots[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              f,
                              width: 140,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: _uploading ? null : () => _removeShot(i),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _uploading
                        ? l10n.common_uploading
                        : l10n.owner_publish_assets_upload_assets,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
