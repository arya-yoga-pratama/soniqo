import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/audio_provider.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';
import 'share_lyrics_preview.dart';
/// Pushes a full-screen overlay showing the currently playing song.
void showFullscreenPlayer(BuildContext context, {String? initialPanel}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FullscreenPlayer(initialPanel: initialPanel);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom
        final slideAnim = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));

        // Fade in simultaneously
        final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
          ),
        );

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: slideAnim, child: child),
        );
      },
    ),
  );
}

class FullscreenPlayer extends StatefulWidget {
  final String? initialPanel;
  const FullscreenPlayer({super.key, this.initialPanel});

  @override
  State<FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  late String? _activePanel;
  Timer? _colorTimer;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _activePanel = widget.initialPanel;
    _startColorPulsing();
  }

  void _startColorPulsing() {
    _colorTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted) return;
      final audio = Provider.of<AudioProvider>(context, listen: false);
      if (audio.isPlaying) {
        setState(() {
          double target = math.Random().nextDouble();
          _amplitude = (_amplitude * 0.7) + (target * 0.3);
        });
      } else if (_amplitude > 0.0) {
        setState(() {
          _amplitude = (_amplitude - 0.15).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    super.dispose();
  }

  void _togglePanel(String panel) {
    setState(() {
      if (_activePanel == panel) {
        _activePanel = null;
      } else {
        _activePanel = panel;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final song = audio.currentSong;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Blurred album art background ─────────────────────────────
              if (song != null)
                Image(image: song.imageProvider, fit: BoxFit.cover)
              else
                Container(color: const Color(0xFF0D0D0D)),

              // Blur + dark overlay + dynamic pulsing gradient
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.lerp(const Color(0xFF1A0F2E), const Color(0xFF2D1B4E), _amplitude)!,
                        Color.lerp(const Color(0xFF2D1B4E), const Color(0xFF6C3BFF), _amplitude * 0.8)!,
                        const Color(0xFF080810),
                      ],
                      stops: [
                        0.0,
                        0.5 + (_amplitude * 0.25),
                        1.0,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA54BFF).withValues(alpha: 0.2 * _amplitude),
                        blurRadius: 100,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              ),

              // Extra radial purple glow — top-left corner (behind album cover)
              Positioned(
                top: -80,
                left: -60,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA54BFF).withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle right-side glow accent
              Positioned(
                bottom: -40,
                right: -60,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7C3AED).withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      child: Row(
                        children: [
                          _IconBtn(
                            icon: Icons.keyboard_arrow_down_rounded,
                            size: 28,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Now Playing',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── LEFT: Album cover + info + controls ──────
                            Expanded(
                              flex: _activePanel == null ? 100 : 45,
                              child: LayoutBuilder(builder: (context, constraints) {
                                // Dynamically size the cover so the whole column fits
                                final coverSize = (constraints.maxHeight * 0.30).clamp(120.0, 180.0);
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: _activePanel == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, -30),
                                      child: VinylRecord(
                                        coverPath: song?.coverPath,
                                        isPlaying: audio.isPlaying,
                                        size: coverSize,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Contained area for metadata, progress, and controls (Glassmorphism)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: _activePanel == null ? 600 : double.infinity),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 30,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(28),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Reduced padding
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.05), // Lowered opacity
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.08), // Lowered border opacity
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  // Title + artist + like
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: _activePanel == null ? MainAxisAlignment.center : MainAxisAlignment.start,
                                                    children: [
                                                      if (_activePanel != null)
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                song?.title ?? '–',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.bold,
                                                                  letterSpacing: -0.4,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Text(
                                                                song?.artist ?? '–',
                                                                style: TextStyle(
                                                                  color: Colors.white.withValues(alpha: 0.55),
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w400,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Column(
                                                          children: [
                                                            Text(
                                                              song?.title ?? '–',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 22, // Slightly reduced
                                                                fontWeight: FontWeight.bold,
                                                                letterSpacing: -0.4,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              song?.artist ?? '–',
                                                              style: TextStyle(
                                                                color: Colors.white.withValues(alpha: 0.55),
                                                                fontSize: 14, // Slightly reduced
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (_activePanel != null) const SizedBox(width: 12),
                                                      if (_activePanel != null) _LikeButton(audio: audio),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 12), // Reduced spacing

                                                  // Progress bar
                                                  _ProgressBar(audio: audio, fmt: formatDuration),

                                                  const SizedBox(height: 4),

                                                  // Timestamps
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(formatDuration(audio.currentPosition),
                                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                                                      Text(formatDuration(audio.totalDuration),
                                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 10), // Moved closer to progress bar

                                                  // Playback controls
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      _ControlIcon(
                                                        icon: Icons.shuffle_rounded,
                                                        active: audio.isShuffle,
                                                        onTap: () => audio.toggleShuffle(),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 16),
                                                      _ControlIcon(
                                                        icon: Icons.skip_previous_rounded,
                                                        onTap: () => audio.previous(),
                                                        size: 28,
                                                      ),
                                                      const SizedBox(width: 20),
                                                      _PlayPauseButton(audio: audio),
                                                      const SizedBox(width: 20),
                                                      _ControlIcon(
                                                        icon: Icons.skip_next_rounded,
                                                        onTap: () => audio.next(),
                                                        size: 28,
                                                      ),
                                                      const SizedBox(width: 16),
                                                      _ControlIcon(
                                                        icon: audio.loopMode == RepeatState.one
                                                            ? Icons.repeat_one_rounded
                                                            : Icons.repeat_rounded,
                                                        active: audio.loopMode != RepeatState.off,
                                                        onTap: () => audio.toggleRepeat(),
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16), // Reduced spacing
                                    
                                    // ── Footer Actions (Lyrics, Queue, Volume) ──
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _FooterAction(
                                          icon: Icons.mic_none_rounded,
                                          label: 'Lyrics',
                                          active: _activePanel == 'lyrics',
                                          onTap: () => _togglePanel('lyrics'),
                                        ),
                                        const SizedBox(width: 42),
                                        _FooterAction(
                                          icon: Icons.queue_music_rounded,
                                          label: 'Queue',
                                          active: _activePanel == 'queue',
                                          onTap: () => _togglePanel('queue'),
                                        ),
                                        const SizedBox(width: 42),
                                        _VolumeControl(audio: audio),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ),

                            if (_activePanel != null) ...[
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 55,
                                child: Transform.translate(
                                  offset: const Offset(0, -24),
                                  child: _InfoPanel(
                                    song: song, 
                                    audio: audio, 
                                    activeTab: _activePanel!,
                                    onTabChanged: (tab) => setState(() => _activePanel = tab),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: size),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final AudioProvider audio;
  const _LikeButton({required this.audio});

  @override
  Widget build(BuildContext context) {
    final liked = audio.currentSong?.isLiked ?? false;
    return GestureDetector(
      onTap: () => audio.toggleLike(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: liked
              ? const Color(0xFFA54BFF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? const Color(0xFFA54BFF) : Colors.white.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioProvider audio;
  final String Function(Duration) fmt;
  const _ProgressBar({required this.audio, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pos = audio.currentPosition.inSeconds.toDouble();
    final total = audio.totalDuration.inSeconds.toDouble();
    final maxVal = total > 0 ? total : 1.0;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: const Color(0xFFA54BFF),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFA54BFF).withValues(alpha: 0.2),
      ),
      child: Slider(
        value: pos.clamp(0.0, maxVal),
        min: 0.0,
        max: maxVal,
        onChanged: (v) => audio.seek(Duration(seconds: v.toInt())),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final AudioProvider audio;
  const _VolumeSlider({required this.audio});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: const Color(0xFFA54BFF),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFA54BFF).withValues(alpha: 0.2),
        showValueIndicator: ShowValueIndicator.always,
        valueIndicatorShape: const DropSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        valueIndicatorColor: const Color(0xFFA54BFF),
      ),
      child: Slider(
        value: audio.volume,
        label: '${(audio.volume * 100).round()}',
        min: 0.0,
        max: 1.0,
        onChanged: (v) => audio.setVolume(v),
      ),
    );
  }
}

class _ControlIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;

  const _ControlIcon({
    required this.icon,
    required this.onTap,
    this.active = false,
    required this.size,
  });

  @override
  State<_ControlIcon> createState() => _ControlIconState();
}

class _ControlIconState extends State<_ControlIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: widget.active
                ? const Color(0xFFA54BFF)
                : Colors.white.withValues(alpha: _hovered ? 1.0 : 0.7),
            size: widget.size,
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final AudioProvider audio;
  const _PlayPauseButton({required this.audio});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.audio.togglePlayPause(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFA54BFF),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Icon(
            widget.audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final dynamic song;
  final AudioProvider audio;
  final String activeTab;
  final Function(String) onTabChanged;

  const _InfoPanel({
    required this.song, 
    required this.audio, 
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 52),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), // Lowered opacity
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), // Lowered border opacity
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tabs Header ─────────────────────────────────────────────
                Row(
                  children: [
                    _Tab(
                      label: 'LYRICS', 
                      active: activeTab == 'lyrics',
                      onTap: () => onTabChanged('lyrics'),
                    ),
                    const SizedBox(width: 32),
                    _Tab(
                      label: 'QUEUE', 
                      active: activeTab == 'queue',
                      onTap: () => onTabChanged('queue'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ── Content Area ──────────────────────────────
                Expanded(
                  child: activeTab == 'lyrics'
                      ? (audio.hasLyrics
                          ? _LyricsView(audio: audio)
                          : _EmptyLyricsState(audio: audio, song: song))
                      : const _QueueView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricsView extends StatefulWidget {
  final AudioProvider audio;
  const _LyricsView({required this.audio});

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIndices.clear();
    });
  }

  void _toggleLineSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _scrollToIndex(int index, double viewportHeight) {
    if (!_scrollController.hasClients) return;
    if (_isSelectionMode) return;
    if (index != _currentIndex && index >= 0) {
      _currentIndex = index;
      
      // Calculate target based on fixed item height (60.0)
      final double target = index * 60.0;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double clampedTarget = target.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutExpo,
      );
    }
  }

  void _showPreview(List<dynamic> lyrics) {
    if (widget.audio.currentSong == null) return;
    
    final sortedIndices = _selectedIndices.toList()..sort();
    final selectedText = sortedIndices.map((i) => lyrics[i].text as String).toList();

    showDialog(
      context: context,
      builder: (context) => ShareLyricsPreviewModal(
        song: widget.audio.currentSong!,
        selectedLyrics: selectedText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.audio.currentLyrics;
    final position = widget.audio.currentPosition;

    int activeIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (position >= lyrics[i].time) {
        activeIndex = i;
      } else {
        break;
      }
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vHeight = constraints.maxHeight;
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _scrollToIndex(activeIndex, vHeight);
              });

              return Stack(
                children: [
                  ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: lyrics.length,
            // Fixed item height (60.0) centering logic
            padding: EdgeInsets.symmetric(vertical: vHeight / 2 - 30),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final line = lyrics[index];
              final distance = (index - activeIndex).abs();
              final isActive = index == activeIndex;
              final isSelected = _isSelectionMode && _selectedIndices.contains(index);
              
              // Modern karaoke depth effects
              final opacity = _isSelectionMode
                  ? (isSelected ? 1.0 : 0.6)
                  : (1.0 - (distance * 0.25)).clamp(0.08, 1.0);
              final scale = _isSelectionMode
                  ? 1.0
                  : (1.0 - (distance * 0.04)).clamp(0.85, 1.0);
              final blurAmount = _isSelectionMode
                  ? 0.0
                  : (isActive ? 0.0 : (distance * 0.8).clamp(0.0, 3.0));

              return GestureDetector(
                onTap: _isSelectionMode ? () => _toggleLineSelection(index) : null,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  color: Colors.transparent, // Ensures the tap area spans the full width
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: opacity,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: scale,
                      curve: Curves.easeOutBack,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isSelectionMode)
                            Positioned(
                              left: 20,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            key: ValueKey('selected'),
                                            color: Color(0xFFA54BFF),
                                            size: 24,
                                          )
                                        : Icon(
                                            Icons.circle_outlined,
                                            key: const ValueKey('unselected'),
                                            color: Colors.white.withValues(alpha: 0.3),
                                            size: 24,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 56.0),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isSelectionMode
                                    ? (isSelected ? const Color(0xFFA54BFF) : Colors.white)
                                    : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.6)),
                                fontSize: _isSelectionMode
                                    ? 20
                                    : (isActive ? 24 : 18),
                                fontWeight: _isSelectionMode
                                    ? FontWeight.w700
                                    : (isActive ? FontWeight.w800 : FontWeight.w500),
                                height: 1.2,
                                letterSpacing: _isSelectionMode ? 0.2 : (isActive ? 0.0 : 0.2),
                                shadows: [
                                  if (isActive && !_isSelectionMode)
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  if (blurAmount > 0)
                                    Shadow(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      blurRadius: blurAmount,
                                    ),
                                ],
                              ),
                              child: Text(line.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Action Buttons (Floating)
        if (!_isSelectionMode)
          Align(
            key: const ValueKey('actions_row'),
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _KaraokeBtn(audio: widget.audio),
                  _KaraokeSettingsBtn(audio: widget.audio),
                  const SizedBox(width: 8),
                  _ShareLyricsBtn(onTap: _toggleSelectionMode),
                ],
              ),
            ),
          ),
      ],
    );
  },
),
),

        // Action Bar for Selection Mode
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _isSelectionMode
              ? Container(
                  key: const ValueKey('selection_mode'),
                  padding: const EdgeInsets.only(top: 16.0), // Extra space on top of the button row
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: _toggleSelectionMode,
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      if (_selectedIndices.isNotEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.preview_rounded, size: 18),
                          label: const Text('Preview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA54BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            minimumSize: const Size(0, 40),
                          ),
                          onPressed: () => _showPreview(lyrics),
                        )
                      else
                        const SizedBox(height: 40), // Placeholder to maintain the height
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}

class _ShareLyricsBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _ShareLyricsBtn({required this.onTap});

  @override
  State<_ShareLyricsBtn> createState() => _ShareLyricsBtnState();
}

class _ShareLyricsBtnState extends State<_ShareLyricsBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.ios_share_rounded,
            color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.5),
            size: 22,
            shadows: _hovered
                ? [
                    Shadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _KaraokeBtn extends StatefulWidget {
  final AudioProvider audio;
  const _KaraokeBtn({required this.audio});

  @override
  State<_KaraokeBtn> createState() => _KaraokeBtnState();
}

class _KaraokeBtnState extends State<_KaraokeBtn> {
  bool _hovered = false;

  void _handleTap() async {
    final song = widget.audio.currentSong;
    if (song == null) return;

    if (song.karaokePath != null && File(song.karaokePath!).existsSync()) {
      widget.audio.toggleKaraokeMode();
    } else {
      // Show upload dialog
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Karaoke Track Not Found', style: TextStyle(color: Colors.white)),
          content: const Text(
            "This song doesn't have a karaoke version yet.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA54BFF)),
              child: const Text('Upload Karaoke File', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldUpload == true) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3'],
        );

        if (result != null && result.files.single.path != null) {
          await widget.audio.uploadKaraokePath(song, result.files.single.path!);
          widget.audio.toggleKaraokeMode();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.audio.isKaraokeMode;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.mic_rounded,
            color: isActive 
                ? const Color(0xFFE0B0FF) // Bright purple when active
                : (_hovered ? Colors.white : Colors.white.withValues(alpha: 0.5)),
            size: 22,
            shadows: (isActive || _hovered)
                ? [
                    Shadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _KaraokeSettingsBtn extends StatefulWidget {
  final AudioProvider audio;
  const _KaraokeSettingsBtn({required this.audio});

  @override
  State<_KaraokeSettingsBtn> createState() => _KaraokeSettingsBtnState();
}

class _KaraokeSettingsBtnState extends State<_KaraokeSettingsBtn> {
  bool _hovered = false;

  void _showSettingsDialog() {
    final song = widget.audio.currentSong;
    if (song == null) return;

    final hasKaraoke = song.karaokePath != null && File(song.karaokePath!).existsSync();
    final fileName = hasKaraoke ? song.karaokePath!.split(RegExp(r'[\\/]')).last : 'None';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_voice_rounded, color: Color(0xFFA54BFF)),
            const SizedBox(width: 12),
            const Text('Karaoke Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current File:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 4),
            Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 24),
            
            // Replace / Add Button
            ElevatedButton.icon(
              icon: Icon(hasKaraoke ? Icons.file_upload_outlined : Icons.add_rounded, size: 18),
              label: Text(hasKaraoke ? 'Replace Karaoke File' : 'Add Karaoke File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // close settings dialog
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['mp3'],
                );
                if (result != null && result.files.single.path != null) {
                  await widget.audio.uploadKaraokePath(song, result.files.single.path!);
                  // Auto enable if replaced/added and not active
                  if (!widget.audio.isKaraokeMode) {
                    widget.audio.toggleKaraokeMode();
                  }
                }
              },
            ),
            
            if (hasKaraoke) ...[
              const SizedBox(height: 12),
              // Remove Button
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove Karaoke File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // close settings dialog
                  // Confirm
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Remove Karaoke?', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to remove the karaoke file from this song?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).pop(true), 
                          child: const Text('Remove', style: TextStyle(color: Colors.white))
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await widget.audio.removeKaraokePath(song);
                  }
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showSettingsDialog,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.5),
            size: 20,
            shadows: _hovered
                ? [Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final playlist = audio.playlist;
        final currentSong = audio.currentSong;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            itemCount: playlist.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final song = playlist[index];
              final isPlaying = currentSong?.id == song.id;

              return ListTile(
                onTap: () => audio.playSong(song, playlist: playlist),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image(
                    image: song.imageProvider,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  style: TextStyle(
                    color: isPlaying ? const Color(0xFFA54BFF) : Colors.white,
                    fontSize: 14,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: isPlaying
                    ? const Icon(Icons.bar_chart_rounded, color: Color(0xFFA54BFF), size: 20)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.25),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            width: active ? 24 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFFA54BFF),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: const Color(0xFFA54BFF).withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLyricsState extends StatefulWidget {
  final AudioProvider audio;
  final dynamic song;

  const _EmptyLyricsState({required this.audio, required this.song});

  @override
  State<_EmptyLyricsState> createState() => _EmptyLyricsStateState();
}

class _EmptyLyricsStateState extends State<_EmptyLyricsState> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickLrcFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc'],
        dialogTitle: 'Select LRC Lyrics File',
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) setState(() {
          _isLoading = false;
          _errorMessage = 'Could not access the selected file.';
        });
        return;
      }

      // Validate extension
      if (!filePath.toLowerCase().endsWith('.lrc')) {
        if (mounted) setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid file type. Please select a .lrc file.';
        });
        return;
      }

      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) setState(() {
          _isLoading = false;
          _errorMessage = 'File not found or inaccessible.';
        });
        return;
      }

      // Validate LRC content has at least one timestamp
      final content = await file.readAsString();
      final timeRegex = RegExp(r'\[\d+:\d+');
      if (!timeRegex.hasMatch(content)) {
        if (mounted) setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid .lrc file — no timestamps found.';
        });
        return;
      }

      final song = widget.song;
      if (song == null) {
        if (mounted) setState(() {
          _isLoading = false;
          _errorMessage = 'No song is currently playing.';
        });
        return;
      }

      // Save + reload
      await widget.audio.uploadLyricsPath(song, filePath);

      if (mounted) setState(() { _isLoading = false; _errorMessage = null; });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.error_outline_rounded : Icons.lyrics_outlined,
              color: hasError
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            hasError ? 'UPLOAD FAILED' : 'NO LYRICS',
            style: TextStyle(
              color: hasError
                  ? Colors.red.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle / error
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Upload a .lrc file to sync lyrics with this track.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasError
                    ? Colors.red.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.12),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Upload button or spinner
          if (_isLoading)
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFA54BFF),
              ),
            )
          else
            _UploadButton(
              label: hasError ? 'Try Again' : 'Upload .lrc File',
              onTap: _pickLrcFile,
            ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _UploadButton({required this.label, required this.onTap});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFA54BFF).withValues(alpha: 0.25)
                : const Color(0xFFA54BFF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFA54BFF).withValues(alpha: _hovered ? 0.6 : 0.35),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_rounded, color: Color(0xFFA54BFF), size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFFA54BFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FooterAction({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: active ? const Color(0xFFA54BFF) : Colors.white.withValues(alpha: 0.7), 
              size: 22
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFA54BFF) : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final AudioProvider audio;
  const _VolumeControl({required this.audio});

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    // Remove the overlay directly — do NOT call setState here (widget is defunct)
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleSlider() {
    if (_overlayEntry == null) {
      _showSlider();
    } else {
      _hideSlider();
    }
  }

  void _showSlider() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hideSlider() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
    // Note: dispose() bypasses this method intentionally to avoid setState on defunct element
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideSlider,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(size.width + 8, size.height / 2 - 20),
              child: Consumer<AudioProvider>(
                builder: (context, audio, _) => Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 140,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFFA54BFF),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        thumbColor: Colors.white,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        showValueIndicator: ShowValueIndicator.always,
                        valueIndicatorShape: const DropSliderValueIndicatorShape(),
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        valueIndicatorColor: const Color(0xFFA54BFF),
                      ),
                      child: Slider(
                        value: audio.volume,
                        label: '${(audio.volume * 100).round()}',
                        onChanged: (v) => audio.setVolume(v),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleSlider,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.audio.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                'Volume',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Vinyl Record Component
// ──────────────────────────────────────────────────────────────────────────────

class VinylRecord extends StatefulWidget {
  final String? coverPath;
  final bool isPlaying;
  final double size;

  const VinylRecord({
    super.key,
    required this.coverPath,
    required this.isPlaying,
    required this.size,
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _visualizerController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slow, elegant rotation
    );
    
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
      _visualizerController.repeat();
      _fadeController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
        _visualizerController.repeat();
        _fadeController.forward();
      } else {
        _rotationController.stop();
        _fadeController.reverse().then((_) {
          if (!mounted) return;
          _visualizerController.stop();
        });
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _visualizerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Modern Purple Visualizer ──
          AnimatedBuilder(
            animation: Listenable.merge([_visualizerController, _fadeController]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularVisualizerPainter(
                  animationValue: _visualizerController.value,
                  fadeValue: _fadeController.value,
                ),
              );
            },
          ),

          // The Rotating Vinyl Disc
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0A0A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 35,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle concentric rings (grooves)
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _VinylTexturePainter(),
                  ),
                  
                  // Disc outer rim highlight
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Center Album Art (The Label)
                  Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.size),
                      child: buildCoverImage(widget.coverPath ?? '', fit: BoxFit.cover),
                    ),
                  ),

                  // The Center Hole
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Static Gloss Overlay (provides depth, does not rotate)
          IgnorePointer(
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.25, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VinylTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw many fine concentric circles for vinyl grooves
    for (double r = maxRadius * 0.42; r < maxRadius - 3; r += 2.0) {
      // Subtle variations in opacity for realism
      final opacity = 0.008 + (0.012 * (r % 7) / 7);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, r, paint);
    }
    
    // Major groove separators
    paint.strokeWidth = 0.8;
    for (double r in [maxRadius * 0.55, maxRadius * 0.72, maxRadius * 0.88]) {
      paint.color = Colors.white.withValues(alpha: 0.03);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircularVisualizerPainter extends CustomPainter {
  final double animationValue;
  final double fadeValue;

  _CircularVisualizerPainter({
    required this.animationValue,
    required this.fadeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fadeValue == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final int numBars = 72; // dense bars
    final double angleStep = (2 * math.pi) / numBars;
    final double t = animationValue * math.pi * 2; 

    for (int i = 0; i < numBars; i++) {
      final double angle = i * angleStep;
      
      // Complex wave composition to simulate real audio spectrum
      double wave1 = math.sin(i * 0.3 + t * 3.0);
      double wave2 = math.cos(i * 0.8 - t * 2.0);
      double wave3 = math.sin(i * 1.5 + t * 4.0);
      double wave4 = math.cos(i * 0.1 + t * 1.0);
      
      double amplitude = (wave1 + wave2 + wave3 + wave4) / 4.0;
      // Map to 0..1
      amplitude = (amplitude + 1.0) / 2.0;
      
      // Make it spiky
      amplitude = amplitude * amplitude;

      final double maxBarHeight = 24.0; // max length of bars
      final double minBarHeight = 3.0;
      
      final double barHeight = minBarHeight + (amplitude * maxBarHeight * fadeValue);
      
      final Offset startPoint = Offset(
        center.dx + math.cos(angle) * (baseRadius + 8),
        center.dy + math.sin(angle) * (baseRadius + 8),
      );
      
      final Offset endPoint = Offset(
        center.dx + math.cos(angle) * (baseRadius + 12 + barHeight),
        center.dy + math.sin(angle) * (baseRadius + 12 + barHeight),
      );

      // Opacity and color based on amplitude and fadeValue
      final double opacity = (0.2 + (0.8 * amplitude)) * fadeValue;
      paint.color = const Color(0xFFA54BFF).withValues(alpha: opacity.clamp(0.0, 1.0));
      
      // Add a subtle purple glow behind bars using a shadow
      if (amplitude > 0.5) {
        paint.strokeWidth = 4.0;
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 8.0
          ..color = const Color(0xFFA54BFF).withValues(alpha: (opacity * 0.5).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawLine(startPoint, endPoint, glowPaint);
      } else {
        paint.strokeWidth = 3.0;
      }
      
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularVisualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.fadeValue != fadeValue;
  }
}
