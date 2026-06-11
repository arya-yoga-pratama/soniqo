import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import 'image_helper.dart';

class TrendingSection extends StatelessWidget {
  final List<Song> songs;
  const TrendingSection({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        // Sort songs by total play count (descending)
        final sortedSongs = List<Song>.from(songs);
        sortedSongs.sort((a, b) {
          int cmp = b.playCount.compareTo(a.playCount);
          if (cmp == 0) {
            return b.addedAt.compareTo(a.addedAt);
          }
          return cmp;
        });

        // Take top 3 for this small preview section
        final displayed = sortedSongs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trending Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: Colors.transparent),
                  child: const Text('View all',
                      style: TextStyle(
                          color: Color(0xFFA54BFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: displayed.asMap().entries.map((e) {
                final song = e.value;
                final isActive = audio.currentSong?.id == song.id;
                return _TrendingRow(
                  rank: e.key + 1,
                  song: song,
                  isActive: isActive,
                  onTap: () => audio.playSong(song, playlist: sortedSongs),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _TrendingRow extends StatefulWidget {
  final int rank;
  final Song song;
  final bool isActive;
  final VoidCallback onTap;

  const _TrendingRow({
    required this.rank,
    required this.song,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TrendingRow> createState() => _TrendingRowState();
}

class _TrendingRowState extends State<_TrendingRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isPlaying
                ? const Color(0xFFA54BFF).withValues(alpha: 0.12)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isPlaying
                ? Border.all(
                    color: const Color(0xFFA54BFF).withValues(alpha: 0.3),
                    width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text('${widget.rank}',
                    style: TextStyle(
                        color: isPlaying
                            ? const Color(0xFFA54BFF)
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: buildCoverImage(widget.song.coverPath,
                    width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.song.title,
                        style: TextStyle(
                            color: isPlaying
                                ? const Color(0xFFA54BFF)
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(widget.song.artist,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFFA54BFF)
                      : _hovered
                          ? const Color(0xFFA54BFF)
                          : Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: (isPlaying || _hovered)
                        ? Colors.white
                        : Colors.white60,
                    size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
