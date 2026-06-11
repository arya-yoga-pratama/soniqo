import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../utils/formatters.dart';
import 'image_helper.dart';

class AlbumDetailView extends StatelessWidget {
  final String albumName;
  final List<Song> allSongs;
  final VoidCallback onBack;

  const AlbumDetailView({
    super.key,
    required this.albumName,
    required this.allSongs,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Filter songs by album name or fallback to title for singles
    final albumSongs = allSongs
        .where((s) {
          final hasRealAlbum = s.album != null && s.album!.trim().isNotEmpty;
          if (hasRealAlbum) return s.album == albumName;
          return s.title == albumName; // Treat single as its own album
        })
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    // Determine artist label
    final artists = albumSongs.map((s) => s.artist).toSet();
    final artistLabel =
        artists.length == 1 ? artists.first : 'Various Artists';

    // Cover from first song
    final coverPath =
        albumSongs.isNotEmpty ? albumSongs.first.coverPath : '';

    // Total duration
    final totalDuration = albumSongs.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back Button ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 24, bottom: 28),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onBack,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Albums',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Album Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Cover Art
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: const Color(0xFFA54BFF).withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: buildCoverImage(coverPath, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 36),

                    // Album Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFA54BFF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFA54BFF)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'ALBUM',
                              style: TextStyle(
                                color: Color(0xFFA54BFF),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            albumName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            artistLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stats row
                          Row(
                            children: [
                              Text(
                                '${albumSongs.length} song${albumSongs.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 13,
                                ),
                              ),
                              if (totalDuration != Duration.zero) ...[
                                Text(
                                  '  ·  ',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                Text(
                                  _formatTotalDuration(totalDuration),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Play button
                          Row(
                            children: [
                              _AlbumPlayButton(
                                isPlaying: audio.isPlaying &&
                                    albumSongs.any(
                                        (s) => s.id == audio.currentSong?.id),
                                onPressed: () {
                                  if (albumSongs.isEmpty) return;
                                  final isFromThisAlbum = albumSongs
                                      .any((s) => s.id == audio.currentSong?.id);
                                  if (isFromThisAlbum) {
                                    audio.togglePlayPause();
                                  } else {
                                    audio.playSong(albumSongs.first,
                                        playlist: albumSongs);
                                  }
                                },
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.more_horiz_rounded),
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Divider(color: Colors.white.withValues(alpha: 0.07)),
              ),
              const SizedBox(height: 8),

              // ── Song Table Header ─────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('#',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              letterSpacing: 1)),
                    ),
                    const Expanded(
                      flex: 5,
                      child: Text('TITLE',
                          style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                              letterSpacing: 1)),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text('ARTIST',
                          style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                              letterSpacing: 1)),
                    ),
                    SizedBox(
                      width: 80,
                      child: Icon(Icons.access_time,
                          color: Colors.white.withValues(alpha: 0.4), size: 14),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Divider(color: Colors.white.withValues(alpha: 0.06)),
              ),

              // ── Song List ─────────────────────────────────────────────────
              if (albumSongs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No songs in this album',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 15),
                    ),
                  ),
                )
              else
                ...albumSongs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final song = entry.value;
                  final isActive = audio.currentSong?.id == song.id;
                  return _AlbumSongTile(
                    song: song,
                    index: index + 1,
                    isActive: isActive,
                    isPlaying: isActive && audio.isPlaying,
                    onTap: () => audio.playSong(song, playlist: albumSongs),
                    onLike: () {
                      if (audio.isFavourite(song)) {
                        audio.removeFavourite(song);
                      } else {
                        audio.addFavourite(song);
                      }
                    },
                    isLiked: audio.isFavourite(song),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _formatTotalDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Play Button ───────────────────────────────────────────────────────────────

class _AlbumPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _AlbumPlayButton(
      {required this.isPlaying, required this.onPressed});

  @override
  State<_AlbumPlayButton> createState() => _AlbumPlayButtonState();
}

class _AlbumPlayButtonState extends State<_AlbumPlayButton> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFA54BFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA54BFF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isPlaying ? 'Pause' : 'Play',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Song Tile ─────────────────────────────────────────────────────────────────

class _AlbumSongTile extends StatefulWidget {
  final Song song;
  final int index;
  final bool isActive;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _AlbumSongTile({
    required this.song,
    required this.index,
    required this.isActive,
    required this.isPlaying,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
  });

  @override
  State<_AlbumSongTile> createState() => _AlbumSongTileState();
}

class _AlbumSongTileState extends State<_AlbumSongTile> {
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFFA54BFF).withValues(alpha: 0.1)
                : (_hovered
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border(
                    left: BorderSide(
                        color: const Color(0xFFA54BFF), width: 3))
                : null,
          ),
          child: Row(
            children: [
              // Index / Equalizer icon
              SizedBox(
                width: 36,
                child: widget.isActive
                    ? Icon(
                        widget.isPlaying
                            ? Icons.equalizer_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFFA54BFF),
                        size: 18,
                      )
                    : Text(
                        '${widget.index}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              // Cover + Title
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: buildCoverImage(widget.song.coverPath,
                          width: 42, height: 42, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.song.title,
                        style: TextStyle(
                          color: widget.isActive
                              ? const Color(0xFFA54BFF)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                  widget.song.artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Duration
              SizedBox(
                width: 80,
                child: Text(
                  formatDuration(widget.song.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ),

              // Like + More
              SizedBox(
                width: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_hovered || widget.isLiked)
                      GestureDetector(
                        onTap: widget.onLike,
                        child: Icon(
                          widget.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: widget.isLiked
                              ? const Color(0xFFA54BFF)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
