import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../models/song.dart';
import 'app_search_bar.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';
import '../data/songs_data.dart';

class DownloadedContent extends StatefulWidget {
  const DownloadedContent({super.key});

  @override
  State<DownloadedContent> createState() => _DownloadedContentState();
}

class _DownloadedContentState extends State<DownloadedContent> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      color: Colors.transparent,
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, _) {
          final query = _searchController.text.toLowerCase();
          
          // For demonstration, let's take some songs from allSongsData and treat them as "downloaded"
          final downloadedSongs = allSongsData.where((song) {
            final matchesQuery = song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query);
            return matchesQuery;
          }).take(5).toList(); // Just take 5 for the mockup

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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00C853), // Modern green for downloads
                              Color(0xFF00E676),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download_for_offline_rounded,
                          color: Colors.white,
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
                                'OFFLINE LIBRARY',
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Downloaded',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: theme.textColor,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: theme.accentColor.withValues(alpha: 0.2),
                                    child: Icon(Icons.person, size: 14, color: theme.accentColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'User • ${downloadedSongs.length} songs • 248 MB',
                                    style: TextStyle(
                                      color: theme.textSecondaryColor, 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
                  child: Row(
                    children: [
                      _DownloadPlayButton(
                        isPlaying: downloadedSongs.isNotEmpty && 
                                   audioProvider.isPlaying && 
                                   downloadedSongs.any((s) => s.id == audioProvider.currentSong?.id),
                        onPressed: downloadedSongs.isNotEmpty
                            ? () {
                                final isCurrentInList = downloadedSongs.any((s) => s.id == audioProvider.currentSong?.id);
                                if (isCurrentInList) {
                                  audioProvider.togglePlayPause();
                                } else {
                                  audioProvider.setPlaylist(downloadedSongs);
                                  audioProvider.playSong(downloadedSongs.first);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(Icons.shuffle_rounded, 'Shuffle', theme),
                      const SizedBox(width: 12),
                      _buildActionButton(Icons.sort_rounded, 'Date Downloaded', theme),
                      const Spacer(),
                      _buildActionButton(Icons.settings_suggest_outlined, 'Storage Settings', theme),
                    ],
                  ),
                ),
              ),

              if (downloadedSongs.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(theme))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    child: Column(
                      children: [
                        _buildTableHeader(theme),
                        Container(height: 1, color: theme.borderColor.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(vertical: 8)),
                        ...downloadedSongs.asMap().entries.map((e) => _buildSongRow(
                          context, 
                          e.key + 1, 
                          e.value, 
                          audioProvider.currentSong?.id == e.value.id && audioProvider.isPlaying, 
                          audioProvider,
                          playlist: downloadedSongs
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

  Widget _buildActionButton(IconData icon, String label, AppThemeExtension theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: theme.textSecondaryColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
          SizedBox(width: 100, child: Text('SIZE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
          SizedBox(width: 40, child: Icon(Icons.access_time, color: theme.textSecondaryColor, size: 14)),
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, int number, Song song, bool isPlaying, AudioProvider audioProvider, {List<Song>? playlist}) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final isCurrentSong = audioProvider.currentSong?.id == song.id;

    return InkWell(
      onTap: () {
        if (isCurrentSong) {
          audioProvider.togglePlayPause();
        } else {
          audioProvider.playSong(song, playlist: playlist);
        }
      },
      borderRadius: BorderRadius.circular(12),
      hoverColor: theme.borderColor.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isCurrentSong ? theme.accentColor.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: isPlaying
                  ? Icon(Icons.equalizer_rounded, color: theme.accentColor, size: 18)
                  : Text('$number', style: TextStyle(color: theme.textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: buildCoverImage(song.coverPath, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong ? theme.accentColor : theme.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist, 
                          style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
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
                'Offline Collection',
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${(song.title.length * 0.8).toStringAsFixed(1)} MB', // Fake size
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                formatDuration(song.duration),
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: const Color(0xFF00C853).withValues(alpha: 0.8), size: 18),
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
                color: theme.borderColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: 40,
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No downloads yet',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your downloaded songs will appear here.\nDownload your favorite tracks to listen offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('Explore Music', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;

  const _DownloadPlayButton({required this.isPlaying, required this.onPressed});

  @override
  State<_DownloadPlayButton> createState() => _DownloadPlayButtonState();
}

class _DownloadPlayButtonState extends State<_DownloadPlayButton> {
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
                ? const Color(0xFF00C853).withValues(alpha: 0.3)
                : const Color(0xFF00C853),
            borderRadius: BorderRadius.circular(50),
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
