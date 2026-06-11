import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import 'artist_profile_view.dart';

class TrendingContent extends StatefulWidget {
  final List<Song> allSongs;
  final VoidCallback onBack;

  const TrendingContent({
    super.key,
    required this.allSongs,
    required this.onBack,
  });

  @override
  State<TrendingContent> createState() => _TrendingContentState();
}

class _TrendingContentState extends State<TrendingContent> {
  String _selectedTimeRange = 'Today';
  final List<String> _timeRanges = ['Today', 'This Week', 'This Month'];
  List<Song>? _randomizedSongs;
  List<Map<String, dynamic>>? _randomizedArtists;
  String? _selectedArtist;

  @override
  void initState() {
    super.initState();
    // Initial shuffle for the "all zero" case
    _randomizedSongs = [...widget.allSongs]..shuffle();

    // Group by artist for initial random artists
    Map<String, String> artistImages = {};
    for (var s in widget.allSongs) {
      if (!artistImages.containsKey(s.artist)) {
        artistImages[s.artist] = s.coverPath;
      }
    }
    _randomizedArtists = artistImages.entries.map((e) => {
      'name': e.key,
      'image': e.value,
      'listeners': 'Trending',
    }).toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    if (_selectedArtist != null) {
      return ArtistProfileView(
        artistName: _selectedArtist!,
        allSongs: widget.allSongs,
        onBack: () => setState(() => _selectedArtist = null),
      );
    }
    
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
                        'Trending',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_rounded, color: const Color(0xFF9D50FF), size: 28),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Text(
                      "What's hot right now. The most popular songs, artists and albums.",
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
                  _buildGenreDropdown(theme),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: _timeRanges.map((range) => _buildTimeChip(range, theme)).toList(),
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
              child: Selector<AudioProvider, int>(
                selector: (_, audio) => widget.allSongs.fold(0, (sum, s) => sum + s.playCount),
                builder: (context, totalPlays, child) {
                  final trendingSongs = [...widget.allSongs];
                  final anyPlayed = trendingSongs.any((s) => s.playCount > 0);
                  
                  final sortedSongs = anyPlayed 
                      ? (trendingSongs..sort((a, b) => b.playCount.compareTo(a.playCount)))
                      : (_randomizedSongs ?? trendingSongs);
                  
                  final top3Songs = sortedSongs.take(3).toList();
                  final topAlbums = sortedSongs.take(5).toList();

                  // Calculate Trending Artists
                  List<Map<String, dynamic>> artistList;
                  if (anyPlayed) {
                    Map<String, Map<String, dynamic>> artistMap = {};
                    for (var s in widget.allSongs) {
                      if (!artistMap.containsKey(s.artist)) {
                        artistMap[s.artist] = {
                          'name': s.artist,
                          'playCount': 0,
                          'image': s.coverPath,
                        };
                      }
                      artistMap[s.artist]!['playCount'] += s.playCount;
                    }
                    artistList = artistMap.values.toList();
                    artistList.sort((a, b) => (b['playCount'] as int).compareTo(a['playCount'] as int));
                    for (var a in artistList) {
                      final count = a['playCount'] as int;
                      a['listeners'] = count > 1000 ? '${(count/1000).toStringAsFixed(1)}K listeners' : '$count listeners';
                      if (count == 0) a['listeners'] = 'Trending';
                    }
                  } else {
                    artistList = _randomizedArtists ?? [];
                  }
                  final topArtists = artistList.take(6).toList();

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trending Songs
                          Expanded(
                            flex: 4,
                            child: _buildTrendingSongsSection(top3Songs, theme),
                          ),
                          const SizedBox(width: 32),
                          // Trending Artists
                          Expanded(
                            flex: 5,
                            child: _buildTrendingArtistsSection(topArtists, theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trending Albums
                          Expanded(
                            flex: 6,
                            child: _buildTrendingAlbumsSection(topAlbums, theme),
                          ),
                          const SizedBox(width: 32),
                          // Trending Playlists
                          Expanded(
                            flex: 4,
                            child: _buildTrendingPlaylistsSection(theme),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSongsSection(List<Song> songs, AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trending Songs', theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: songs.asMap().entries.map((entry) {
              return _buildSmallSongRow(entry.key + 1, entry.value, theme, songs);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallSongRow(int index, Song song, AppThemeExtension theme, List<Song> playlist) {
    return _TrendingSongRow(
      index: index,
      song: song,
      theme: theme,
      playlist: playlist,
    );
  }

  Widget _buildTrendingArtistsSection(List<Map<String, dynamic>> artists, AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trending Artists', theme),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 2),
            clipBehavior: Clip.hardEdge,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _TrendingArtistCard(
                artist: artist,
                theme: theme,
                onTap: () => setState(() => _selectedArtist = artist['name'] as String),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingAlbumsSection(List<Song> songs, AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trending Albums', theme),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: getImageProvider(song.coverPath),
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingPlaylistsSection(AppThemeExtension theme) {
    final playlists = [
      {'title': 'Top 50 Indonesia', 'desc': 'The most streamed songs in Indonesia.', 'icon': Icons.music_note_rounded, 'color': Colors.purple},
      {'title': 'Viral Hits', 'desc': 'Songs that are blowing up on social media.', 'icon': Icons.trending_up_rounded, 'color': Colors.blue},
      {'title': 'Charts Global', 'desc': 'The biggest global hits this week.', 'icon': Icons.public_rounded, 'color': Colors.indigo},
      {'title': 'Mood Booster', 'desc': 'Feel good songs to brighten your day.', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trending Playlists', theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: playlists.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (p['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            p['desc'] as String,
                            style: TextStyle(color: theme.textSecondaryColor, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: theme.accentColor, size: 24),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, AppThemeExtension theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'View all',
          style: TextStyle(color: theme.accentColor, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGenreDropdown(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text('All Genres', style: TextStyle(color: theme.textColor, fontSize: 13)),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: theme.textColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String text, AppThemeExtension theme) {
    final isSelected = _selectedTimeRange == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textSecondaryColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TrendingSongRow extends StatefulWidget {
  final int index;
  final Song song;
  final AppThemeExtension theme;
  final List<Song> playlist;

  const _TrendingSongRow({
    required this.index,
    required this.song,
    required this.theme,
    required this.playlist,
  });

  @override
  State<_TrendingSongRow> createState() => _TrendingSongRowState();
}

class _TrendingSongRowState extends State<_TrendingSongRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final isCurrent = audio.currentSong?.id == widget.song.id;
        final isPlaying = isCurrent && audio.isPlaying;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: () => audio.playSong(widget.song, playlist: widget.playlist),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isHovered 
                    ? widget.theme.accentColor.withValues(alpha: 0.1) 
                    : (isCurrent ? widget.theme.accentColor.withValues(alpha: 0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        color: isCurrent ? widget.theme.accentColor : widget.theme.textSecondaryColor,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image(
                          image: getImageProvider(widget.song.coverPath),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        if (isPlaying)
                          Container(
                            width: 40,
                            height: 40,
                            color: widget.theme.accentColor.withValues(alpha: 0.3),
                            child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 20),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: TextStyle(
                            color: isCurrent ? widget.theme.accentColor : widget.theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.song.artist,
                          style: TextStyle(
                            color: _isHovered ? widget.theme.textColor.withValues(alpha: 0.8) : widget.theme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '3:45',
                    style: TextStyle(
                      color: _isHovered ? widget.theme.textColor.withValues(alpha: 0.8) : widget.theme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: isCurrent || _isHovered ? widget.theme.accentColor : widget.theme.textColor.withValues(alpha: 0.3),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.more_vert_rounded,
                    color: _isHovered ? widget.theme.textColor.withValues(alpha: 0.8) : widget.theme.textSecondaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrendingArtistCard extends StatefulWidget {
  final Map<String, dynamic> artist;
  final AppThemeExtension theme;
  final VoidCallback onTap;

  const _TrendingArtistCard({
    required this.artist,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_TrendingArtistCard> createState() => _TrendingArtistCardState();
}

class _TrendingArtistCardState extends State<_TrendingArtistCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: Column(
              children: [
                // Artist Avatar with effects
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHovered ? widget.theme.accentColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: widget.theme.accentColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        Image(
                          image: getImageProvider(widget.artist['image'] as String),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                        ),
                        // Purple gradient overlay on hover
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isHovered ? 0.3 : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.theme.accentColor.withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.artist['name'] as String,
                  style: TextStyle(
                    color: _isHovered ? widget.theme.accentColor : widget.theme.textColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.artist['listeners'] as String,
                  style: TextStyle(
                    color: _isHovered ? widget.theme.accentColor.withValues(alpha: 0.7) : widget.theme.textSecondaryColor, 
                    fontSize: 11
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
