import 'package:flutter/material.dart';
import '../models/song.dart';
import 'image_helper.dart';

/// Top Artists — horizontal row of circular avatar cards (right column, row 3).
/// Derives unique artists from the existing song list.
class TopArtistsSection extends StatelessWidget {
  final List<Song> songs;
  final Function(String)? onArtistTap;

  const TopArtistsSection({
    super.key,
    required this.songs,
    this.onArtistTap,
  });

  List<_ArtistDef> _uniqueArtists() {
    final seen = <String>{};
    final artists = <_ArtistDef>[];
    for (final s in songs) {
      if (seen.add(s.artist)) {
        artists.add(_ArtistDef(name: s.artist, coverPath: s.coverPath));
      }
    }
    return artists;
  }

  @override
  Widget build(BuildContext context) {
    final artists = _uniqueArtists();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top Artists',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, overlayColor: Colors.transparent),
              child: const Text('View all', style: TextStyle(color: Color(0xFFA54BFF), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 0),
        SizedBox(
          height: 140, // Increased height to prevent clipping when scaling and glowing
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 18),
            clipBehavior: Clip.hardEdge, // Prevent items from bleeding into neighboring sections when scrolling
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: i == artists.length - 1 ? 0 : 20),
              child: _ArtistCard(
                def: artists[i],
                onTap: onArtistTap != null ? () => onArtistTap!(artists[i].name) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistDef {
  final String name;
  final String coverPath;
  const _ArtistDef({required this.name, required this.coverPath});
}

class _ArtistCard extends StatefulWidget {
  final _ArtistDef def;
  final VoidCallback? onTap;
  const _ArtistCard({required this.def, this.onTap});
  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                // Circular avatar with purple ring on hover
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hovered ? const Color(0xFFA54BFF) : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: _hovered
                        ? [BoxShadow(color: const Color(0xFFA54BFF).withValues(alpha: 0.4), blurRadius: 14)]
                        : [],
                  ),
                  child: ClipOval(
                    child: buildCoverImage(widget.def.coverPath, width: 70, height: 70, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.def.name,
                  style: TextStyle(
                    color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
