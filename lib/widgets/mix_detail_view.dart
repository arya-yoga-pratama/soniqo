import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/audio_provider.dart';
import 'image_helper.dart';
import '../utils/formatters.dart';

class MixDetailView extends StatelessWidget {
  final Playlist playlist;
  final List<Song> allSongs;
  final VoidCallback onBack;
  final Function(String) onArtistTap;

  const MixDetailView({
    super.key,
    required this.playlist,
    required this.allSongs,
    required this.onBack,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = playlist.songs.fold<Duration>(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    final durationStr = _formatTotalDuration(totalDuration);

    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Navigation ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 20, bottom: 24),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        const Text(
                          'Back',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Playlist Info Section ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Large Cover Art
                    _buildCoverArt(),
                    const SizedBox(width: 40),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MADE FOR YOU',
                            style: TextStyle(
                              color: Color(0xFFA54BFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            playlist.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            playlist.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Avatar and Update Info
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2A1F5C),
                                ),
                                child: const Icon(Icons.person_outline, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Soniqo',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.white38)),
                              const SizedBox(width: 8),
                              Text(
                                'Updated today',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons & Stats Row
                          Row(
                            children: [
                              // Play All / Toggle Play
                              _PlayToggleButton(
                                isPlaying: audio.isPlaying && playlist.songs.any((s) => s.id == audio.currentSong?.id),
                                onPressed: () {
                                  if (playlist.songs.isNotEmpty) {
                                    final isFromThisPlaylist = playlist.songs.any((s) => s.id == audio.currentSong?.id);
                                    if (isFromThisPlaylist) {
                                      audio.togglePlayPause();
                                    } else {
                                      audio.playSong(playlist.songs.first, playlist: playlist.songs);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 16),

                              // Shuffle
                              _buildOutlineButton(Icons.shuffle_rounded, 'Shuffle', () {}),
                              const SizedBox(width: 16),

                              // Like
                              _buildCircleButton(Icons.favorite_border_rounded, () {}),
                              const SizedBox(width: 12),

                              // More
                              _buildCircleButton(Icons.more_horiz_rounded, () {}),
                              
                              const Spacer(),

                              // Stats
                              _buildStat('Songs', playlist.songs.length.toString()),
                              const SizedBox(width: 40),
                              _buildStat('Duration', durationStr),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Content Layout (Table + Sidebar) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Song List Table
                    Expanded(
                      flex: 70,
                      child: _buildSongTable(audio),
                    ),
                    const SizedBox(width: 48),

                    // Right: Sidebar
                    Expanded(
                      flex: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSidebarSection(
                            'About this playlist',
                            playlist.about ?? 'A personalized mix of ${playlist.title.replaceFirst(' Mix', '').replaceFirst(' Hits', '')}\'s songs and similar tracks that match your vibe.',
                          ),
                          const SizedBox(height: 40),
                          _buildYoullAlsoLikeSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverArt() {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            buildCoverImage(playlist.coverPath, width: 240, height: 240, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    playlist.gradientColors[0].withValues(alpha: 0.8),
                    playlist.gradientColors[1].withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Icon(Icons.library_music_rounded, color: Colors.white.withValues(alpha: 0.9), size: 32),
            ),
            Center(
              child: Text(
                playlist.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 0.9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: Colors.white,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(color: Color(0xFFA54BFF), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSongTable(AudioProvider audio) {
    return Column(
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              SizedBox(width: 32, child: Text('#', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 5, child: Text('TITLE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(flex: 4, child: Text('ALBUM', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 60, child: Center(child: Icon(Icons.access_time_rounded, color: Colors.white38, size: 16))),
              SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(color: Color(0xFF202020), height: 1),
        const SizedBox(height: 8),

        // Song Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playlist.songs.length,
          itemBuilder: (context, index) {
            final song = playlist.songs[index];
            final isPlaying = audio.currentSong?.id == song.id;
            return _SongRow(
              index: index + 1,
              song: song,
              isPlaying: isPlaying,
              onTap: () => audio.playSong(song, playlist: playlist.songs),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSidebarSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          content,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildYoullAlsoLikeSection() {
    // Current artists in this playlist
    final currentArtists = playlist.songs.map((s) => s.artist).toSet();
    
    // Find all artists available in the data
    final allArtistNames = allSongs.map((s) => s.artist).toSet();
    
    // Filter out artists that are already in this playlist to recommend "others"
    final recommendedArtistNames = allArtistNames
        .where((name) => !currentArtists.contains(name))
        .take(3)
        .toList();
        
    // If we don't have enough "other" artists, fill with current ones (but not the main one if possible)
    if (recommendedArtistNames.length < 2) {
      recommendedArtistNames.addAll(
        currentArtists.take(3 - recommendedArtistNames.length)
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You\'ll also like',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...recommendedArtistNames.map((artistName) {
          // Find a cover for this artist
          final artistCover = allSongs.firstWhere((s) => s.artist == artistName).coverPath;
          return _ArtistTile(
            artistName: artistName, 
            coverPath: artistCover,
            onTap: () => onArtistTap(artistName),
          );
        }),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.7),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('See more', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _formatTotalDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }
}

class _SongRow extends StatefulWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongRow({
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? const Color(0xFF1A1A1A)
                : (_hovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Index / Play Icon
              SizedBox(
                width: 32,
                child: widget.isPlaying
                    ? const Icon(Icons.play_arrow_rounded, color: Color(0xFFA54BFF), size: 18)
                    : Text(
                        widget.index.toString(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
              ),

              // Title & Artist
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: buildCoverImage(widget.song.coverPath, width: 42, height: 42, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            style: TextStyle(
                              color: widget.isPlaying ? const Color(0xFFA54BFF) : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.song.artist,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Album
              Expanded(
                flex: 4,
                child: Text(
                  widget.song.album?.isNotEmpty == true ? widget.song.album! : 'Unknown Album',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Duration
              SizedBox(
                width: 60,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.song.isLiked)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.favorite_rounded, color: Color(0xFFA54BFF), size: 14),
                        ),
                      Text(
                        formatDuration(widget.song.duration),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // More
              SizedBox(
                width: 40,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: _hovered ? Colors.white70 : Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class _ArtistTile extends StatefulWidget {
  final String artistName;
  final String coverPath;
  final VoidCallback onTap;

  const _ArtistTile({
    required this.artistName,
    required this.coverPath,
    required this.onTap,
  });

  @override
  State<_ArtistTile> createState() => _ArtistTileState();
}
class _PlayToggleButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayToggleButton({required this.isPlaying, required this.onPressed});

  @override
  State<_PlayToggleButton> createState() => _PlayToggleButtonState();
}

class _PlayToggleButtonState extends State<_PlayToggleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFA54BFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA54BFF).withValues(alpha: 0.2),
                blurRadius: 12,
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
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isPlaying ? 'Pause' : 'Play All',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistTileState extends State<_ArtistTile> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isHovered ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Avatar with Stroke and Glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isHovered ? const Color(0xFFA54BFF) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: const Color(0xFFA54BFF).withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: buildCoverImage(widget.coverPath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artistName,
                          style: TextStyle(
                            color: _isHovered ? const Color(0xFFA54BFF) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Artist',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Small Arrow appears on hover
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFA54BFF), size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
