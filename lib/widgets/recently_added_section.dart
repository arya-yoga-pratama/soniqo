import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';

/// Recently Added — horizontal strip of album covers (left column, row 3).
class RecentlyAddedSection extends StatelessWidget {
  final List<Song> songs;
  final VoidCallback? onViewAll;
  const RecentlyAddedSection({super.key, required this.songs, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final sortedSongs = List<Song>.from(songs);
    sortedSongs.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final displayed = sortedSongs.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recently Added',
                style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, overlayColor: Colors.transparent),
              child: const Text('View all', style: TextStyle(color: Color(0xFFA54BFF), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 125, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayed.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 12,
                left: i == 0 ? 2 : 0,
                right: 18,
              ),
              child: _AddedCard(
                song: displayed[i],
                playlist: displayed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddedCard extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  const _AddedCard({required this.song, required this.playlist});
  @override
  State<_AddedCard> createState() => _AddedCardState();
}

class _AddedCardState extends State<_AddedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        final bool isCurrent = audio.currentSong?.id == widget.song.id;
        final bool isPlaying = isCurrent && audio.isPlaying;
        final bool showGlow = _hovered || isCurrent;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (showGlow)
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: isCurrent ? 0.3 : 0.18),
                      blurRadius: isCurrent ? 24 : 16,
                      spreadRadius: isCurrent ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  if (isCurrent)
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: AnimatedScale(
                scale: _hovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildCoverImage(widget.song.coverPath, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    // Glassy overlay when active or hovered
                    if (_hovered || isCurrent)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            color: Colors.black.withValues(alpha: isCurrent ? 0.4 : 0.25),
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: _hovered ? 1.1 : 1.0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isCurrent ? const Color(0xFFA54BFF) : Colors.white24,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (isCurrent)
                                        BoxShadow(
                                          color: const Color(0xFFA54BFF).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                        )
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
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
            ),
          ),
        );
      },
    );
  }
}
