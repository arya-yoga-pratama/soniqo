import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';

class GenreContent extends StatelessWidget {
  final List<Song> allSongs;
  final String genre;
  final VoidCallback onBack;

  const GenreContent({
    super.key,
    required this.allSongs,
    required this.genre,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    
    final genreSongs = allSongs.where((song) {
      if (song.genre == null) return false;
      return song.genre!.toLowerCase() == genre.toLowerCase();
    }).toList();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$genre Music',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.music_note_rounded, color: theme.accentColor, size: 24),
                  ],
                ),
                Text(
                  'Explore the best $genre tracks',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('All $genre Songs (${genreSongs.length})', theme),
                const SizedBox(height: 16),
                if (genreSongs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No $genre songs found in your library.',
                        style: TextStyle(color: theme.textSecondaryColor, fontSize: 16),
                      ),
                    ),
                  )
                else
                  _buildSongsTable(context, genreSongs, theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeExtension theme) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSongsTable(BuildContext context, List<Song> songs, AppThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
                Expanded(flex: 4, child: Text('SONG', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
                Expanded(flex: 3, child: Text('ARTIST', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
                Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
                SizedBox(width: 60, child: Center(child: Icon(Icons.access_time_rounded, color: theme.textSecondaryColor, size: 16))),
                const SizedBox(width: 80),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Table Body
          ...songs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildSongRow(context, index + 1, song, theme, songs);
          }),
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, int index, Song song, AppThemeExtension theme, List<Song> playlist) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final isCurrent = audio.currentSong?.id == song.id;
        final isPlaying = isCurrent && audio.isPlaying;

        return InkWell(
          onTap: () {
            if (isCurrent) {
              audio.togglePlayPause();
            } else {
              audio.playSong(song, playlist: playlist);
            }
          },
          child: Container(
            color: isCurrent ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isCurrent ? theme.accentColor : theme.textSecondaryColor,
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image(
                              image: getImageProvider(song.coverPath),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            if (isPlaying)
                              Container(
                                width: 40,
                                height: 40,
                                color: theme.accentColor.withValues(alpha: 0.3),
                                child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 20),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrent ? theme.accentColor : theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    song.artist,
                    style: TextStyle(
                      color: isCurrent ? Colors.white.withValues(alpha: 0.9) : theme.textSecondaryColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    song.album?.isNotEmpty == true ? song.album! : 'Unknown Album',
                    style: TextStyle(
                      color: isCurrent ? Colors.white.withValues(alpha: 0.9) : theme.textSecondaryColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white.withValues(alpha: 0.9) : theme.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                        color: isCurrent ? theme.accentColor : theme.textSecondaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.more_vert_rounded, color: theme.textSecondaryColor, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
