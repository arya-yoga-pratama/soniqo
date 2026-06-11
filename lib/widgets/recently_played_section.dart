import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';

class RecentlyPlayedSection extends StatelessWidget {
  final List<Song> songs;

  const RecentlyPlayedSection({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final displayed = songs.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Recently Played',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: Colors.transparent,
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: Theme.of(context).extension<AppThemeExtension>()!.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Horizontal Card List ────────────────────────────────────────────
        SizedBox(
          height: 208,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayed.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == displayed.length - 1 ? 0 : 14,
                ),
                child: _RecentlyPlayedCard(song: displayed[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Individual Card ─────────────────────────────────────────────────────────
class _RecentlyPlayedCard extends StatefulWidget {
  final Song song;
  const _RecentlyPlayedCard({required this.song});

  @override
  State<_RecentlyPlayedCard> createState() => _RecentlyPlayedCardState();
}

class _RecentlyPlayedCardState extends State<_RecentlyPlayedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -8.0 : 0.0, 0),
          child: SizedBox(
            width: 142,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image ───────────────────────────────────────────
                Stack(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (_hovered)
                              BoxShadow(
                                color: theme.accentColor.withValues(alpha: 0.85),
                                blurRadius: 28,
                                spreadRadius: 6,
                                offset: const Offset(0, 8),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: buildCoverImage(
                          widget.song.coverPath,
                          width: 142,
                          height: 142,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Bottom gradient so play button is readable
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black
                                    .withValues(alpha: _hovered ? 0.65 : 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Play button – bottom-right, always slightly visible
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: _hovered ? 10 : 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Song Title ────────────────────────────────────────────
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // ── Artist Name ───────────────────────────────────────────
                Text(
                  widget.song.artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.2,
                  ),
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
