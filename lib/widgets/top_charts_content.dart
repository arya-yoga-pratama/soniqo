import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';

class TopChartsContent extends StatelessWidget {
  final List<Song> allSongs;
  final VoidCallback onBack;

  const TopChartsContent({
    super.key,
    required this.allSongs,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Charts',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.sensors_rounded, color: const Color(0xFF43A047), size: 28),
              const Spacer(),
              Tooltip(
                message: 'Update reference rankings',
                child: IconButton(
                  icon: Icon(Icons.sync_rounded, color: theme.textSecondaryColor, size: 20),
                  onPressed: () {
                    context.read<AudioProvider>().updatePreviousRankings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference rankings updated! Changes will track from this point.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48.0, top: 4.0),
            child: Text(
              "The most played songs right now. Compare movements from your last sync.",
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, _) {
                // Determine top charts based on play count
                final List<Song> topSongs = List.from(allSongs);
                // Sort by playCount descending, then addedAt descending
                topSongs.sort((a, b) {
                  int cmp = b.playCount.compareTo(a.playCount);
                  if (cmp == 0) {
                    return b.addedAt.compareTo(a.addedAt);
                  }
                  return cmp;
                });

                // Filter out songs with 0 play count
                final List<Song> playedSongs = topSongs.where((s) => s.playCount > 0).toList();
                
                if (playedSongs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 64, color: theme.borderColor),
                        const SizedBox(height: 16),
                        Text(
                          'No Top Charts Available Yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Play some songs to see them in the charts.',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textSecondaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Take top 20
                final displayedSongs = playedSongs.take(20).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTableHeader(theme),
                    Divider(color: theme.borderColor, height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayedSongs.length,
                        itemBuilder: (context, index) {
                          final song = displayedSongs[index];
                          final isPlaying = audioProvider.currentSong?.id == song.id;
                          return _buildSongRow(
                            context,
                            index + 1,
                            song,
                            isPlaying,
                            audioProvider,
                            theme,
                            playlist: displayedSongs,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 4,
            child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 80,
            child: Text('PLAYS', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 40,
            child: Icon(Icons.access_time, color: theme.textSecondaryColor, size: 15),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildSongRow(
    BuildContext context,
    int rank,
    Song song,
    bool isPlaying,
    AudioProvider audioProvider,
    AppThemeExtension theme, {
    required List<Song> playlist,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          if (isPlaying) {
            audioProvider.togglePlayPause();
          } else {
            audioProvider.playSong(song, playlist: playlist);
          }
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        splashColor: theme.accentColor.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        mouseCursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isPlaying
                ? const Color(0xFF43A047).withValues(alpha: 0.08)
                : Colors.transparent,
          ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPlaying)
                    const Icon(Icons.equalizer, color: Color(0xFF43A047), size: 16)
                  else
                    Text('$rank', style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  _buildRankIndicator(song.id, rank, audioProvider),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: buildCoverImage(song.coverPath, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isPlaying ? const Color(0xFF43A047) : theme.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                song.album?.isNotEmpty == true ? song.album! : 'Unknown Album',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${song.playCount}',
                style: TextStyle(
                  color: isPlaying ? const Color(0xFF43A047) : theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 32,
              child: IconButton(
                icon: Icon(
                  isPlaying && audioProvider.isPlaying 
                    ? Icons.pause_circle_filled_rounded 
                    : Icons.play_circle_fill_rounded, 
                  size: 24,
                ),
                color: isPlaying ? const Color(0xFF43A047) : theme.textSecondaryColor,
                onPressed: () {
                  if (isPlaying) {
                    audioProvider.togglePlayPause();
                  } else {
                    audioProvider.playSong(song, playlist: playlist);
                  }
                },
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankIndicator(String songId, int currentRank, AudioProvider audio) {
    final prevRank = audio.previousRankings[songId];
    
    Widget icon;
    if (prevRank == null) {
      icon = const Icon(Icons.fiber_new_rounded, color: Colors.blueAccent, size: 14, key: ValueKey('new'));
    } else if (currentRank < prevRank) {
      icon = const Icon(Icons.arrow_drop_up_rounded, color: Colors.greenAccent, size: 20, key: ValueKey('up'));
    } else if (currentRank > prevRank) {
      icon = const Icon(Icons.arrow_drop_down_rounded, color: Colors.redAccent, size: 20, key: ValueKey('down'));
    } else {
      icon = Text('–', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14, fontWeight: FontWeight.bold), key: const ValueKey('neutral'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
      child: icon,
    );
  }
}
