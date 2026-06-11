import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/favourite_entry.dart';
import '../models/song.dart';
import 'app_search_bar.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';

class FavouriteContent extends StatefulWidget {
  const FavouriteContent({super.key});

  @override
  State<FavouriteContent> createState() => _FavouriteContentState();
}

class _FavouriteContentState extends State<FavouriteContent> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();

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

  String _formatAddedAt(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final timeStr = '$h12:$m $period';
    if (diff.inDays == 0) return 'Today, $timeStr';
    if (diff.inDays == 1) return 'Yesterday, $timeStr';
    return '${time.day}/${time.month}/${time.year}';
  }



  Duration _totalDuration(List<FavouriteEntry> entries) {
    return entries.fold(Duration.zero, (sum, e) => sum + e.song.duration);
  }

  String _formatTotalDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours} hr ${d.inMinutes.remainder(60)} min';
    }
    return '${d.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      color: Colors.transparent,
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, _) {
          final rawFavourites = audioProvider.favourites;
          final query = _searchController.text.toLowerCase();

          final favourites = rawFavourites.where((entry) {
            final song = entry.song;
            return song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query);
          }).toList();

          return CustomScrollView(
            slivers: [
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
                      Row(
                        children: [
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
                          AppSearchBar(controller: _searchController),
                        ],
                      ),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.7)],
                          ),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: theme.textColor,
                          size: 72,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'PLAYLIST',
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Liked Songs',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                rawFavourites.isEmpty
                                    ? 'No liked songs yet'
                                    : '${rawFavourites.length} song${rawFavourites.length > 1 ? 's' : ''} • ${_formatTotalDuration(_totalDuration(rawFavourites))}',
                                style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                  child: Row(
                    children: [
                      _FavouritePlayButton(
                        isPlaying: rawFavourites.isNotEmpty && audioProvider.isPlaying && rawFavourites.any((e) => e.song.id == audioProvider.currentSong?.id),
                        onPressed: rawFavourites.isNotEmpty
                            ? () {
                                final isFromFav = rawFavourites.any((e) => e.song.id == audioProvider.currentSong?.id);
                                if (isFromFav) {
                                  audioProvider.togglePlayPause();
                                } else {
                                  final songs = rawFavourites.map((e) => e.song).toList();
                                  audioProvider.setPlaylist(songs);
                                  audioProvider.playSong(songs.first);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: rawFavourites.isNotEmpty ? SystemMouseCursors.click : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: rawFavourites.isNotEmpty
                              ? () {
                                  final songs = List<Song>.from(rawFavourites.map((e) => e.song))..shuffle();
                                  audioProvider.setPlaylist(songs);
                                  audioProvider.playSong(songs.first);
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.shuffle_rounded, color: rawFavourites.isNotEmpty ? theme.textSecondaryColor : theme.borderColor, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Shuffle',
                                  style: TextStyle(
                                    color: rawFavourites.isNotEmpty ? theme.textSecondaryColor : theme.borderColor,
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
                ),
              ),

              if (rawFavourites.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(theme))
              else if (favourites.isEmpty)
                SliverToBoxAdapter(child: _buildNoResultsState(theme))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                    child: Column(
                      children: [
                        _buildTableHeader(theme),
                        Container(height: 1, color: theme.borderColor),
                        const SizedBox(height: 4),
                        ...favourites.asMap().entries.map((e) => _buildSongRow(
                          context, 
                          e.key + 1, 
                          e.value, 
                          audioProvider.currentSong?.id == e.value.song.id && audioProvider.isPlaying, 
                          audioProvider,
                          playlist: favourites.map((item) => item.song).toList()
                        )),
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

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 4, child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5))),
          SizedBox(
            width: 160,
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.textSecondaryColor, size: 13),
                SizedBox(width: 4),
                Text('DATE ADDED', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 0.5)),
              ],
            ),
          ),
          SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, int number, FavouriteEntry entry, bool isPlaying, AudioProvider audioProvider, {List<Song>? playlist}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final Song song = entry.song;
    final isCurrentSong = audioProvider.currentSong?.id == song.id;
    final isPlayingNow = isPlaying;

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCurrentSong ? theme.accentColor.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: isPlayingNow
                  ? Icon(Icons.equalizer, color: theme.accentColor, size: 16)
                  : Text('$number', style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: buildCoverImage(song.coverPath, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong ? theme.accentColor : theme.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(song.artist, style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Album
            Expanded(
              flex: 3,
              child: Text(
                song.album?.isNotEmpty == true ? song.album! : 'Unknown Album',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Date Added
            SizedBox(
              width: 160,
              child: Text(
                _formatAddedAt(entry.addedAt),
                style: TextStyle(
                  color: isCurrentSong ? theme.accentColor : theme.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ),

            // Duration
            SizedBox(
              width: 40,
              child: Text(
                formatDuration(song.duration),
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),

            // Play/Pause button
              GestureDetector(
              onTap: () {
                if (isCurrentSong) {
                  audioProvider.togglePlayPause();
                } else {
                  audioProvider.playSong(song, playlist: playlist);
                }
              },
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrentSong
                      ? theme.accentColor
                      : theme.borderColor.withValues(alpha: 0.5),
                ),
                child: Icon(
                  isPlayingNow ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Unlike button
            IconButton(
              icon: const Icon(Icons.favorite_rounded, size: 18),
              color: theme.accentColor,
              tooltip: 'Remove from Liked Songs',
              onPressed: () => audioProvider.removeFavourite(song),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),

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
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: theme.accentColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No liked songs yet',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start liking songs and they will appear here.\nClick the ♥ button while a song is playing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.borderColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
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
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouritePlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;

  const _FavouritePlayButton({required this.isPlaying, required this.onPressed});

  @override
  State<_FavouritePlayButton> createState() => _FavouritePlayButtonState();
}

class _FavouritePlayButtonState extends State<_FavouritePlayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                : const Color(0xFF7C3AED),
            borderRadius: BorderRadius.circular(50),
            boxShadow: isDisabled ? [] : [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isPlaying ? 'Pause' : 'Play All',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
