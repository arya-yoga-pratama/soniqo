import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import 'image_helper.dart';
import 'album_detail_view.dart';
import '../utils/formatters.dart';
import '../utils/genre_styles.dart';

class ArtistProfileView extends StatefulWidget {
  final String artistName;
  final List<Song> allSongs;
  final VoidCallback onBack;

  const ArtistProfileView({
    super.key,
    required this.artistName,
    required this.allSongs,
    required this.onBack,
  });

  @override
  State<ArtistProfileView> createState() => _ArtistProfileViewState();
}

class _ArtistProfileViewState extends State<ArtistProfileView> {
  // 0=Overview, 1=Songs, 2=Albums, 3=About
  int _activeTab = 1;
  String? _selectedAlbum;

  static const List<String> _tabs = ['Overview', 'Songs', 'Albums', 'About'];

  @override
  Widget build(BuildContext context) {
    // If an album is selected, show AlbumDetailView inline
    if (_selectedAlbum != null) {
      return AlbumDetailView(
        albumName: _selectedAlbum!,
        allSongs: widget.allSongs,
        onBack: () => setState(() => _selectedAlbum = null),
      );
    }

    final artistSongs = widget.allSongs
        .where((s) => s.artist == widget.artistName)
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final coverPath = artistSongs.isNotEmpty ? artistSongs.first.coverPath : '';

    // Build unique albums for this artist
    final Map<String, _AlbumInfo> albumMap = {};
    for (final s in artistSongs) {
      if (s.album == null || s.album!.isEmpty) continue;
      albumMap.putIfAbsent(s.album!, () => _AlbumInfo(s.album!, s.coverPath, []));
      albumMap[s.album!]!.songs.add(s);
    }
    final albums = albumMap.values.toList();

    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 20, bottom: 24),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onBack,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text('Artist', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Artist Profile Header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
                        ],
                      ),
                      child: ClipOval(child: buildCoverImage(coverPath, fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ARTIST', style: TextStyle(color: Color(0xFFA54BFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          const SizedBox(height: 6),
                          Text(widget.artistName, style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1)),
                          const SizedBox(height: 8),
                          Text(
                            '${artistSongs.length} song${artistSongs.length != 1 ? 's' : ''} · ${albums.length} album${albums.length != 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _ArtistPlayButton(
                                isPlaying: audio.isPlaying && artistSongs.any((s) => s.id == audio.currentSong?.id),
                                onPressed: () {
                                  if (artistSongs.isNotEmpty) {
                                    final isFromThisArtist = artistSongs.any((s) => s.id == audio.currentSong?.id);
                                    if (isFromThisArtist) {
                                      audio.togglePlayPause();
                                    } else {
                                      audio.playSong(artistSongs.first, playlist: artistSongs);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 14),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('Follow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.more_horiz_rounded),
                                color: Colors.white.withValues(alpha: 0.6),
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

              // ── Navigation Tabs ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: _tabs.asMap().entries.map((e) {
                        final i = e.key;
                        final label = e.value;
                        return Padding(
                          padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 32 : 0),
                          child: _TabItem(
                            title: label,
                            isActive: _activeTab == i,
                            onTap: () => setState(() => _activeTab = i),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 1),
                    Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.05)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ── Tab Content ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _buildTabContent(artistSongs, albums, coverPath, audio),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(List<Song> artistSongs, List<_AlbumInfo> albums, String coverPath, AudioProvider audio) {
    switch (_activeTab) {
      case 2: // Albums
        return _AlbumsTabContent(
          albums: albums,
          onAlbumTap: (albumName) => setState(() => _selectedAlbum = albumName),
        );
      case 3: // About
        return _AboutArtistSection(
          artistName: widget.artistName,
          coverPath: coverPath,
          genres: artistSongs.map((s) => s.genre).whereType<String>().where((g) => g.isNotEmpty).toSet().toList(),
        );
      case 0: // Overview — show both popular songs + albums preview
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 60, child: _PopularSongsSection(artistSongs: artistSongs, audio: audio)),
            const SizedBox(width: 60),
            Expanded(
              flex: 40,
              child: _AboutArtistSection(
                artistName: widget.artistName,
                coverPath: coverPath,
                genres: artistSongs.map((s) => s.genre).whereType<String>().where((g) => g.isNotEmpty).toSet().toList(),
              ),
            ),
          ],
        );
      case 1: // Songs (default)
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 60, child: _PopularSongsSection(artistSongs: artistSongs, audio: audio)),
            const SizedBox(width: 60),
            Expanded(
              flex: 40,
              child: _AboutArtistSection(
                artistName: widget.artistName,
                coverPath: coverPath,
                genres: artistSongs.map((s) => s.genre).whereType<String>().where((g) => g.isNotEmpty).toSet().toList(),
              ),
            ),
          ],
        );
    }
  }
}

// ── Album info holder ─────────────────────────────────────────────────────────
class _AlbumInfo {
  final String name;
  final String coverPath;
  final List<Song> songs;
  _AlbumInfo(this.name, this.coverPath, this.songs);
}

// ── Albums Tab ────────────────────────────────────────────────────────────────
class _AlbumsTabContent extends StatelessWidget {
  final List<_AlbumInfo> albums;
  final void Function(String albumName) onAlbumTap;

  const _AlbumsTabContent({required this.albums, required this.onAlbumTap});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.album_rounded, color: Colors.white.withValues(alpha: 0.1), size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'No Albums Available',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Add songs with album info via Add Song to see albums here.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 28,
      runSpacing: 28,
      children: albums.map((a) => _AlbumCard(album: a, onTap: () => onAlbumTap(a.name))).toList(),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final _AlbumInfo album;
  final VoidCallback onTap;
  const _AlbumCard({required this.album, required this.onTap});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _hovered
                            ? const Color(0xFFA54BFF).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: _hovered ? 20 : 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        buildCoverImage(widget.album.coverPath, fit: BoxFit.cover),
                        if (_hovered)
                          Container(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: const Center(
                              child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 44),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.album.name,
                  style: TextStyle(
                    color: _hovered ? const Color(0xFFA54BFF) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.album.songs.length} song${widget.album.songs.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab item ──────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 30 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFA54BFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFFA54BFF).withValues(alpha: 0.5), blurRadius: 6)]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popular Songs Section ─────────────────────────────────────────────────────
class _PopularSongsSection extends StatelessWidget {
  final List<Song> artistSongs;
  final AudioProvider audio;

  const _PopularSongsSection({required this.artistSongs, required this.audio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artistSongs.length,
          itemBuilder: (context, index) {
            final song = artistSongs[index];
            final isActive = audio.currentSong?.id == song.id;
            final playCount = song.playCount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            );
            return _PopularSongTile(
              song: song,
              index: index + 1,
              playCount: playCount,
              isActive: isActive,
              onTap: () => audio.playSong(song, playlist: artistSongs),
            );
          },
        ),
        const SizedBox(height: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {},
            child: const Text('See all', style: TextStyle(color: Color(0xFFA54BFF), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _PopularSongTile extends StatefulWidget {
  final Song song;
  final int index;
  final String playCount;
  final bool isActive;
  final VoidCallback onTap;

  const _PopularSongTile({
    required this.song,
    required this.index,
    required this.playCount,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PopularSongTile> createState() => _PopularSongTileState();
}

class _PopularSongTileState extends State<_PopularSongTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: widget.isActive
                    ? const Icon(Icons.bar_chart_rounded, color: Color(0xFFA54BFF), size: 16)
                    : Text('${widget.index}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: buildCoverImage(widget.song.coverPath, width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Text(
                  widget.song.title,
                  style: TextStyle(color: widget.isActive ? const Color(0xFFA54BFF) : Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(widget.playCount, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13), textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 60,
                child: Text(formatDuration(widget.song.duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13), textAlign: TextAlign.right),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 30,
                child: Icon(Icons.more_horiz_rounded, color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.0), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── About Artist Section ──────────────────────────────────────────────────────
class _AboutArtistSection extends StatelessWidget {
  final String artistName;
  final String coverPath;
  final List<String> genres;

  const _AboutArtistSection({required this.artistName, required this.coverPath, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About $artistName', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 20),
        Text(
          '$artistName adalah musisi yang dikenal dengan karya-karya berkualitas tinggi.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 24),
        const Text('Genre', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.isEmpty
              ? [Text('No genre specified', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontStyle: FontStyle.italic))]
              : genres.map((genre) {
                  final style = getGenreStyle(genre);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(genre, style: TextStyle(color: style.color, fontSize: 11, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            5,
            (i) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D0D0D), width: 2)),
              child: ClipOval(child: buildCoverImage(coverPath, fit: BoxFit.cover)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {},
            child: const Text('See more', style: TextStyle(color: Color(0xFFA54BFF), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ── Artist Play Button ────────────────────────────────────────────────────────
class _ArtistPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  const _ArtistPlayButton({required this.isPlaying, required this.onPressed});

  @override
  State<_ArtistPlayButton> createState() => _ArtistPlayButtonState();
}

class _ArtistPlayButtonState extends State<_ArtistPlayButton> {
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
            boxShadow: [BoxShadow(color: const Color(0xFFA54BFF).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(widget.isPlaying ? 'Pause' : 'Play', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
