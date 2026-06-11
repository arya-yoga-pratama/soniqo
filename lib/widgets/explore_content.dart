import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'app_search_bar.dart';
import 'image_helper.dart';
import 'new_releases_content.dart';
import 'trending_content.dart';
import 'genre_content.dart';
import 'top_charts_content.dart';

class ExploreContent extends StatefulWidget {
  final List<Song> allSongs;
  final String? initialSubPage;
  const ExploreContent({super.key, required this.allSongs, this.initialSubPage});

  @override
  State<ExploreContent> createState() => _ExploreContentState();
}

class _ExploreContentState extends State<ExploreContent> {
  String? _activeSubPage;

  @override
  void initState() {
    super.initState();
    _activeSubPage = widget.initialSubPage;
  }

  String _getGenreCount(String genre) {
    final count = widget.allSongs.where((s) => s.genre?.trim().toLowerCase() == genre.trim().toLowerCase()).length;
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K songs';
    }
    return '$count ${count == 1 ? 'song' : 'songs'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    if (_activeSubPage == 'New Releases') {
      return NewReleasesContent(
        allSongs: widget.allSongs,
        onBack: () => setState(() => _activeSubPage = null),
      );
    }

    if (_activeSubPage == 'Trending') {
      return TrendingContent(
        allSongs: widget.allSongs,
        onBack: () => setState(() => _activeSubPage = null),
      );
    }

    if (_activeSubPage != null && _activeSubPage!.startsWith('Genre: ')) {
      final genre = _activeSubPage!.substring(7);
      return GenreContent(
        allSongs: widget.allSongs,
        genre: genre,
        onBack: () => setState(() => _activeSubPage = null),
      );
    }

    if (_activeSubPage == 'Top Charts') {
      return TopChartsContent(
        allSongs: widget.allSongs,
        onBack: () => setState(() => _activeSubPage = null),
      );
    }
    final sortedSongs = List<Song>.from(widget.allSongs);
    sortedSongs.sort((a, b) {
      int cmp = b.playCount.compareTo(a.playCount);
      if (cmp == 0) return b.addedAt.compareTo(a.addedAt);
      return cmp;
    });
    final topSongs = sortedSongs.where((s) => s.playCount > 0).take(5).toList();
    if (topSongs.isEmpty && widget.allSongs.isNotEmpty) {
      topSongs.addAll(widget.allSongs.take(5));
    }

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Discover new music and find your next favorite',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              // Search bar removed
            ],
          ),
          const SizedBox(height: 24),

          // ── Main Content Area (Scrollable if needed) ───────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN (Categories, Genres, Moods)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Browse by Category
                        _buildSectionHeader('Browse by Category', theme),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: Row(
                            children: [
                              _buildCategoryCard(
                                'New Releases',
                                Icons.star_border_rounded,
                                [const Color(0xFF8E24AA), const Color(0xFF4A148C)],
                                theme,
                                onTap: () => setState(() => _activeSubPage = 'New Releases'),
                              ),
                              const SizedBox(width: 12),
                              _buildCategoryCard(
                                'Trending',
                                Icons.local_fire_department_rounded,
                                [const Color(0xFF1E88E5), const Color(0xFF0D47A1)],
                                theme,
                                onTap: () => setState(() => _activeSubPage = 'Trending'),
                              ),
                              const SizedBox(width: 12),
                              _buildCategoryCard(
                                'Top Charts', 
                                Icons.sensors_rounded, 
                                [const Color(0xFF43A047), const Color(0xFF1B5E20)], 
                                theme,
                                onTap: () => setState(() => _activeSubPage = 'Top Charts'),
                              ),
                              const SizedBox(width: 12),
                              _buildCategoryCard('Events', Icons.calendar_today_rounded, [const Color(0xFFFB8C00), const Color(0xFFE65100)], theme),
                              const SizedBox(width: 12),
                              _buildCategoryCard('Exclusive', Icons.diamond_rounded, [const Color(0xFFD81B60), const Color(0xFF880E4F)], theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Popular Genres
                        _buildSectionHeader('Popular Genres', theme),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGenreSquareCard('Pop', _getGenreCount('Pop'), Icons.music_note_rounded, Colors.purpleAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: Pop')),
                            _buildGenreSquareCard('Indie', _getGenreCount('Indie'), Icons.album_rounded, Colors.greenAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: Indie')),
                            _buildGenreSquareCard('Rock', _getGenreCount('Rock'), Icons.flash_on_rounded, Colors.redAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: Rock')),
                            _buildGenreSquareCard('Hip Hop', _getGenreCount('Hip Hop'), Icons.mic_rounded, Colors.orangeAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: Hip Hop')),
                            _buildGenreSquareCard('R&B', _getGenreCount('R&B'), Icons.favorite_rounded, Colors.pinkAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: R&B')),
                            _buildGenreSquareCard('K-Pop', _getGenreCount('K-Pop'), Icons.star_rounded, Colors.blueAccent, theme, onTap: () => setState(() => _activeSubPage = 'Genre: K-Pop')),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Moods & Vibes
                        _buildSectionHeader('Moods & Vibes', theme),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMoodCircle('Chill', Icons.cloud_rounded, theme),
                            _buildMoodCircle('Workout', Icons.fitness_center_rounded, theme),
                            _buildMoodCircle('Focus', Icons.center_focus_strong_rounded, theme),
                            _buildMoodCircle('Happy', Icons.sentiment_satisfied_alt_rounded, theme),
                            _buildMoodCircle('Romantic', Icons.favorite_rounded, theme),
                            _buildMoodCircle('Sad', Icons.umbrella_rounded, theme),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),

                  // RIGHT COLUMN (Top Charts, New Releases)
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Top Charts',
                            theme,
                            onViewAll: () => setState(() => _activeSubPage = 'Top Charts'),
                          ),
                          const SizedBox(height: 16),
                          ...topSongs.asMap().entries.map((entry) {
                            return _buildChartItem(entry.key + 1, entry.value, theme);
                          }),
                          const SizedBox(height: 32),
                          _buildSectionHeader(
                            'New Releases',
                            theme,
                            onViewAll: () => setState(() => _activeSubPage = 'New Releases'),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0), // Vertical room for floating & glow
                            child: Row(
                              children: () {
                                final sortedSongs = List<Song>.from(widget.allSongs);
                                sortedSongs.sort((a, b) => b.addedAt.compareTo(a.addedAt));
                                return sortedSongs.take(8).map((song) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: _SmallNewReleaseCard(song: song, allSongs: widget.allSongs),
                                  );
                                }).toList();
                              }(),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeExtension theme, {VoidCallback? onViewAll}) {
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
        if (onViewAll != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View all',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, List<Color> colors, AppThemeExtension theme, {VoidCallback? onTap}) {
    return _CategoryCard(
      title: title,
      icon: icon,
      colors: colors,
      theme: theme,
      onTap: onTap,
    );
  }

  Widget _buildGenreSquareCard(String title, String count, IconData icon, Color iconColor, AppThemeExtension theme, {VoidCallback? onTap}) {
    return _GenreCard(
      title: title,
      count: count,
      icon: icon,
      iconColor: iconColor,
      theme: theme,
      onTap: onTap,
    );
  }

  Widget _buildMoodCircle(String title, IconData icon, AppThemeExtension theme) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Icon(icon, color: theme.textColor.withValues(alpha: 0.7), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildChartItem(int rank, Song song, AppThemeExtension theme) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final isPlaying = audio.currentSong?.id == song.id && audio.isPlaying;
        final isCurrent = audio.currentSong?.id == song.id;

        final prevRank = audio.previousRankings[song.id];
        Widget indicator;
        if (prevRank == null || prevRank == rank) {
          indicator = const Icon(Icons.remove_rounded, color: Colors.grey, size: 14);
        } else if (rank < prevRank) {
          indicator = const Icon(Icons.arrow_drop_up_rounded, color: Colors.greenAccent, size: 20);
        } else {
          indicator = const Icon(Icons.arrow_drop_down_rounded, color: Colors.redAccent, size: 20);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                if (isCurrent) {
                  audio.togglePlayPause();
                } else {
                  audio.playSong(song, playlist: widget.allSongs);
                }
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor: Colors.white.withValues(alpha: 0.06),
              splashColor: theme.accentColor.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              mouseCursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isCurrent
                      ? theme.accentColor.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$rank',
                            style: TextStyle(
                              color: isCurrent ? theme.accentColor : theme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          indicator,
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image(
                            image: getImageProvider(song.coverPath),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                          if (isPlaying)
                            Container(
                              width: 44,
                              height: 44,
                              color: theme.accentColor.withValues(alpha: 0.3),
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
                            song.title,
                            style: TextStyle(
                              color: isCurrent ? theme.accentColor : theme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: theme.textSecondaryColor.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Play/Pause button - absorbs its own tap without bubbling
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          size: 28,
                        ),
                        color: isCurrent
                            ? theme.accentColor
                            : theme.textColor.withValues(alpha: 0.8),
                        onPressed: () {
                          if (isCurrent) {
                            audio.togglePlayPause();
                          } else {
                            audio.playSong(song, playlist: widget.allSongs);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SmallNewReleaseCard extends StatefulWidget {
  final Song song;
  final List<Song> allSongs;
  const _SmallNewReleaseCard({required this.song, required this.allSongs});

  @override
  State<_SmallNewReleaseCard> createState() => _SmallNewReleaseCardState();
}

class _SmallNewReleaseCardState extends State<_SmallNewReleaseCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final isPlaying = audio.currentSong?.id == widget.song.id && audio.isPlaying;
        final isCurrent = audio.currentSong?.id == widget.song.id;
        final showGlow = _isHovered || isCurrent;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              if (isCurrent) {
                audio.togglePlayPause();
              } else {
                audio.playSong(widget.song, playlist: widget.allSongs);
              }
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (showGlow)
                                BoxShadow(
                                  color: theme.accentColor.withValues(alpha: isPlaying ? 0.4 : 0.2),
                                  blurRadius: _isHovered ? 20 : 15,
                                  spreadRadius: isPlaying ? 2 : 0,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image(
                              image: getImageProvider(widget.song.coverPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Play Icon Overlay
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: AnimatedScale(
                            scale: showGlow ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 76,
                      child: Text(
                        widget.song.title,
                        style: TextStyle(
                          color: isCurrent ? theme.accentColor : theme.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _NewReleaseCard extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  const _NewReleaseCard({required this.song, required this.playlist});

  @override
  State<_NewReleaseCard> createState() => _NewReleaseCardState();
}

class _NewReleaseCardState extends State<_NewReleaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final bool isCurrent = audio.currentSong?.id == widget.song.id;
        final bool isPlaying = isCurrent && audio.isPlaying;
        final bool showGlow = isCurrent || _isHovered;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (isCurrent) {
                audio.togglePlayPause();
              } else {
                audio.playSong(widget.song, playlist: widget.playlist);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 125,
              margin: const EdgeInsets.only(right: 24),
              transform: Matrix4.translationValues(0, _isHovered ? -8.0 : 0.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main Cover with organic glow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: getImageProvider(widget.song.coverPath), fit: BoxFit.cover),
                            boxShadow: [
                              if (showGlow) ...[
                                BoxShadow(
                                  color: theme.accentColor.withValues(alpha: isCurrent ? 0.3 : 0.15),
                                  blurRadius: _isHovered ? 25 : 20,
                                  spreadRadius: isCurrent ? 2 : 0,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: theme.accentColor.withValues(alpha: isCurrent ? 0.2 : 0.1),
                                  blurRadius: 40,
                                  spreadRadius: -2,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Glassy Active/Hover Overlay
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              color: showGlow ? Colors.black.withValues(alpha: isCurrent ? 0.45 : 0.25) : Colors.transparent,
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 240),
                                  scale: showGlow ? 1.0 : 0.8,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 240),
                                    opacity: showGlow ? 1.0 : 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? theme.accentColor : Colors.black54,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          if (isCurrent)
                                            BoxShadow(
                                              color: theme.accentColor.withValues(alpha: 0.5),
                                              blurRadius: 15,
                                            )
                                        ],
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.song.title,
                    style: TextStyle(
                      color: isCurrent ? theme.accentColor : theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.song.artist,
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFFA54BFF).withValues(alpha: 0.6) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _CategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final AppThemeExtension theme;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.theme,
    this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -8.0 : 0.0, 0.0)
              ..scale(_isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0)),
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: widget.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors[0].withValues(alpha: _isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 10 : 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

class _GenreCard extends StatefulWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final AppThemeExtension theme;
  final VoidCallback? onTap;

  const _GenreCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.theme,
    this.onTap,
  });

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0, 0.0)
            ..scale(_isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0)),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.iconColor.withValues(alpha: _isHovered ? 0.3 : 0.05)),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(color: widget.theme.textColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                widget.count,
                style: TextStyle(color: widget.theme.textSecondaryColor.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
