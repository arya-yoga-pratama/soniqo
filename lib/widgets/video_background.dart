import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

/// Persistent fullscreen video background.
/// Place this as the BOTTOM layer of a Stack at a high widget-tree level
/// so it is never removed/recreated during navigation.
class VideoBackground extends StatefulWidget {
  /// Relative asset path, e.g. 'assets/videobacground/background.mp4'
  final String assetPath;

  /// Overlay opacity applied on top of the video (0 = transparent, 1 = fully black).
  final double overlayOpacity;

  const VideoBackground({
    super.key,
    required this.assetPath,
    this.overlayOpacity = 0.55,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    _controller = VideoController(_player);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final String videoPath;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final executableDir = File(Platform.resolvedExecutable).parent.path;
        final normalizedAsset =
            widget.assetPath.replaceAll('/', Platform.pathSeparator);
        videoPath =
            p.join(executableDir, 'data', 'flutter_assets', normalizedAsset);
        debugPrint('[VideoBackground] Loading: $videoPath');
      } else {
        videoPath = 'asset:///${widget.assetPath}';
      }

      await _player.open(Media(videoPath), play: true);
      await _player.setVolume(0.0);
      await _player.setPlaylistMode(PlaylistMode.loop);
      debugPrint('[VideoBackground] ✅ Playing');
    } catch (e) {
      debugPrint('[VideoBackground] ❌ ERROR: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Video ──────────────────────────────────────────────────────────
        Video(
          controller: _controller,
          fill: const Color(0xFF0A0A0F),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          controls: NoVideoControls,
        ),

        // ── Dark overlay for readability ───────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: widget.overlayOpacity),
                Colors.black.withValues(
                    alpha: (widget.overlayOpacity + 0.05).clamp(0.0, 1.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
