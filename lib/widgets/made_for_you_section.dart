import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'image_helper.dart';

/// "Made For You" horizontal playlist card strip.
/// Cards show a colored accent header, playlist title and description text.
/// Uses existing songs to derive playlist names — no fake unrelated data.
class MadeForYouSection extends StatelessWidget {
  final List<Song> songs;
  final Function(Playlist) onPlaylistTap;

  const MadeForYouSection({
    super.key, 
    required this.songs,
    required this.onPlaylistTap,
  });

  // Build playlist definitions from existing song data
  List<Playlist> _buildPlaylists() {
    // Group by artist
    final artistGroups = <String, List<Song>>{};
    for (final s in songs) {
      artistGroups.putIfAbsent(s.artist, () => []).add(s);
    }

    const gradients = [
      [Color(0xFF7C3AED), Color(0xFFA54BFF)],
      [Color(0xFF1E5799), Color(0xFF2989D8)],
      [Color(0xFF1B6E2E), Color(0xFF3BAF55)],
      [Color(0xFF8B2500), Color(0xFFD44F00)],
      [Color(0xFF7B1063), Color(0xFFBE2F9A)],
    ];

    final playlists = <Playlist>[];
    
    // Helper to find songs by artist (case-insensitive and space-flexible)
    List<Song> findByArtist(String name) {
      final normalized = name.toLowerCase().replaceAll(' ', '');
      for (final artist in artistGroups.keys) {
        if (artist.toLowerCase().replaceAll(' ', '') == normalized) {
          return artistGroups[artist]!;
        }
      }
      return [];
    }

    // 1. Try to get the specific requested mixes
    final raimSongs = findByArtist('Raim Laode');
    final justinSongs = findByArtist('Justin Bieber');
    final forRevengeSongs = findByArtist('For Revenge');

    if (raimSongs.isNotEmpty) {
      playlists.add(Playlist(
        id: 'mix_raim_laode',
        title: '${raimSongs.first.artist} Mix',
        description: 'A mix of your favourite tracks from ${raimSongs.first.artist}.',
        coverPath: raimSongs.first.coverPath,
        gradientColors: gradients[0],
        songs: raimSongs,
      ));
    }

    if (justinSongs.isNotEmpty) {
      playlists.add(Playlist(
        id: 'hits_justin_bieber',
        title: '${justinSongs.first.artist} Hits',
        description: 'Best of ${justinSongs.first.artist}',
        coverPath: justinSongs.last.coverPath,
        gradientColors: gradients[1],
        songs: justinSongs,
      ));
    }

    if (forRevengeSongs.isNotEmpty) {
      playlists.add(Playlist(
        id: 'mix_for_revenge',
        title: '${forRevengeSongs.first.artist} Mix',
        description: '${forRevengeSongs.length} tracks · ${forRevengeSongs.first.artist}',
        coverPath: forRevengeSongs.first.coverPath,
        gradientColors: gradients[2],
        songs: forRevengeSongs,
      ));
    }

    // 2. If we still have fewer than 3 playlists, add other artists found
    if (playlists.length < 3) {
      final otherArtists = artistGroups.keys.where((a) {
        final norm = a.toLowerCase().replaceAll(' ', '');
        return norm != 'raimlaode' && norm != 'justinbieber' && norm != 'forrevenge';
      }).toList();

      for (final artist in otherArtists) {
        if (playlists.length >= 4) break;
        final artistSongs = artistGroups[artist]!;
        playlists.add(Playlist(
          id: 'mix_${artist.toLowerCase().replaceAll(' ', '_')}',
          title: '$artist Mix',
          description: 'Personalized mix with $artist',
          coverPath: artistSongs.first.coverPath,
          gradientColors: gradients[playlists.length % gradients.length],
          songs: artistSongs,
        ));
      }
    }

    // 3. For Mix (Blend of all songs)
    if (songs.isNotEmpty) {
      final blendSongs = List<Song>.from(songs)..shuffle();
      final finalBlend = blendSongs.take(10).toList();
      playlists.add(Playlist(
        id: 'mix_for_blend',
        title: 'For Mix',
        description: 'Personalized blend for you',
        coverPath: songs.first.coverPath,
        gradientColors: gradients[3],
        songs: finalBlend,
      ));
    }

    return playlists;
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _buildPlaylists();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        const Text(
          'Made For You',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Playlists based on your listening',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        // ── Horizontal List ──────────────────────────────────────────────────
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: i == playlists.length - 1 ? 0 : 12),
              child: _PlaylistCard(
                playlist: playlists[i],
                onTap: () => onPlaylistTap(playlists[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  
  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
  });

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
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
          duration: const Duration(milliseconds: 170),
          width: 148,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF242424)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFFA54BFF).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored gradient header with cover
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: Stack(
                  children: [
                    buildCoverImage(
                      widget.playlist.coverPath,
                      width: 148,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: 148,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.playlist.gradientColors[0].withValues(alpha: 0.75),
                            widget.playlist.gradientColors[1].withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    // Music note icon
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Icon(
                        Icons.library_music_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ),
                    // Play button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA54BFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.playlist.songs.length} tracks · ${widget.playlist.songs.first.artist}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

