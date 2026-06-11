import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/user_playlist.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import 'image_helper.dart';
import 'select_songs_dialog.dart';

class UserPlaylistDetailView extends StatefulWidget {
  final UserPlaylist playlist;
  final List<Song> allSongs;
  final VoidCallback onBack;

  const UserPlaylistDetailView({
    super.key,
    required this.playlist,
    required this.allSongs,
    required this.onBack,
  });

  @override
  State<UserPlaylistDetailView> createState() => _UserPlaylistDetailViewState();
}

class _UserPlaylistDetailViewState extends State<UserPlaylistDetailView> {
  late List<Song> _playlistSongs;

  @override
  void initState() {
    super.initState();
    _updateSongs();
  }

  @override
  void didUpdateWidget(UserPlaylistDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlist != oldWidget.playlist) {
      _updateSongs();
    }
  }

  void _updateSongs() {
    _playlistSongs = widget.playlist.songIds
        .map((id) {
          try {
            return widget.allSongs.firstWhere((s) => s.id == id);
          } catch (e) {
            return null;
          }
        })
        .where((s) => s != null)
        .cast<Song>()
        .toList();
  }

  void _playAll() {
    if (_playlistSongs.isNotEmpty) {
      context.read<AudioProvider>().playSong(_playlistSongs.first, playlist: _playlistSongs);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${widget.playlist.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AudioProvider>().deleteUserPlaylist(widget.playlist.id);
              Navigator.of(ctx).pop();
              widget.onBack();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.playlist.title);
    final descController = TextEditingController(text: widget.playlist.description);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Edit Playlist', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                context.read<AudioProvider>().updateUserPlaylist(
                  widget.playlist.id,
                  titleController.text.trim(),
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                );
                // Force a rebuild to reflect changes (the object is mutated in AudioProvider)
                setState(() {});
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final audioProvider = context.watch<AudioProvider>();

    String? displayCover = widget.playlist.coverPath;
    if ((displayCover == null || displayCover.isEmpty) && _playlistSongs.isNotEmpty) {
      displayCover = _playlistSongs.first.coverPath;
    }

    return Container(
      color: theme.backgroundColor,
      child: CustomScrollView(
        slivers: [
          // ── Back Button ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 32, top: 24, bottom: 8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Library',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: displayCover != null && displayCover.isNotEmpty
                          ? DecorationImage(
                              image: getImageProvider(displayCover),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: displayCover == null || displayCover.isEmpty
                        ? Center(child: Icon(Icons.queue_music_rounded, size: 64, color: theme.textSecondaryColor))
                        : null,
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYLIST', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          widget.playlist.title,
                          style: TextStyle(color: theme.textColor, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                        ),
                        if (widget.playlist.description != null && widget.playlist.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(widget.playlist.description!, style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Soniqo', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: theme.textSecondaryColor)),
                            const SizedBox(width: 8),
                            Text('${_playlistSongs.length} songs', style: TextStyle(color: theme.textSecondaryColor)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _playAll,
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              label: const Text('Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: theme.textSecondaryColor),
                              tooltip: 'Add Songs',
                              onPressed: () => showSelectSongsDialog(context, widget.playlist),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.edit_rounded, color: theme.textSecondaryColor),
                              tooltip: 'Edit Playlist',
                              onPressed: _showEditDialog,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: theme.textSecondaryColor),
                              tooltip: 'Delete Playlist',
                              onPressed: _confirmDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: _buildTableHeader(theme),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Divider(color: theme.borderColor, height: 1),
            ),
          ),
          if (_playlistSongs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(64.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.music_note_rounded, size: 48, color: theme.textSecondaryColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No songs added yet', style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Go to your songs to add them here', style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => showSelectSongsDialog(context, widget.playlist),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Add Songs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _playlistSongs[index];
                    return _buildSongRow(context, index + 1, song, audioProvider, theme);
                  },
                  childCount: _playlistSongs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('#', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
          Expanded(flex: 4, child: Text('TITLE', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
          Expanded(flex: 3, child: Text('ALBUM', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
          SizedBox(width: 120, child: Text('DATE ADDED', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12))),
          SizedBox(width: 60, child: Icon(Icons.access_time, color: theme.textSecondaryColor, size: 16)),
          const SizedBox(width: 40), // For remove button
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, int rank, Song song, AudioProvider audioProvider, AppThemeExtension theme) {
    final isPlaying = audioProvider.currentSong?.id == song.id;

    return InkWell(
      onTap: () {
        if (isPlaying) {
          audioProvider.togglePlayPause();
        } else {
          audioProvider.playSong(song, playlist: _playlistSongs);
        }
      },
      borderRadius: BorderRadius.circular(8),
      hoverColor: theme.borderColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isPlaying ? theme.borderColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Center(
                child: isPlaying
                    ? Icon(Icons.equalizer_rounded, color: theme.accentColor, size: 16)
                    : Text('$rank', style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: buildCoverImage(song.coverPath, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, style: TextStyle(color: isPlaying ? theme.accentColor : theme.textColor, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(song.artist, style: TextStyle(color: theme.textSecondaryColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(song.album ?? '—', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 120,
              child: Text('${song.addedAt.day}/${song.addedAt.month}/${song.addedAt.year}', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
            ),
            SizedBox(
              width: 60,
              child: Text('${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
            ),
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: theme.textSecondaryColor),
                color: theme.surfaceColor,
                onSelected: (value) {
                  if (value == 'remove') {
                    audioProvider.removeSongFromPlaylist(widget.playlist.id, song.id);
                    setState(() {
                      _updateSongs();
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text('Remove from Playlist', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
