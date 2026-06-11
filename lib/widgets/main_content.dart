import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../data/songs_data.dart';
import 'home_hero_section.dart';
import 'recently_played_section.dart';
import 'home_hero_banner.dart';
import 'recently_played_grid.dart';
import 'made_for_you_section.dart';
import 'trending_section.dart';
import 'recently_added_section.dart';
import 'top_artists_section.dart';
import 'artist_profile_view.dart';
import 'image_helper.dart';
import 'mix_detail_view.dart';
import 'app_search_bar.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';

class MainContent extends StatefulWidget {
  final VoidCallback? onViewHistory;
  final VoidCallback? onViewNewReleases;

  const MainContent({super.key, this.onViewHistory, this.onViewNewReleases});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedArtist;
  Playlist? _selectedPlaylist;

  final List<Song> _songs = allSongsData;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AudioProvider>(context, listen: false);
      if (provider.playlist.isEmpty) {
        provider.setPlaylist(_songs);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    if (_selectedArtist != null) {
      return ArtistProfileView(
        artistName: _selectedArtist!,
        allSongs: _songs,
        onBack: () {
          setState(() {
            _selectedArtist = null;
          });
        },
      );
    }

    if (_selectedPlaylist != null) {
      return MixDetailView(
        playlist: _selectedPlaylist!,
        allSongs: _songs,
        onBack: () {
          setState(() {
            _selectedPlaylist = null;
          });
        },
        onArtistTap: (artistName) {
          setState(() {
            _selectedPlaylist = null;
            _selectedArtist = artistName;
          });
        },
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          toolbarHeight: 72,
          titleSpacing: 0,
          flexibleSpace: ClipRect(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AppSearchBar(controller: _searchController),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.borderColor,
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
                        color: const Color(0xFF2A1F5C),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
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

        SliverToBoxAdapter(
          child: _searchQuery.isEmpty
              ? _buildHomeView()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  // ── Home View ──────────────────────────────────────────────────────────────
  Widget _buildHomeView() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning, ';
    } else if (hour < 17) {
      greeting = 'Good Afternoon, ';
    } else {
      greeting = 'Good Evening, ';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting Header ───────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textColor, letterSpacing: -0.5),
                  children: [
                    TextSpan(text: greeting),
                    const TextSpan(text: 'Arya', style: TextStyle(color: Color(0xFFA54BFF))),
                    const TextSpan(text: ' 👋'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Let's play something you love",
                style: TextStyle(fontSize: 14, color: theme.textSecondaryColor, fontWeight: FontWeight.w400),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Row 1 : Hero (left) + Recently Played grid (right) ────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 55, 
                  child: Consumer<AudioProvider>(
                    builder: (context, audio, _) => HomeHeroBanner(allSongs: _songs),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(flex: 45, child: RecentlyPlayedGrid(allSongs: _songs, onViewAll: widget.onViewHistory)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55, 
                  child: MadeForYouSection(
                    songs: _songs,
                    onPlaylistTap: (playlist) {
                      setState(() {
                        _selectedPlaylist = playlist;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(flex: 45, child: TrendingSection(songs: _songs)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Row 3 : Recently Added (left) + Top Artists (right) ───────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 55, child: RecentlyAddedSection(songs: _songs, onViewAll: widget.onViewNewReleases)),
              const SizedBox(width: 40),
              Expanded(
                flex: 45, 
                child: TopArtistsSection(
                  songs: _songs,
                  onArtistTap: (artistName) {
                    setState(() {
                      _selectedArtist = artistName;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // ── All Songs Table (Trending Songs) ──────────────────────────────
          Text(
            'Trending Songs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 14),
          _buildSongTableHeader(),
          Divider(color: theme.borderColor, height: 1),
          const SizedBox(height: 8),
          Consumer<AudioProvider>(
            builder: (context, audioProvider, _) {
              // Create a copy of all songs to sort
              final List<Song> trendingSongs = List.from(_songs);
              
              // Sort: 1. playCount DESC, 2. addedAt DESC
              trendingSongs.sort((a, b) {
                int cmp = b.playCount.compareTo(a.playCount);
                if (cmp == 0) {
                  return b.addedAt.compareTo(a.addedAt);
                }
                return cmp;
              });

              // Take top 20
              final displayedSongs = trendingSongs.take(20).toList();

              return Column(
                children: displayedSongs.asMap().entries.map((e) {
                  final song = e.value;
                  final isPlaying = audioProvider.currentSong?.id == song.id;
                  // Use displayedSongs as the playlist context for gapless playback of trending list
                  return _buildSongRow(context, e.key + 1, song, isPlaying, audioProvider, playlist: displayedSongs);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Search Results View ─────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final filtered = _songs.where((s) {
      return s.title.toLowerCase().contains(_searchQuery) ||
             s.artist.toLowerCase().contains(_searchQuery) ||
             (s.album != null && s.album!.toLowerCase().contains(_searchQuery));
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
                  children: [
                    const TextSpan(text: 'Showing results for '),
                    TextSpan(
                      text: '"$_searchQuery"',
                      style: const TextStyle(
                        color: Color(0xFF9D6FEF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Category Tabs ─────────────────────────────────────────────
              Row(
                children: [
                  _buildCategoryTab('Songs', filtered.length, true),
                  const SizedBox(width: 8),
                  _buildCategoryTab('Artists', 0, false),
                  const SizedBox(width: 8),
                  _buildCategoryTab('Albums', 0, false),
                  const SizedBox(width: 8),
                  _buildCategoryTab('Playlists', 0, false),
                ],
              ),
              const SizedBox(height: 24),

              // ── Empty State ───────────────────────────────────────────────
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: theme.borderColor),
                        const SizedBox(height: 16),
                        Text(
                          'No songs found for "$_searchQuery"',
                          style: TextStyle(color: theme.textSecondaryColor, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // ── Table Header ─────────────────────────────────────────────
                _buildSongTableHeader(),
                Divider(color: theme.borderColor, height: 1),
                const SizedBox(height: 4),

                // ── Song Rows ────────────────────────────────────────────────
                ...filtered.asMap().entries.map((e) {
                  final song = e.value;
                  final isPlaying = audioProvider.currentSong?.id == song.id;
                  return _buildSongRow(context, e.key + 1, song, isPlaying, audioProvider, playlist: filtered);
                }),

                const SizedBox(height: 8),

                // ── View All Results Button ───────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      overlayColor: theme.textColor,
                    ),
                    child: Text(
                      'View all results',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(String label, int count, bool isActive) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF7C3AED) : theme.borderColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Text(
        count > 0 ? '$label ($count)' : label,
        style: TextStyle(
          color: isActive ? Colors.white : theme.textSecondaryColor,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSongTableHeader() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 4, child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          SizedBox(width: 40, child: Icon(Icons.access_time, color: theme.textSecondaryColor, size: 15)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(String title, String imagePath, bool isFeatured) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: getImageProvider(imagePath),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isFeatured ? Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  radius: 16,
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ),
            ) : null,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, int number, Song song, bool isPlaying, AudioProvider audioProvider, {List<Song>? playlist}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    return InkWell(
      onTap: () {
        if (isPlaying) {
          audioProvider.togglePlayPause();
        } else {
          audioProvider.playSong(song, playlist: playlist);
        }
      },
      borderRadius: BorderRadius.circular(8),
      hoverColor: theme.borderColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isPlaying ? theme.borderColor : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: isPlaying
                  ? const Icon(Icons.equalizer, color: Color(0xFF7C3AED), size: 16)
                  : Text(number.toString(), style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
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
                            color: isPlaying ? const Color(0xFF7C3AED) : theme.textColor,
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
              width: 64,
              child: Text(
                '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.more_horiz, size: 18),
                color: theme.textSecondaryColor,
                onPressed: () {},
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Search Bar Widget ───────────────────────────────────────────────

