import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/song.dart';
import '../models/user_playlist.dart';
import '../data/songs_data.dart';
import 'create_playlist_dialog.dart';
import 'user_playlist_detail_view.dart';
import 'add_to_playlist_dialog.dart';
import 'artist_profile_view.dart';
import 'album_detail_view.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';
import 'app_search_bar.dart';

class LibraryContent extends StatefulWidget {
  const LibraryContent({super.key});

  @override
  State<LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<LibraryContent> {
  bool _isListView = true;
  String _activeSection = 'Songs';
  String? _selectedArtist;
  String? _selectedAlbum;
  UserPlaylist? _selectedUserPlaylist;
  String _sortBy = 'Recently Added';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAddedAt(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    
    return '${time.day}/${time.month}/${time.year}';
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

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

    if (_selectedUserPlaylist != null) {
      return UserPlaylistDetailView(
        playlist: _selectedUserPlaylist!,
        allSongs: allSongsData,
        onBack: () => setState(() => _selectedUserPlaylist = null),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your music collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // ── Filters & Controls Row ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppSearchBar(controller: _searchController),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Sort Dropdown
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: theme.borderColor,
                        splashColor: theme.borderColor,
                      ),
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        color: theme.surfaceColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.borderColor)),
                        onSelected: (value) => setState(() => _sortBy = value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _sortBy,
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down, color: theme.textSecondaryColor, size: 16),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          _buildSortItem('Recently Added'),
                          _buildSortItem('A-Z'),
                          _buildSortItem('Z-A'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // View Toggles
                    Container(
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          _buildViewToggle(true, Icons.format_list_bulleted_rounded, theme),
                          _buildViewToggle(false, Icons.grid_view_rounded, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Content ───────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
          
          // ── Summary Cards Grid ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Consumer<AudioProvider>(
                builder: (context, audioProvider, _) {
                  final uniqueAlbums = allSongsData
                      .where((s) => s.album != null && s.album!.isNotEmpty)
                      .map((s) => s.album!)
                      .toSet()
                      .length;
                  final uniqueArtists = allSongsData.map((s) => s.artist).toSet().length;
                  
                  return Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Songs', '${allSongsData.length}', Icons.music_note_rounded, const Color(0xFF4A148C), const Color(0xFF7C3AED))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Albums', '$uniqueAlbums', Icons.album_rounded, const Color(0xFF0D47A1), const Color(0xFF2979FF))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Artists', '$uniqueArtists', Icons.mic_rounded, const Color(0xFF004D40), const Color(0xFF00E676))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Playlists', '${audioProvider.userPlaylists.length}', Icons.folder_rounded, const Color(0xFFE65100), const Color(0xFFFF9100))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Favourites', '${audioProvider.favourites.length}', Icons.favorite_rounded, const Color(0xFFB71C1C), const Color(0xFFFF5252))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSummaryCard('Downloaded', '0', Icons.download_rounded, const Color(0xFF311B92), const Color(0xFF651FFF))),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── List Header ──────────────────────────────────────────────────
          if (_isListView && (_activeSection == 'Songs' || _activeSection == 'Favourites')) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
                child: _buildTableHeader(theme),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Container(height: 1, color: theme.borderColor),
              ),
            ),
          ] else if (!_isListView || _activeSection == 'Artists' || _activeSection == 'Albums' || _activeSection == 'Playlists') ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                child: Text(
                  _activeSection,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 40),
              child: Consumer<AudioProvider>(
                builder: (context, audioProvider, _) {
                  final query = _searchController.text.toLowerCase();
                  
                  List<Song> filterSongs(List<Song> inputSongs) {
                    if (query.isEmpty) return inputSongs;
                    return inputSongs.where((s) {
                      return s.title.toLowerCase().contains(query) ||
                             s.artist.toLowerCase().contains(query) ||
                             (s.album != null && s.album!.toLowerCase().contains(query));
                    }).toList();
                  }

                  if (_activeSection == 'Songs') {
                    final songs = _getSortedSongs(filterSongs(allSongsData));
                    if (_isListView) {
                      return Column(
                        children: songs.asMap().entries.map((e) {
                          return _buildSongRow(context, e.key + 1, e.value, audioProvider, songs);
                        }).toList(),
                      );
                    } else {
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: songs.map((s) => _buildSongGridItem(context, s, audioProvider, songs)).toList(),
                      );
                    }
                  } else if (_activeSection == 'Favourites') {
                    final favourites = _getSortedSongs(filterSongs(audioProvider.favourites.map((e) => e.song).toList()));
                    if (favourites.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No favourites yet', style: TextStyle(color: Colors.white54)),
                        ),
                      );
                    }
                    if (_isListView) {
                      return Column(
                        children: favourites.asMap().entries.map((e) {
                          return _buildSongRow(context, e.key + 1, e.value, audioProvider, favourites);
                        }).toList(),
                      );
                    } else {
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: favourites.map((s) => _buildSongGridItem(context, s, audioProvider, favourites)).toList(),
                      );
                    }
                  } else if (_activeSection == 'Artists') {
                    final uniqueArtists = _getUniqueArtists();
                    return Wrap(
                      spacing: 32,
                      runSpacing: 32,
                      children: uniqueArtists.map((artist) => _buildArtistCard(artist)).toList(),
                    );
                  } else if (_activeSection == 'Albums') {
                    final uniqueAlbums = _getUniqueAlbums();
                    return Wrap(
                      spacing: 32,
                      runSpacing: 32,
                      children: uniqueAlbums.map((album) => _buildAlbumCard(album)).toList(),
                    );
                  } else if (_activeSection == 'Playlists') {
                    final playlists = audioProvider.userPlaylists;
                    return Wrap(
                      spacing: 32,
                      runSpacing: 32,
                      children: [
                        _buildCreatePlaylistCard(context, theme),
                        ...playlists.map((playlist) => _buildPlaylistCard(playlist)).toList(),
                      ],
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text('Nothing here yet', style: TextStyle(color: theme.textSecondaryColor)),
                    ),
                  );
                },
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isList, IconData icon, AppThemeExtension theme) {
    final isActive = _isListView == isList;
    return GestureDetector(
      onTap: () => setState(() => _isListView = isList),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? theme.accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isActive
              ? Border.all(color: theme.accentColor.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? theme.accentColor : theme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color bgColor, Color iconColor) {
    return _SummaryCard(
      title: title,
      count: count,
      icon: icon,
      bgColor: bgColor,
      iconColor: iconColor,
      isActive: _activeSection == title,
      onTap: () {
        setState(() {
          _activeSection = title;
        });
      },
    );
  }

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1))),
        Expanded(flex: 4, child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1))),
        Expanded(flex: 3, child: Text('ARTIST', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1))),
        Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1))),
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Icon(Icons.access_time, color: theme.textSecondaryColor, size: 14),
              const SizedBox(width: 4),
              Text('DURATION', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
        SizedBox(
          width: 120,
          child: Text('ADDED', style: TextStyle(color: theme.textSecondaryColor, fontSize: 11, letterSpacing: 1)),
        ),
        const SizedBox(width: 80), // For heart and more actions
      ],
    );
  }

  Widget _buildSongRow(
    BuildContext context,
    int index,
    Song song,
    AudioProvider audioProvider,
    List<Song> playlist,
  ) {
    final bool isCurrentSong = audioProvider.currentSong?.id == song.id;
    final bool isLiked = audioProvider.isFavourite(song);
    
    final addedTime = song.addedAt;

    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return InkWell(
      onTap: () {
        if (isCurrentSong) {
          audioProvider.togglePlayPause();
        } else {
          audioProvider.playSong(song, playlist: playlist);
        }
      },
      borderRadius: BorderRadius.circular(8),
      hoverColor: theme.borderColor.withValues(alpha: 0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.only(left: 12, right: 16, top: 10, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCurrentSong
              ? theme.accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isCurrentSong
              ? Border(
                  left: BorderSide(
                    color: theme.accentColor,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // # or equalizer
            SizedBox(
              width: 40,
              child: isCurrentSong
                  ? Icon(Icons.equalizer, color: theme.accentColor, size: 16)
                  : Text('$index', style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
            ),

            // Art + Title
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: buildCoverImage(song.coverPath, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentSong ? theme.accentColor : theme.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Artist
            Expanded(
              flex: 3,
              child: Text(
                song.artist,
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Album
            Expanded(
              flex: 3,
              child: Text(
                song.album ?? '—',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Duration
            SizedBox(
              width: 100,
              child: Text(
                formatDuration(song.duration),
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),

            // Added
            SizedBox(
              width: 120,
              child: Text(
                _formatAddedAt(addedTime),
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),

            // Heart
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                ),
                color: isLiked ? theme.accentColor : theme.textSecondaryColor,
                onPressed: () {
                  if (isLiked) {
                    audioProvider.removeFavourite(song);
                  } else {
                    audioProvider.addFavourite(song);
                  }
                },
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            
            // More menu
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                color: theme.surfaceColor,
                onSelected: (value) {
                  if (value == 'add_to_playlist') {
                    showAddToPlaylistDialog(context, song);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add_rounded, color: theme.textSecondaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text('Add to Playlist', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongGridItem(BuildContext context, Song song, AudioProvider audioProvider, List<Song> playlist) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final bool isCurrentSong = audioProvider.currentSong?.id == song.id;
    final bool isPlaying = isCurrentSong && audioProvider.isPlaying;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (isCurrentSong) {
            audioProvider.togglePlayPause();
          } else {
            audioProvider.playSong(song, playlist: playlist);
          }
        },
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: getImageProvider(song.coverPath),
                          fit: BoxFit.cover,
                        ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentSong)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.accentColor.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: theme.textColor,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                song.title,
                style: TextStyle(
                  color: isCurrentSong ? theme.accentColor : theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
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
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final bool isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: isSelected ? theme.accentColor : theme.textSecondaryColor,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, color: theme.accentColor, size: 16),
          ],
        ],
      ),
    );
  }

  List<Song> _getSortedSongs(List<Song> songs) {
    final List<Song> sorted = List.from(songs);
    switch (_sortBy) {
      case 'A-Z':
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Z-A':
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'Recently Added':
      default:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
    }
    return sorted;
  }

  List<_ArtistItem> _getUniqueArtists() {
    final seen = <String>{};
    final items = <_ArtistItem>[];
    for (var s in allSongsData) {
      if (seen.add(s.artist)) {
        items.add(_ArtistItem(s.artist, s.coverPath));
      }
    }
    return items;
  }

  List<_AlbumItem> _getUniqueAlbums() {
    final seen = <String>{};
    final items = <_AlbumItem>[];
    for (var s in allSongsData) {
      // Only include songs with a defined, non-empty album name
      if (s.album == null || s.album!.isEmpty) continue;
      if (seen.add(s.album!)) {
        // Use cover of the first song with this album as the album cover
        items.add(_AlbumItem(s.album!, s.artist, s.coverPath));
      }
    }
    return items;
  }

  Widget _buildArtistCard(_ArtistItem artist) {
    return _ArtistCard(
      artist: artist,
      onTap: () => setState(() => _selectedArtist = artist.name),
    );
  }

  Widget _buildAlbumCard(_AlbumItem album) {
    return _AlbumCard(
      album: album,
      onTap: () => setState(() => _selectedAlbum = album.title),
    );
  }

  Widget _buildCreatePlaylistCard(BuildContext context, AppThemeExtension theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showCreatePlaylistDialog(context),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Center(
                  child: Icon(Icons.add_rounded, size: 48, color: theme.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text('Create Playlist', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Make it yours', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(UserPlaylist playlist) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    
    String? displayCover = playlist.coverPath;
    if ((displayCover == null || displayCover.isEmpty) && playlist.songIds.isNotEmpty) {
      try {
        final firstSongId = playlist.songIds.first;
        final firstSong = allSongsData.firstWhere((s) => s.id == firstSongId);
        displayCover = firstSong.coverPath;
      } catch (e) {
        // Fallback to empty if not found
      }
    }

    final hasCover = displayCover != null && displayCover.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserPlaylist = playlist;
          });
        },
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                  image: hasCover
                      ? DecorationImage(image: getImageProvider(displayCover!), fit: BoxFit.cover)
                      : null,
                ),
                child: hasCover
                    ? null
                    : Center(
                        child: Icon(Icons.queue_music_rounded, size: 48, color: theme.textSecondaryColor.withValues(alpha: 0.5)),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                playlist.title,
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${playlist.songIds.length} tracks',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistItem {
  final String name;
  final String coverPath;
  _ArtistItem(this.name, this.coverPath);
}

class _AlbumItem {
  final String title;
  final String artist;
  final String coverPath;
  _AlbumItem(this.title, this.artist, this.coverPath);
}

class _ArtistCard extends StatefulWidget {
  final _ArtistItem artist;
  final VoidCallback onTap;
  const _ArtistCard({required this.artist, required this.onTap});

  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
                    border: Border.all(
                      color: _isHovered ? const Color(0xFF7C3AED) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                    child: buildCoverImage(widget.artist.coverPath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.artist.name,
                  style: TextStyle(
                    color: _isHovered ? const Color(0xFF9D6FEF) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Artist',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final _AlbumItem album;
  final VoidCallback onTap;
  const _AlbumCard({required this.album, required this.onTap});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isHovered ? const Color(0xFF7C3AED) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: buildCoverImage(widget.album.coverPath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.album.title,
                  style: TextStyle(
                    color: _isHovered ? const Color(0xFF9D6FEF) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.album.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
}

class _SummaryCard extends StatefulWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isActive;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive ? widget.bgColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isActive ? widget.iconColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.02),
              ),
              boxShadow: widget.isActive ? [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.bgColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.count,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

