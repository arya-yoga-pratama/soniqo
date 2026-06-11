import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'fullscreen_player.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});



  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioProvider, ThemeProvider>(
      builder: (context, audioProvider, themeProvider, child) {
        final accentColor = themeProvider.accentColor;
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        final isDarkMode = themeProvider.isDarkMode;
        final currentSong = audioProvider.currentSong;

        return Container(
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                  ? const [Color(0xFF1A1235), Color(0xFF121212), Color(0xFF0F0F0F)]
                  : [theme.surfaceColor, theme.backgroundColor],
            ),
            border: Border(
              top: BorderSide(
                color: theme.borderColor,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ---------------------------------------------------
              // Left Section: Current Song Info
              // ---------------------------------------------------
              Expanded(
                flex: 3,
                child: currentSong != null
                    ? Row(
                        children: [
                          // Album Art
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: getImageProvider(currentSong.coverPath),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Track & Artist Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong.artist,
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Favorite Button
                          IconButton(
                            icon: Icon(
                              currentSong.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                            ),
                            color: currentSong.isLiked
                                ? accentColor
                                : theme.textSecondaryColor,
                            onPressed: () {
                              audioProvider.toggleLike();
                            },
                            tooltip: 'Save to Your Library',
                          ),
                          const SizedBox(
                            width: 16,
                          ), // Memberi jarak agar ikon geser ke kiri
                        ],
                      )
                    : const SizedBox(),
              ),

              // ---------------------------------------------------
              // Center Section: Player Controls & Progress Bar
              // ---------------------------------------------------
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // Playback Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle, size: 20),
                          color: audioProvider.isShuffle
                              ? accentColor
                              : theme.textSecondaryColor,
                          onPressed: () => audioProvider.toggleShuffle(),
                          tooltip: 'Enable shuffle',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 24),
                          color: audioProvider.playlist.isNotEmpty
                              ? theme.textColor
                              : theme.textSecondaryColor.withOpacity(0.3),
                          onPressed: audioProvider.playlist.isNotEmpty
                              ? () => audioProvider.previous()
                              : null,
                          tooltip: 'Previous',
                        ),
                        const SizedBox(width: 16),

                        // Play/Pause Button
                        _AnimatedPlayButton(
                          isEnabled: audioProvider.playlist.isNotEmpty,
                          isPlaying: audioProvider.isPlaying,
                          accentColor: accentColor,
                          onPressed: () => audioProvider.togglePlayPause(),
                        ),

                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 24),
                          color: audioProvider.playlist.isNotEmpty
                              ? theme.textColor
                              : theme.textSecondaryColor.withOpacity(0.3),
                          onPressed: audioProvider.playlist.isNotEmpty
                              ? () => audioProvider.next()
                              : null,
                          tooltip: 'Next',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            audioProvider.loopMode == RepeatState.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            size: 20,
                          ),
                          color: audioProvider.loopMode != RepeatState.off
                              ? accentColor
                              : theme.textSecondaryColor,
                          onPressed: () => audioProvider.toggleRepeat(),
                          tooltip: 'Enable repeat',
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Progress Bar
                    Row(
                      children: [
                        Text(
                          formatDuration(audioProvider.currentPosition),
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14.0,
                              ),
                              activeTrackColor: accentColor,
                              inactiveTrackColor: theme.borderColor,
                              thumbColor: theme.textColor,
                              overlayColor: accentColor.withOpacity(0.2),
                              trackShape: const RoundedRectSliderTrackShape(),
                            ),
                            child: Slider(
                              value: currentSong != null
                                  ? audioProvider.currentPosition.inSeconds
                                        .toDouble()
                                        .clamp(
                                          0.0,
                                          audioProvider.totalDuration.inSeconds
                                                      .toDouble() >
                                                  0
                                              ? audioProvider
                                                    .totalDuration
                                                    .inSeconds
                                                    .toDouble()
                                              : 1.0,
                                        )
                                  : 0.0,
                              min: 0.0,
                              max:
                                  currentSong != null &&
                                      audioProvider.totalDuration.inSeconds > 0
                                  ? audioProvider.totalDuration.inSeconds
                                        .toDouble()
                                  : 1.0,
                              onChanged: currentSong != null
                                  ? (value) {
                                      audioProvider.seek(
                                        Duration(seconds: value.toInt()),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentSong != null
                              ? formatDuration(audioProvider.totalDuration)
                              : '0:00',
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------
              // Right Section: Additional Controls & Volume
              // ---------------------------------------------------
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mic_none, size: 20),
                      color: theme.textSecondaryColor,
                      onPressed: () => showFullscreenPlayer(context, initialPanel: 'lyrics'),
                      tooltip: 'Lyrics',
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music, size: 20),
                      color: theme.textSecondaryColor,
                      onPressed: () => showFullscreenPlayer(context, initialPanel: 'queue'),
                      tooltip: 'Queue',
                    ),
                    IconButton(
                      icon: Icon(
                        audioProvider.volume == 0
                            ? Icons.volume_off
                            : Icons.volume_up,
                        size: 20,
                      ),
                      color: theme.textSecondaryColor,
                      onPressed: () {
                        if (audioProvider.volume > 0) {
                          audioProvider.setVolume(0);
                        } else {
                          audioProvider.setVolume(0.6);
                        }
                      },
                    ),

                    // Volume Slider
                    SizedBox(
                      width: 90,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14.0,
                          ),
                          activeTrackColor: accentColor,
                          inactiveTrackColor: theme.borderColor,
                          thumbColor: theme.textColor,
                          overlayColor: accentColor.withOpacity(0.2),
                          showValueIndicator: ShowValueIndicator.always,
                          valueIndicatorShape: const DropSliderValueIndicatorShape(),
                          valueIndicatorTextStyle: TextStyle(
                            color: theme.backgroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          valueIndicatorColor: accentColor,
                        ),
                        child: Slider(
                          value: audioProvider.volume,
                          min: 0.0,
                          max: 1.0,
                          label: '${(audioProvider.volume * 100).round()}',
                          onChanged: (value) {
                            audioProvider.setVolume(value);
                          },
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.open_in_full, size: 18),
                      color: theme.textSecondaryColor,
                      onPressed: () => showFullscreenPlayer(context),
                      tooltip: 'Full screen',
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

class _AnimatedPlayButton extends StatefulWidget {
  final bool isEnabled;
  final bool isPlaying;
  final Color accentColor;
  final VoidCallback onPressed;

  const _AnimatedPlayButton({
    required this.isEnabled,
    required this.isPlaying,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.isEnabled
          ? (_) => setState(() => _isHovered = true)
          : null,
      onExit: widget.isEnabled
          ? (_) => setState(() => _isHovered = false)
          : null,
      child: GestureDetector(
        onTapDown: widget.isEnabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: widget.isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isEnabled ? theme.textColor : theme.textSecondaryColor.withOpacity(0.3),

            boxShadow: (widget.isPlaying || _isPressed || _isHovered) && widget.isEnabled
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 24,
              color: (widget.isPlaying || _isHovered) && widget.isEnabled ? widget.accentColor : theme.backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
