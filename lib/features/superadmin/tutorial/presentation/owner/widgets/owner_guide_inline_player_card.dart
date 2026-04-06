import 'dart:async';

import 'package:build4all_manager/features/superadmin/tutorial/data/repositories/tutorial_repository_impl.dart';
import 'package:build4all_manager/features/superadmin/tutorial/data/services/tutorial_api.dart';
import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/get_owner_guide_video.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/core/network/url_utils.dart' as urlu;



class OwnerGuideInlinePlayerCard extends StatefulWidget {
  final Dio dio;

  const OwnerGuideInlinePlayerCard({
    super.key,
    required this.dio,
  });

  @override
  State<OwnerGuideInlinePlayerCard> createState() =>
      _OwnerGuideInlinePlayerCardState();
}

class _OwnerGuideInlinePlayerCardState extends State<OwnerGuideInlinePlayerCard> {
  bool _loading = true;
  String? _error;
  String? _videoPath; // relative or absolute from API
  VideoPlayerController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = TutorialApi(widget.dio);
      final repo = TutorialRepositoryImpl(api);
      final usecase = GetOwnerGuideVideo(repo);

      final path = await usecase.call(); // public endpoint, token not required

      if (!mounted) return;

      final cleaned = (path == null || path.trim().isEmpty) ? null : path.trim();
      _videoPath = cleaned;

      if (cleaned == null) {
        setState(() {
          _loading = false;
          _error = null; // just no video yet
        });
        return;
      }

      final abs = urlu.absUrlFromDioBaseUrl(widget.dio.options.baseUrl, cleaned);

      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(Uri.parse(abs));

      _initFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        _controller!.setLooping(false);
        _controller!.setVolume(1.0);
      });

      await _initFuture;

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
       } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiErrorHandler.message(e);
      });
    }
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openFullscreen() async {
    final path = _videoPath;
    if (path == null || path.isEmpty) return;

    final abs = urlu.absUrlFromDioBaseUrl(widget.dio.options.baseUrl, path);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OwnerGuideFullscreenPlayer(videoUrl: abs),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 14),
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
                  l10n.owner_proj_details_tutorial_title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: l10n.common_refresh,
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.owner_proj_details_tutorial_subtitle,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(.75),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          if (_loading) ...[
            const LinearProgressIndicator(minHeight: 6),
            const SizedBox(height: 10),
            Text(
              l10n.common_loading,
              style: tt.bodySmall,
            ),
          ] else if (_error != null) ...[
            _ErrorBox(text: _error!),
          ] else if (_controller == null || _videoPath == null) ...[
            _InfoBox(text: l10n.owner_proj_details_tutorial_not_set),
          ] else ...[
            FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                final c = _controller!;
                if (snapshot.connectionState != ConnectionState.done ||
                    !c.value.isInitialized) {
                  return const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final ratio = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: ratio,
                          child: VideoPlayer(c),
                        ),

                        // tap-to-play overlay
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedOpacity(
                                opacity: c.value.isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // controls bar
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: Colors.white,
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    c.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    c,
                                    allowScrubbing: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: Colors.white,
                                  tooltip: l10n.owner_proj_details_tutorial_fullscreen,
                                  onPressed: _openFullscreen,
                                  icon: const Icon(Icons.fullscreen_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ✅ l10n steps based on your video
            Text(
              l10n.owner_proj_details_tutorial_steps_title,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _StepItem(index: 1, text: l10n.owner_proj_details_tutorial_step_1),
            _StepItem(index: 2, text: l10n.owner_proj_details_tutorial_step_2),
            _StepItem(index: 3, text: l10n.owner_proj_details_tutorial_step_3),
            _StepItem(index: 4, text: l10n.owner_proj_details_tutorial_step_4),
            _StepItem(index: 5, text: l10n.owner_proj_details_tutorial_step_5),
            _StepItem(index: 6, text: l10n.owner_proj_details_tutorial_step_6),
            _StepItem(index: 7, text: l10n.owner_proj_details_tutorial_step_7),
            _StepItem(index: 8, text: l10n.owner_proj_details_tutorial_step_8),
          ],
        ],
      ),
    );
  }
}

class _OwnerGuideFullscreenPlayer extends StatefulWidget {
  final String videoUrl;
  const _OwnerGuideFullscreenPlayer({required this.videoUrl});

  @override
  State<_OwnerGuideFullscreenPlayer> createState() =>
      _OwnerGuideFullscreenPlayerState();
}

class _OwnerGuideFullscreenPlayerState extends State<_OwnerGuideFullscreenPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initFuture = _controller.initialize().then((_) async {
      await _controller.setLooping(false);
      await _controller.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.owner_proj_details_tutorial_title),
      ),
      body: SafeArea(
        child: Center(
          child: FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  !_controller.value.isInitialized) {
                return const CircularProgressIndicator(color: Colors.white);
              }

              final ratio = _controller.value.aspectRatio == 0
                  ? 16 / 9
                  : _controller.value.aspectRatio;

              return Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: ratio,
                    child: VideoPlayer(_controller),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: AnimatedOpacity(
                        opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          color: Colors.black.withOpacity(.15),
                          alignment: Alignment.center,
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            color: Colors.white,
                            onPressed: _togglePlay,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final String text;

  const _StepItem({
    required this.index,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: cs.onErrorContainer),
      ),
    );
  }
}