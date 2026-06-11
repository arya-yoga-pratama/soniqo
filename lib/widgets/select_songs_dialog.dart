import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/user_playlist.dart';
import '../providers/audio_provider.dart';
import '../data/songs_data.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'image_helper.dart';

Future<void> showSelectSongsDialog(BuildContext context, UserPlaylist playlist) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    barrierDismissible: false,
    builder: (_) => _SelectSongsDialog(playlist: playlist),
  );
}

class _SelectSongsDialog extends StatefulWidget {
  final UserPlaylist playlist;
  const _SelectSongsDialog({required this.playlist});

  @override
  State<_SelectSongsDialog> createState() => _SelectSongsDialogState();
}

class _SelectSongsDialogState extends State<_SelectSongsDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  
  final _searchController = TextEditingController();
  List<Song> _filteredSongs = [];
  final Set<String> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _filteredSongs = List.from(allSongsData);
    // Pre-select songs already in the playlist
    _selectedSongIds.addAll(widget.playlist.songIds);
    
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
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = List.from(allSongsData);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredSongs = allSongsData.where((song) {
          return song.title.toLowerCase().contains(lowerQuery) ||
                 song.artist.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _save() {
    final newSongIds = _selectedSongIds.where((id) => !widget.playlist.songIds.contains(id)).toList();
    if (newSongIds.isNotEmpty) {
      context.read<AudioProvider>().addSongsToPlaylist(widget.playlist.id, newSongIds);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final accent = context.watch<ThemeProvider>().accentColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.library_music_rounded, color: accent, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Songs', style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                              Text('to "${widget.playlist.title}"', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: theme.textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search songs or artists...',
                        hintStyle: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.search_rounded, color: theme.textSecondaryColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  Flexible(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        final isSelected = _selectedSongIds.contains(song.id);
                        final isAlreadyInPlaylist = widget.playlist.songIds.contains(song.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: buildCoverImage(song.coverPath, width: 48, height: 48, fit: BoxFit.cover),
                          ),
                          title: Text(song.title, style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist, style: TextStyle(color: theme.textSecondaryColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: isAlreadyInPlaylist
                              ? Text('Added', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold))
                              : Checkbox(
                                  value: isSelected,
                                  activeColor: accent,
                                  checkColor: Colors.white,
                                  side: BorderSide(color: theme.textSecondaryColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedSongIds.add(song.id);
                                      } else {
                                        _selectedSongIds.remove(song.id);
                                      }
                                    });
                                  },
                                ),
                          onTap: isAlreadyInPlaylist ? null : () {
                            setState(() {
                              if (isSelected) {
                                _selectedSongIds.remove(song.id);
                              } else {
                                _selectedSongIds.add(song.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_selectedSongIds.difference(widget.playlist.songIds.toSet()).isEmpty ? 'Done' : 'Add Selected', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ],
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
