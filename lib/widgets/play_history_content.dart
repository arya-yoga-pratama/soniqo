import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/play_history_entry.dart';
import '../models/song.dart';
import 'app_search_bar.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';
import 'artist_profile_view.dart';
import 'album_detail_view.dart';
import '../data/songs_data.dart';

class PlayHistoryContent extends StatefulWidget {
  const PlayHistoryContent({super.key});

  @override
  State<PlayHistoryContent> createState() => _PlayHistoryContentState();
}

class _PlayHistoryContentState extends State<PlayHistoryContent> {
  // Category tab index (All = 0, Songs = 1, Artists = 2, Albums = 3, Playlists = 4)
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedArtist;
  String? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPlayedAt(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final todayString = 'Today, ${_padTwo(time.hour)}:${_padTwo(time.minute)} ${time.hour >= 12 ? 'PM' : 'AM'}';
    if (diff.inDays == 0) return todayString;
    if (diff.inDays == 1) return 'Yesterday, ${_padTwo(time.hour)}:${_padTwo(time.minute)} ${time.hour >= 12 ? 'PM' : 'AM'}';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _padTwo(int v) => v.toString().padLeft(2, '0');



  @override
  Widget build(BuildContext context) {
    if (_selectedArtist != null) {
      return ArtistProfileView(
        artistName: _selectedArtist!,
        allSongs: allSongsData,
        onBack: () => setState(() => _selectedArtist = null),
      );
    }
    if (_selectedAlbum != null) {
      return AlbumDetailView(
        albumName: _selectedAlbum!,
        allSongs: allSongsData,
        onBack: () => setState(() => _selectedAlbum = null),
      );
    }

    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      color: Colors.transparent,
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, _) {
          final rawHistory = audioProvider.playHistory;
          final query = _searchController.text.toLowerCase();

          final searchedHistory = rawHistory.where((entry) {
            final song = entry.song;
            return song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query) ||
                (song.album?.toLowerCase().contains(query) ?? false);
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: theme.backgroundColor.withValues(alpha: 0.95),
                elevation: 0,
                pinned: true,
                toolbarHeight: 72,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Nav arrows + Search bar
                      Row(
                        children: [
                          // Back / Forward buttons
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            color: theme.textSecondaryColor,
                            onPressed: () {},
                            splashRadius: 20,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            color: theme.textSecondaryColor,
                            onPressed: () {},
                            splashRadius: 20,
                          ),
                          const SizedBox(width: 20),
                          // Search bar
                          AppSearchBar(controller: _searchController),
                        ],
                      ),
                      // Right: notification + avatar
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.borderColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: theme.textSecondaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.accentColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 20,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Page Title ──────────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.history, color: theme.accentColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Play History',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your recently played songs and more',
                                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Tabs + Clear Button ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildTab(0, Icons.grid_view_rounded, 'All'),
                              const SizedBox(width: 8),
                              _buildTab(1, Icons.music_note_rounded, 'Songs'),
                              const SizedBox(width: 8),
                              _buildTab(2, Icons.person_outline_rounded, 'Artists'),
                              const SizedBox(width: 8),
                              _buildTab(3, Icons.album_rounded, 'Albums'),
                              const SizedBox(width: 8),
                              _buildTab(4, Icons.queue_music_rounded, 'Playlists'),
                            ],
                          ),
                          // Clear History button
                          if (rawHistory.isNotEmpty)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _showClearDialog(context, audioProvider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: theme.accentColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: theme.accentColor, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Clear History',
                                        style: TextStyle(
                                          color: theme.accentColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Empty / Search Results State ─────────────────────────────────────
                      if (rawHistory.isEmpty)
                        _buildEmptyState(theme)
                      else if (searchedHistory.isEmpty)
                        _buildNoResultsState(theme)
                      else
                        _buildCurrentTabContent(theme, searchedHistory, audioProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        final isActive = _selectedTab == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = index),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.accentColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? theme.accentColor : theme.borderColor,
                )
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      key: ValueKey('icon_${isActive}'),
                      size: 15,
                      color: isActive ? Colors.white : theme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.textSecondaryColor,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 4, child: Text('SONG', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          SizedBox(
            width: 160,
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.textSecondaryColor, size: 13),
                SizedBox(width: 4),
                Text('PLAYED AT', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    int index,
    PlayHistoryEntry entry,
    AudioProvider audioProvider,
    List<Song> playlistContext,
  ) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final Song song = entry.song;
    final bool isCurrentSong = audioProvider.currentSong?.id == song.id;
    final bool isPlayingNow = isCurrentSong && audioProvider.isPlaying;

    return InkWell(
      onTap: () {
        if (isCurrentSong) {
          audioProvider.togglePlayPause();
        } else {
          audioProvider.playSong(song, playlist: playlistContext);
        }
      },
      borderRadius: BorderRadius.circular(8),
      hoverColor: theme.borderColor,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCurrentSong
              ? theme.accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // # or equalizer
            SizedBox(
              width: 40,
              child: isCurrentSong
                  ? Row(
                      children: [
                        Icon(
                          isPlayingNow ? Icons.play_arrow : Icons.pause,
                          color: theme.accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.equalizer, color: Color(0xFF7C3AED), size: 14),
                      ],
                    )
                  : Text(
                      '$index',
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                    ),
            ),

            // Album art + title + artist
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: buildCoverImage(
                      song.coverPath,
                      width: 44, height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong
                                ? theme.accentColor
                                : theme.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist,
                          style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Album (dummy)
            Expanded(
              flex: 3,
              child: Text(
                song.album?.isNotEmpty == true ? song.album! : 'Unknown Album',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Played at
            SizedBox(
              width: 160,
              child: Text(
                _formatPlayedAt(entry.playedAt),
                style: TextStyle(
                  color: isCurrentSong
                      ? theme.accentColor
                      : theme.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ),

            // Play button
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentSong
                    ? theme.accentColor
                    : Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                isPlayingNow ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),

            // More menu
            IconButton(
              icon: const Icon(Icons.more_horiz, size: 18),
              color: theme.textSecondaryColor,
              onPressed: () {},
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: theme.borderColor,
            ),
            const SizedBox(height: 20),
            Text(
              'No play history yet',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start playing songs and they will appear here',
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.borderColor,
            ),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different keyword',
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(AppThemeExtension theme, List<PlayHistoryEntry> history, AudioProvider audioProvider) {
    Widget content;
    if (_selectedTab == 0) {
      // All
      content = Column(
        key: const ValueKey('tab_all'),
        children: [
          _buildTableHeader(theme),
          Container(height: 1, color: theme.borderColor),
          const SizedBox(height: 4),
          ...history.asMap().entries.map((e) =>
            _buildHistoryRow(context, e.key + 1, e.value, audioProvider, history.map((e) => e.song).toList()),
          ),
          const SizedBox(height: 40),
        ],
      );
    } else if (_selectedTab == 1) {
      // Songs (Unique)
      final seenIds = <String>{};
      final uniqueSongs = <PlayHistoryEntry>[];
      for (final entry in history) {
        if (!seenIds.contains(entry.song.id)) {
          seenIds.add(entry.song.id);
          uniqueSongs.add(entry);
        }
      }
      
      if (uniqueSongs.isEmpty) {
        content = _buildTabEmptyState(theme, 'No Recently Played Songs', const ValueKey('empty_songs'));
      } else {
        content = Column(
          key: const ValueKey('tab_songs'),
          children: [
            _buildTableHeader(theme),
            Container(height: 1, color: theme.borderColor),
            const SizedBox(height: 4),
            ...uniqueSongs.asMap().entries.map((e) =>
              _buildHistoryRow(context, e.key + 1, e.value, audioProvider, uniqueSongs.map((e) => e.song).toList()),
            ),
            const SizedBox(height: 40),
          ],
        );
      }
    } else if (_selectedTab == 2) {
      // Artists (Unique)
      final seenArtists = <String>{};
      final uniqueArtists = <Map<String, dynamic>>[];
      for (final entry in history) {
        if (!seenArtists.contains(entry.song.artist)) {
          seenArtists.add(entry.song.artist);
          uniqueArtists.add({
            'name': entry.song.artist,
            'cover': entry.song.coverPath,
          });
        }
      }

      if (uniqueArtists.isEmpty) {
        content = _buildTabEmptyState(theme, 'No Recently Played Artists', const ValueKey('empty_artists'));
      } else {
        content = Wrap(
          key: const ValueKey('tab_artists'),
          spacing: 24,
          runSpacing: 24,
          children: uniqueArtists.map((artist) => _buildArtistCard(artist['name'], artist['cover'], theme, ValueKey('artist_${artist['name']}' ))).toList(),
        );
      }
    } else if (_selectedTab == 3) {
      // Albums (Unique)
      final seenAlbums = <String>{};
      final uniqueAlbums = <Map<String, dynamic>>[];
      for (final entry in history) {
        final album = entry.song.album;
        if (album != null && album.isNotEmpty && !seenAlbums.contains(album)) {
          seenAlbums.add(album);
          uniqueAlbums.add({
            'name': album,
            'artist': entry.song.artist,
            'cover': entry.song.coverPath,
          });
        }
      }

      if (uniqueAlbums.isEmpty) {
        content = _buildTabEmptyState(theme, 'No Recently Played Albums', const ValueKey('empty_albums'));
      } else {
        content = Wrap(
          key: const ValueKey('tab_albums'),
          spacing: 24,
          runSpacing: 24,
          children: uniqueAlbums.map((album) => _buildAlbumCard(album['name'], album['artist'], album['cover'], theme, ValueKey('album_${album['name']}' ))).toList(),
        );
      }
    } else {
      // Playlists
      content = _buildTabEmptyState(theme, 'No Recently Played Playlists', const ValueKey('empty_playlists'));
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutQuart,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren.map((child) => Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: child,
                  )),
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: content,
      ),
    );
  }

  Widget _buildTabEmptyState(AppThemeExtension theme, String message, Key key) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 48, color: theme.borderColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(String name, String coverPath, AppThemeExtension theme, Key key) {
    bool hovered = false;
    return StatefulBuilder(
      key: key,
      builder: (context, setCardState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setCardState(() => hovered = true),
          onExit: (_) => setCardState(() => hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _selectedArtist = name),
            child: AnimatedScale(
              scale: hovered ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: SizedBox(
                width: 140,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: hovered 
                                ? theme.accentColor.withValues(alpha: 0.3) 
                                : Colors.black.withValues(alpha: 0.2), 
                            blurRadius: hovered ? 16 : 10, 
                            offset: const Offset(0, 6)
                          ),
                        ],
                      ),
                      child: ClipOval(child: buildCoverImage(coverPath, fit: BoxFit.cover)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        color: hovered ? theme.accentColor : theme.textColor, 
                        fontWeight: FontWeight.w600, 
                        fontSize: 14
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Artist',
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildAlbumCard(String name, String artist, String coverPath, AppThemeExtension theme, Key key) {
    bool hovered = false;
    return StatefulBuilder(
      key: key,
      builder: (context, setCardState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setCardState(() => hovered = true),
          onExit: (_) => setCardState(() => hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _selectedAlbum = name),
            child: AnimatedScale(
              scale: hovered ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: hovered 
                                ? theme.accentColor.withValues(alpha: 0.3) 
                                : Colors.black.withValues(alpha: 0.2), 
                            blurRadius: hovered ? 16 : 10, 
                            offset: const Offset(0, 6)
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildCoverImage(coverPath, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        color: hovered ? theme.accentColor : theme.textColor, 
                        fontWeight: FontWeight.w600, 
                        fontSize: 14
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  void _showClearDialog(BuildContext context, AudioProvider audioProvider) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Clear Play History',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to clear all your play history? This action cannot be undone.',
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              audioProvider.clearHistory();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: theme.accentColor.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
