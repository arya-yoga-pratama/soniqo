import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import 'album_detail_view.dart';

class NewReleasesContent extends StatefulWidget {
  final List<Song> allSongs;
  final VoidCallback onBack;

  const NewReleasesContent({
    super.key,
    required this.allSongs,
    required this.onBack,
  });

  @override
  State<NewReleasesContent> createState() => _NewReleasesContentState();
}

class _NewReleasesContentState extends State<NewReleasesContent> {
  String? _activeAlbumName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    
    if (_activeAlbumName != null) {
      return AlbumDetailView(
        albumName: _activeAlbumName!,
        allSongs: widget.allSongs,
        onBack: () => setState(() => _activeAlbumName = null),
      );
    }

    final sortedSongs = List<Song>.from(widget.allSongs);
    sortedSongs.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    // Group by album name to create dynamic albums
    final latestAlbumsData = <String, List<Song>>{};
    for (var song in sortedSongs) {
      final isSingle = song.album == null || song.album!.trim().isEmpty;
      final albumName = isSingle ? song.title : song.album!.trim();
      
      if (!latestAlbumsData.containsKey(albumName)) {
        latestAlbumsData[albumName] = [];
      }
      latestAlbumsData[albumName]!.add(song);
    }
    
    final displayedAlbums = latestAlbumsData.entries.take(6).toList();

    final latestSongs = sortedSongs.take(10).toList();

    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'New Releases',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.auto_awesome, color: theme.accentColor, size: 24),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Text(
                    'Discover the latest songs, albums and artists',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildDropdown('All Genres', theme),
                const SizedBox(width: 12),
                _buildFilterButton(theme),
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
                // ── Latest Albums Section ──────────────────────────────────
                _buildSectionHeader('Latest Albums', theme),
                const SizedBox(height: 16),
                if (displayedAlbums.isEmpty)
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.album_rounded, size: 48, color: theme.textSecondaryColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No New Albums Yet', style: TextStyle(color: theme.textSecondaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: displayedAlbums.length,
                      itemBuilder: (context, index) {
                        final albumEntry = displayedAlbums[index];
                        return _buildAlbumCard(
                          albumEntry, 
                          theme,
                          onTap: () => setState(() => _activeAlbumName = albumEntry.key),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 40),

                // ── Latest Songs Section ───────────────────────────────────
                _buildSectionHeader('Latest Songs', theme),
                const SizedBox(height: 16),
                _buildSongsTable(context, latestSongs, theme),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'View all',
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(MapEntry<String, List<Song>> albumData, AppThemeExtension theme, {required VoidCallback onTap}) {
    return _AlbumCard(albumData: albumData, theme: theme, onTap: onTap);
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
                    'Single',
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
                      '3:45', // Simulated duration
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

  Widget _buildDropdown(String text, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(text, style: TextStyle(color: theme.textColor, fontSize: 13)),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: theme.textColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildFilterButton(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: theme.textColor, size: 18),
          const SizedBox(width: 8),
          Text('Filter', style: TextStyle(color: theme.textColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final MapEntry<String, List<Song>> albumData;
  final AppThemeExtension theme;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.albumData,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final albumName = widget.albumData.key;
    final songs = widget.albumData.value;
    final firstSong = songs.first;
    
    final isSingle = firstSong.album == null || firstSong.album!.trim().isEmpty;
    final typeLabel = isSingle ? 'Single' : 'Album';
    final artistName = isSingle ? firstSong.artist : (songs.map((s) => s.artist).toSet().length == 1 ? firstSong.artist : 'Various Artists');
    final year = firstSong.addedAt.year.toString();
    final songCount = songs.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered 
                  ? widget.theme.accentColor.withValues(alpha: 0.5) 
                  : Colors.white.withValues(alpha: 0.05)
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.theme.accentColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                splashColor: widget.theme.accentColor.withValues(alpha: 0.1),
                highlightColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image(
                            image: getImageProvider(firstSong.coverPath),
                            width: 160,
                            height: 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.theme.accentColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Consumer<AudioProvider>(
                            builder: (context, audio, _) {
                              final isCurrent = audio.currentSong != null && songs.any((s) => s.id == audio.currentSong!.id);
                              final isPlaying = isCurrent && audio.isPlaying;

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _isHovered || isPlaying ? 1.0 : 0.0,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  scale: _isHovered || isPlaying ? 1.0 : 0.8,
                                  curve: Curves.easeOutBack,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isCurrent && audio.isPlaying) {
                                        audio.togglePlayPause();
                                      } else {
                                        audio.playSong(songs.first, playlist: songs);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.theme.accentColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.theme.accentColor.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white, 
                                        size: 24
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$albumName ($typeLabel)',
                            style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artistName,
                            style: TextStyle(color: widget.theme.textSecondaryColor, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$year • $songCount ${songCount == 1 ? 'song' : 'songs'}',
                            style: TextStyle(color: widget.theme.textSecondaryColor.withValues(alpha: 0.5), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
