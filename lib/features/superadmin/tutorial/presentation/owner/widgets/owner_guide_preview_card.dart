import 'dart:async';

import 'package:build4all_manager/features/superadmin/tutorial/data/services/tutorial_api.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:build4all_manager/core/network/url_utils.dart' as urlu;

class OwnerGuidePreviewCard extends StatefulWidget {
  final Dio dio;

  const OwnerGuidePreviewCard({
    super.key,
    required this.dio,
  });

  @override
  State<OwnerGuidePreviewCard> createState() => _OwnerGuidePreviewCardState();
}

class _OwnerGuidePreviewCardState extends State<OwnerGuidePreviewCard> {
  VideoPlayerController? _controller;

  bool _loading = true;
  bool _videoLoading = false;
  String? _error;
  String? _videoPath; // raw from api (/uploads/...)
  String? _videoUrl; // absolute
  bool _showControls = true;
  Timer? _hideControlsTimer;

  TutorialApi? _api;

  @override
  void initState() {
    super.initState();
    _api = TutorialApi(widget.dio);
    _load();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_onVideoTick);
      await c.dispose();
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    setState(() {});
  }

  void _restartAutoHideTimer() {
    _hideControlsTimer?.cancel();
    final c = _controller;
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (!c.value.isPlaying) return;

    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  String _absUrl(String? path) {
    return urlu.absUrlFromDioBaseUrl(widget.dio.options.baseUrl, path);
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _videoLoading = false;
      _error = null;
    });

    try {
      final path = await _api!.getOwnerGuide(); // public endpoint
      final cleaned = (path == null || path.trim().isEmpty) ? null : path.trim();

      _videoPath = cleaned;

      await _disposeController();

      if (cleaned == null) {
        if (!mounted) return;
        setState(() {
          _videoUrl = null;
          _loading = false;
        });
        return;
      }

      final abs = _absUrl(cleaned);
      final uri = Uri.tryParse(abs);
      if (uri == null) {
        if (!mounted) return;
        setState(() {
          _videoUrl = null;
          _error = 'Invalid video URL';
          _loading = false;
        });
        return;
      }

      setState(() {
        _videoLoading = true;
      });

      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(1.0);

      controller.addListener(_onVideoTick);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;

      setState(() {
        _videoUrl = abs;
        _loading = false;
        _videoLoading = false;
        _showControls = true;
      });
       } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _videoLoading = false;
        _error = ApiErrorHandler.message(e);
      });
    }
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    if (c.value.isPlaying) {
      await c.pause();
      if (!mounted) return;
      setState(() => _showControls = true);
    } else {
      await c.play();
      if (!mounted) return;
      setState(() => _showControls = true);
      _restartAutoHideTimer();
    }
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final current = c.value.position;
    final duration = c.value.duration;

    var target = current + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;

    await c.seekTo(target);
    _restartAutoHideTimer();
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    final url = _videoUrl;
    if (c == null || url == null || !c.value.isInitialized) return;

    final currentPos = c.value.position;
    final wasPlaying = c.value.isPlaying;

    await c.pause();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OwnerGuideFullscreenPlayerPage(
          videoUrl: url,
          initialPosition: currentPos,
          autoPlay: wasPlaying,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _showControls = true);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _restartAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: l10n.tutorial_common_refresh,
                onPressed: _loading || _videoLoading ? null : _load,
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

          if (_loading) ...[
            const LinearProgressIndicator(minHeight: 8),
            const SizedBox(height: 8),
            Text(
              l10n.tutorial_common_loading,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorial_common_failedToLoad,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.75),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.tutorial_common_retry),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_controller == null || !_controller!.value.isInitialized) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.tutorial_ownerGuide_notSetYet,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            _buildVideoPlayer(context),
            const SizedBox(height: 12),

            // ✅ L10N tutorial steps (now visible under the video)
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

            const SizedBox(height: 10),

            // Optional debug path display
           /*  if (_videoPath != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _videoPath!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.75),
                    fontWeight: FontWeight.w600,
                  ),
                ), 
              ),*/
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final c = _controller!;
    final v = c.value;

    final isPlaying = v.isPlaying;
    final pos = v.position;
    final dur = v.duration;
    final finished = dur > Duration.zero && pos >= dur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: (v.aspectRatio <= 0) ? (16 / 9) : v.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.black),
                  VideoPlayer(c),

                  if (_videoLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (_showControls)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(.18),
                      ),
                    ),

                  if (_showControls)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleControlButton(
                          icon: Icons.replay_10_rounded,
                          tooltip: l10n.tutorial_player_back10,
                          onTap: () => _seekRelative(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 10),
                        _CircleControlButton(
                          icon: (isPlaying && !finished)
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          tooltip: (isPlaying && !finished)
                              ? l10n.tutorial_player_pause
                              : l10n.tutorial_player_play,
                          big: true,
                          onTap: _togglePlayPause,
                        ),
                        const SizedBox(width: 10),
                        _CircleControlButton(
                          icon: Icons.forward_10_rounded,
                          tooltip: l10n.tutorial_player_forward10,
                          onTap: () => _seekRelative(const Duration(seconds: 10)),
                        ),
                      ],
                    ),

                  if (_showControls)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CircleControlButton(
                        icon: Icons.fullscreen_rounded,
                        tooltip: l10n.tutorial_player_fullscreen,
                        onTap: _openFullscreen,
                      ),
                    ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          c,
                          allowScrubbing: true,
                          padding: EdgeInsets.zero,
                          colors: VideoProgressColors(
                            playedColor: cs.primary,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        if (_showControls)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                            color: Colors.black.withOpacity(.28),
                            child: Text(
                              '${_fmt(pos)} / ${_fmt(dur)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _togglePlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  isPlaying
                      ? l10n.tutorial_player_pause
                      : l10n.tutorial_player_play,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openFullscreen,
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(l10n.tutorial_player_fullscreen),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final totalSec = d.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;

    String two(int n) => n.toString().padLeft(2, '0');

    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
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

class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool big;

  const _CircleControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 54.0 : 42.0;
    final iconSize = big ? 30.0 : 22.0;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _OwnerGuideFullscreenPlayerPage extends StatefulWidget {
  final String videoUrl;
  final Duration initialPosition;
  final bool autoPlay;

  const _OwnerGuideFullscreenPlayerPage({
    required this.videoUrl,
    required this.initialPosition,
    required this.autoPlay,
  });

  @override
  State<_OwnerGuideFullscreenPlayerPage> createState() =>
      _OwnerGuideFullscreenPlayerPageState();
}

class _OwnerGuideFullscreenPlayerPageState
    extends State<_OwnerGuideFullscreenPlayerPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _enterFullscreenUi();
    _init();
  }

  Future<void> _enterFullscreenUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitFullscreenUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      await c.seekTo(widget.initialPosition);
      await c.setLooping(false);

      c.addListener(_tick);

      if (widget.autoPlay) {
        await c.play();
        _restartAutoHideTimer();
      }

      if (!mounted) {
        await c.dispose();
        return;
      }

      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
  }

  void _restartAutoHideTimer() {
    _hideControlsTimer?.cancel();
    final c = _controller;
    if (c == null || !c.value.isPlaying) return;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_tick);
      c.dispose();
    }
    _exitFullscreenUi();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
      if (!mounted) return;
      setState(() => _showControls = true);
    } else {
      await c.play();
      if (!mounted) return;
      setState(() => _showControls = true);
      _restartAutoHideTimer();
    }
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final current = c.value.position;
    final duration = c.value.duration;
    var target = current + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    await c.seekTo(target);
    _restartAutoHideTimer();
  }

  String _fmt(Duration d) {
    final totalSec = d.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (c == null || !c.value.isInitialized)
                ? Center(
                    child: Text(
                      l10n.tutorial_common_failedToLoad,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => _showControls = !_showControls);
                      if (_showControls) _restartAutoHideTimer();
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: c.value.aspectRatio <= 0
                                ? (16 / 9)
                                : c.value.aspectRatio,
                            child: VideoPlayer(c),
                          ),
                        ),

                        if (_showControls)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(.15),
                            ),
                          ),

                        if (_showControls)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  tooltip: MaterialLocalizations.of(context)
                                      .backButtonTooltip,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.fullscreen_exit_rounded,
                                    color: Colors.white,
                                  ),
                                  tooltip: l10n.tutorial_player_exitFullscreen,
                                ),
                              ],
                            ),
                          ),

                        if (_showControls)
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CircleControlButton(
                                  icon: Icons.replay_10_rounded,
                                  tooltip: l10n.tutorial_player_back10,
                                  onTap: () => _seekRelative(
                                    const Duration(seconds: -10),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _CircleControlButton(
                                  icon: c.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  tooltip: c.value.isPlaying
                                      ? l10n.tutorial_player_pause
                                      : l10n.tutorial_player_play,
                                  big: true,
                                  onTap: _togglePlayPause,
                                ),
                                const SizedBox(width: 12),
                                _CircleControlButton(
                                  icon: Icons.forward_10_rounded,
                                  tooltip: l10n.tutorial_player_forward10,
                                  onTap: () => _seekRelative(
                                    const Duration(seconds: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                c,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              if (_showControls)
                                Container(
                                  width: double.infinity,
                                  color: Colors.black.withOpacity(.4),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 6, 12, 10),
                                  child: Text(
                                    '${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}