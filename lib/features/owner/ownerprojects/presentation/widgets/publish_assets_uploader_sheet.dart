import 'dart:io';

import 'package:build4all_manager/features/owner/publish/data/services/owner_publish_api.dart';
import 'package:build4all_manager/features/owner/publish/domain/entities/publish_draft.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
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

class _PublishAssetsUploaderSheetState extends State<PublishAssetsUploaderSheet> {
  final _picker = ImagePicker();

  File? _icon;
  final List<File> _shots = [];

  bool _uploading = false;

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
    if (_icon == null && _shots.isEmpty) {
      AppToast.error(context, 'Pick an icon or screenshots first');
      return;
    }

    if (_shots.isNotEmpty && _shots.length < 2) {
      AppToast.error(context, 'Screenshots: add at least 2 before submitting');
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
      AppToast.success(context, 'Assets uploaded');

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                      widget.platform == PublishPlatform.android
                          ? 'Android Assets'
                          : 'iOS Assets',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  )
                ],
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'App Icon',
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
                      border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
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
                      label: const Text('Choose Icon'),
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
                      onPressed: _uploading ? null : () => setState(() => _icon = null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: cs.error,
                      tooltip: 'Remove icon',
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
                      'Screenshots (2..8)',
                      style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickScreenshots,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Add'),
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
                    border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
                  ),
                  child: Text(
                    'No screenshots selected yet.',
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
                    _uploading ? 'Uploading...' : 'Upload Assets',
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
