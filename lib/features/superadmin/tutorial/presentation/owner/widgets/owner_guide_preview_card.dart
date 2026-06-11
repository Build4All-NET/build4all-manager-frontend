import 'dart:async';

import 'package:build4all_manager/features/superadmin/tutorial/data/services/tutorial_api.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _videoPath;
  String? _videoUrl;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  late final TutorialApi _api = TutorialApi(widget.dio);

  @override
  void initState() {
    super.initState();
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

  String _absUrl(String? path) {
    return urlu.absUrlFromDioBaseUrl(widget.dio.options.baseUrl, path);
  }

  bool _isDirectVideoUrl(String url) {
    final clean = url.toLowerCase().split('?').first;

    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.m4v') ||
        clean.contains('/uploads/');
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _videoLoading = false;
      _error = null;
    });

    try {
      final path = await _api.getOwnerGuide();
      final cleaned = (path == null || path.trim().isEmpty) ? null : path.trim();

      _videoPath = cleaned;

      await _disposeController();

      // ✅ If no video exists, owner details shows nothing.
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

      // ✅ If URL is not direct mp4/upload video, show simple open button.
      // Example: YouTube links cannot play with video_player directly.
      if (!_isDirectVideoUrl(abs)) {
        if (!mounted) return;
        setState(() {
          _videoUrl = abs;
          _loading = false;
          _videoLoading = false;
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

  Future<void> _openExternal() async {
    final url = _videoUrl;
    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    // ✅ While loading, show nothing in owner details.
    // This avoids empty placeholder/jumping UI.
    if (_loading) {
      return const SizedBox.shrink();
    }

    // ✅ If no video, show nothing.
    if (_videoPath == null || _videoPath!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ If backend/API error, show nothing for owner side.
    // Owner should not see technical error in details.
    if (_error != null) {
      return const SizedBox.shrink();
    }

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
                onPressed: _videoLoading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_videoUrl != null && _controller == null) ...[
            // ✅ For YouTube / external URLs: video_player cannot play them.
            // Show clean button only.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Watch tutorial'),
              ),
            ),
          ] else if (_controller != null &&
              _controller!.value.isInitialized) ...[
            _buildVideoPlayer(context),
          ] else ...[
            const SizedBox.shrink(),
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
                          onTap: () =>
                              _seekRelative(const Duration(seconds: -10)),
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
                          onTap: () =>
                              _seekRelative(const Duration(seconds: 10)),
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
                            padding:
                                const EdgeInsets.fromLTRB(10, 6, 10, 8),
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
                                  tooltip:
                                      l10n.tutorial_player_exitFullscreen,
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