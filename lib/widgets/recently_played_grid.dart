import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';

/// Dynamically shows the last 4 unique songs from play history.
/// Shows an empty-state prompt if nothing has been played yet.
class RecentlyPlayedGrid extends StatefulWidget {
  /// Full song list — used as the playlist context when playSong is called.
  final List<Song> allSongs;
  final VoidCallback? onViewAll;

  const RecentlyPlayedGrid({
    super.key, 
    required this.allSongs,
    this.onViewAll,
  });

  @override
  State<RecentlyPlayedGrid> createState() => _RecentlyPlayedGridState();
}

class _RecentlyPlayedGridState extends State<RecentlyPlayedGrid> {
  List<Song> _suggestedSongs = [];

  @override
  void initState() {
    super.initState();
    _pickSuggestedSongs();
  }

  void _pickSuggestedSongs() {
    if (widget.allSongs.isEmpty) return;

    // Pick 4 random songs from different "albums" (unique coverPath)
    final shuffled = List<Song>.from(widget.allSongs)..shuffle();
    final seenCovers = <String>{};
    final picked = <Song>[];

    for (var song in shuffled) {
      if (seenCovers.add(song.coverPath)) {
        picked.add(song);
      }
      if (picked.length == 4) break;
    }

    // Fallback: fill with any songs if we couldn't find 4 unique covers
    if (picked.length < 4) {
      for (var song in shuffled) {
        if (!picked.any((s) => s.id == song.id)) {
          picked.add(song);
        }
        if (picked.length == 4) break;
      }
    }

    _suggestedSongs = picked;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        // Deduplicate history: keep only the most recent play per song.
        final seen = <String>{};
        final List<Song> historySongs = audio.playHistory
            .map((e) => e.song)
            .where((s) => seen.add(s.id))
            .take(4)
            .toList();

        // Combine history with suggestions to always have 4 songs
        final List<Song> displaySongs = List.from(historySongs);
        if (displaySongs.length < 4) {
          for (var song in _suggestedSongs) {
            if (!displaySongs.any((s) => s.id == song.id)) {
              displaySongs.add(song);
            }
            if (displaySongs.length == 4) break;
          }
        }

        final bool hasActualHistory = historySongs.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently Played',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (hasActualHistory)
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
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

            const SizedBox(height: 14),

            // ── Content area ─────────────────────────────────────────────
            // Base: Always render exactly 4 slots to dictate the natural height.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (i) {
                final song = i < displaySongs.length ? displaySongs[i] : null;
                return [
                  Expanded(
                    child: song != null
                        ? _RecentCard(
                            song: song,
                            isActive: audio.currentSong?.id == song.id,
                            onTap: () => audio.playSong(song, playlist: widget.allSongs),
                          )
                        : const _GhostCard(),
                  ),
                  if (i < 3) const SizedBox(width: 12),
                ];
              }).expand((w) => w).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ghost card — transparent placeholder to fill empty slots
// ─────────────────────────────────────────────────────────────────────────────
class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.music_note_outlined,
            color: Colors.white.withValues(alpha: 0.1),
            size: 28,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real recently-played card
// ─────────────────────────────────────────────────────────────────────────────
class _RecentCard extends StatefulWidget {
  final Song song;
  final bool isActive;
  final VoidCallback onTap;

  const _RecentCard({
    required this.song,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends State<_RecentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -8.0 : 0.0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? theme.accentColor.withValues(alpha: 0.15)
                : _hovered
                    ? theme.borderColor.withValues(alpha: 0.5)
                    : theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isActive
                ? Border.all(
                    color: theme.accentColor.withValues(alpha: 0.6),
                    width: 1.2,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 1.2,
                  ),
            boxShadow: _hovered || widget.isActive
                ? [
                    BoxShadow(
                      color: theme.accentColor.withValues(
                          alpha: _hovered ? 0.85 : (widget.isActive ? 0.5 : 0.0)),
                      blurRadius: _hovered ? 28 : 18,
                      spreadRadius: _hovered ? 6 : 2,
                      offset: Offset(0, _hovered ? 8 : 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Cover with play button ──────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: buildCoverImage(
                        widget.song.coverPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _hovered ? 1.08 : 1.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Title ────────────────────────────────────────────────
              Text(
                widget.song.title,
                style: TextStyle(
                  color: widget.isActive
                      ? theme.accentColor
                      : theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // ── Artist ───────────────────────────────────────────────
              Text(
                widget.song.artist,
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
}
