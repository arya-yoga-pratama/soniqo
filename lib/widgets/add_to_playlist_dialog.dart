import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'image_helper.dart';

Future<void> showAddToPlaylistDialog(BuildContext context, Song song) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _AddToPlaylistDialog(song: song),
  );
}

class _AddToPlaylistDialog extends StatefulWidget {
  final Song song;
  const _AddToPlaylistDialog({required this.song});

  @override
  State<_AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<_AddToPlaylistDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final accent = context.watch<ThemeProvider>().accentColor;
    final audioProvider = context.watch<AudioProvider>();
    final playlists = audioProvider.userPlaylists;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.playlist_add_rounded, color: accent, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Add to Playlist', style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: buildCoverImage(widget.song.coverPath, width: 48, height: 48, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.song.title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(widget.song.artist, style: TextStyle(color: theme.textSecondaryColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  if (playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text("You don't have any playlists yet.", style: TextStyle(color: theme.textSecondaryColor, fontSize: 14)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final isInPlaylist = playlist.songIds.contains(widget.song.id);
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                                image: playlist.coverPath != null && playlist.coverPath!.isNotEmpty
                                    ? DecorationImage(image: getImageProvider(playlist.coverPath!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: playlist.coverPath == null || playlist.coverPath!.isEmpty
                                  ? Icon(Icons.queue_music_rounded, color: theme.textSecondaryColor, size: 20)
                                  : null,
                            ),
                            title: Text(playlist.title, style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text('${playlist.songIds.length} songs', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                            trailing: isInPlaylist
                                ? Icon(Icons.check_circle_rounded, color: accent)
                                : Icon(Icons.circle_outlined, color: theme.textSecondaryColor),
                            onTap: () {
                              if (isInPlaylist) {
                                audioProvider.removeSongFromPlaylist(playlist.id, widget.song.id);
                              } else {
                                audioProvider.addSongToPlaylist(playlist.id, widget.song.id);
                              }
                            },
                          );
                        },
                      ),
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
