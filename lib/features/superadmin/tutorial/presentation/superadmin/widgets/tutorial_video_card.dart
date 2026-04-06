import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/core/network/url_utils.dart' as urlu;

import '../bloc/tutorial_video_bloc.dart';
import '../bloc/tutorial_video_event.dart';
import '../bloc/tutorial_video_state.dart';

class TutorialVideoCard extends StatelessWidget {
  final String dioBaseUrl;

  const TutorialVideoCard({
    super.key,
    required this.dioBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<TutorialVideoBloc, TutorialVideoState>(
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          AppToast.error(context, state.error!);
          context.read<TutorialVideoBloc>().add(const TutorialVideoClearUi());
        }
        if (state.message != null && state.message!.trim().isNotEmpty) {
          AppToast.success(context, state.message!);
          context.read<TutorialVideoBloc>().add(const TutorialVideoClearUi());
        }
      },
      builder: (context, state) {
        final current = (state.videoPath == null || state.videoPath!.isEmpty)
            ? l10n.tutorial_ownerGuide_notSetYet
            : state.videoPath!;

        final busy = state.loading || state.uploading;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.ondemand_video_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tutorial_ownerGuide_title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.tutorial_common_refresh,
                    onPressed: state.uploading
                        ? null
                        : () => context
                            .read<TutorialVideoBloc>()
                            .add(const TutorialVideoRefreshRequested()),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.tutorial_ownerGuide_subtitle,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.75),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        current,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.common_open,
                      onPressed: (state.videoPath == null)
                          ? null
                          : () => _open(context, state),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                    IconButton(
                      tooltip: l10n.common_copy,
                      onPressed: (state.videoPath == null)
                          ? null
                          : () => _copy(context, state),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (busy) ...[
                LinearProgressIndicator(
                  value: state.uploading ? state.progress : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 8),
                Text(
                  state.uploading
                      ? l10n.tutorial_ownerGuide_upload_progress(
                          (state.progress * 100).toStringAsFixed(0),
                        )
                      : l10n.tutorial_common_loading,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state.pickedFileName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.pickedFileName!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.60),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => _pickAndUpload(context),
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(
                    state.uploading
                        ? l10n.common_uploading
                        : l10n.tutorial_ownerGuide_upload_replace_video,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _absUrl(String? path) {
    return urlu.absUrlFromDioBaseUrl(dioBaseUrl, path);
  }

  Future<void> _open(BuildContext context, TutorialVideoState state) async {
    final l10n = AppLocalizations.of(context)!;
    final abs = _absUrl(state.videoPath);
    final uri = Uri.tryParse(abs);

    if (uri == null) {
      AppToast.error(context, l10n.tutorial_ownerGuide_invalid_video_url);
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      AppToast.error(context, l10n.tutorial_ownerGuide_could_not_open_video);
    }
  }

  Future<void> _copy(BuildContext context, TutorialVideoState state) async {
    final l10n = AppLocalizations.of(context)!;
    final abs = _absUrl(state.videoPath);
    await Clipboard.setData(ClipboardData(text: abs));
    AppToast.success(context, l10n.tutorial_ownerGuide_copied_link);
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return;

    final f = picked.files.single;
    final path = f.path;

    if (path == null || path.trim().isEmpty) {
      AppToast.error(
        context,
        l10n.tutorial_ownerGuide_could_not_read_selected_file_path,
      );
      return;
    }

    context.read<TutorialVideoBloc>().add(
          TutorialVideoUploadRequested(
            filePath: path,
            fileName: f.name,
          ),
        );
  }
}