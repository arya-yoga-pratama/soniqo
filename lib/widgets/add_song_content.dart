import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../utils/genre_styles.dart';

class AddSongContent extends StatefulWidget {
  final VoidCallback onBack;
  const AddSongContent({super.key, required this.onBack});

  @override
  State<AddSongContent> createState() => _AddSongContentState();
}

class _AddSongContentState extends State<AddSongContent> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _trackController = TextEditingController();
  final _lyricsController = TextEditingController();

  // Selected file paths
  String? _audioFilePath;
  String? _audioFileName;
  String? _coverImagePath;
  String? _coverImageName;
  String? _lyricsFilePath;
  String? _lyricsFileName;

  bool _isAdding = false;
  int _lyricsCharCount = 0;

  final List<String> _genres = [
    'Pop', 'Rock', 'Jazz', 'Hip Hop', 'R&B', 'Electronic', 'Classical',
    'Country', 'K-Pop', 'Indie', 'Metal', 'Lo-fi', 'Acoustic', 'Blues', 'Soul'
  ];

  void _showGenrePicker() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filteredGenres = _genres.where((g) => g.toLowerCase().contains(query)).toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 400,
              height: 520,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.borderColor.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Genre',
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor, size: 20),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.borderColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: theme.textSecondaryColor.withOpacity(0.5), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  onChanged: (_) => setModalState(() {}),
                                  style: TextStyle(color: theme.textColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search genres...',
                                    hintStyle: TextStyle(color: theme.textSecondaryColor.withOpacity(0.3), fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Genre List
                  Expanded(
                    child: filteredGenres.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, color: theme.borderColor, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'No genres found',
                                  style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredGenres.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final g = filteredGenres[index];
                              final isSelected = _genreController.text == g;
                              final style = getGenreStyle(g);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _genreController.text = g);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  hoverColor: style.color.withOpacity(0.08),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: isSelected ? style.color.withOpacity(0.12) : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? style.color.withOpacity(0.25)
                                                : style.color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: isSelected 
                                                ? Border.all(color: style.color.withOpacity(0.4), width: 1.5)
                                                : null,
                                          ),
                                          child: Icon(
                                            isSelected ? Icons.check_rounded : style.icon,
                                            color: isSelected ? style.color : style.color.withOpacity(0.6),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          g,
                                          style: TextStyle(
                                            color: isSelected ? style.color : theme.textColor,
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isSelected)
                                          Icon(Icons.radio_button_checked_rounded, color: style.color, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateUI);
    _artistController.addListener(_updateUI);
    _genreController.addListener(_updateUI);
    _lyricsController.addListener(_onLyricsChanged);
  }

  void _updateUI() => setState(() {});

  void _onLyricsChanged() {
    setState(() {
      _lyricsCharCount = _lyricsController.text.length;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _pickMusicFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFilePath = result.files.single.path;
        _audioFileName = result.files.single.name;
        // Auto-fill title from filename if empty
        if (_titleController.text.isEmpty) {
          final nameWithoutExt = _audioFileName!.replaceAll(RegExp(r'\.[^\.]+$'), '');
          _titleController.text = nameWithoutExt;
        }
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverImagePath = result.files.single.path;
        _coverImageName = result.files.single.name;
      });
    }
  }

  Future<void> _pickLyricsFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc', 'txt'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _lyricsFilePath = result.files.single.path;
        _lyricsFileName = result.files.single.name;
      });
      // Optionally auto-detect if the text area is empty
      if (_lyricsController.text.isEmpty) {
        _autoDetectLyrics();
      }
    }
  }

  Future<void> _autoDetectLyrics() async {
    if (_lyricsFilePath == null) {
      _showSnackBar('No lyrics file selected', isError: true);
      return;
    }

    try {
      final file = File(_lyricsFilePath!);
      final content = await file.readAsString();
      setState(() {
        _lyricsController.text = content;
      });
      _showSnackBar('Lyrics detected and loaded!');
    } catch (e) {
      _showSnackBar('Failed to read lyrics file: $e', isError: true);
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _artistController.clear();
      _albumController.clear();
      _genreController.clear();
      _yearController.clear();
      _trackController.clear();
      _lyricsController.clear();
      _audioFilePath = null;
      _audioFileName = null;
      _coverImagePath = null;
      _coverImageName = null;
      _lyricsFilePath = null;
      _lyricsFileName = null;
    });
  }

  Future<void> _addToLibrary() async {
    // Validate required fields
    if (_audioFilePath == null) {
      _showSnackBar('Please select a music file (MP3)', isError: true);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a song title', isError: true);
      return;
    }
    if (_artistController.text.trim().isEmpty) {
      _showSnackBar('Please enter an artist name', isError: true);
      return;
    }

    setState(() => _isAdding = true);

    try {
      // 1. Define target directories
      const musicDirPath = 'D:/Soniqo/assets/musik';
      const posterDirPath = 'D:/Soniqo/assets/poster';
      const lyricsDirPath = 'D:/Soniqo/assets/lyrics';

      // 2. Ensure directories exist
      for (var pathStr in [musicDirPath, posterDirPath, lyricsDirPath]) {
        final dir = Directory(pathStr);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }

      // 3. Prepare file names and target paths
      final title = _titleController.text.trim();
      final artist = _artistController.text.trim();
      final formattedFileName = "$artist - $title";
      final targetAudioPath = p.join(musicDirPath, "$formattedFileName.mp3");
      final baseNameNoExt = formattedFileName;

      final audioFile = File(_audioFilePath!);

      // 4. Copy Audio File
      if (p.normalize(audioFile.path) != p.normalize(targetAudioPath)) {
        await audioFile.copy(targetAudioPath);
      }

      // 5. Copy Cover Image (if selected)
      String? targetCoverPath;
      if (_coverImagePath != null) {
        final coverFile = File(_coverImagePath!);
        final coverExt = p.extension(coverFile.path);
        final targetCoverFileName = '$baseNameNoExt$coverExt';
        targetCoverPath = p.join(posterDirPath, targetCoverFileName);
        
        if (p.normalize(coverFile.path) != p.normalize(targetCoverPath)) {
          await coverFile.copy(targetCoverPath);
        }
      } else {
        targetCoverPath = 'assets/poster/default.jpg';
      }

      // 6. Save Lyrics (if provided or picked)
      String? targetLyricsPath;
      if (_lyricsController.text.isNotEmpty) {
        final lyricsFileName = '$baseNameNoExt.lrc';
        targetLyricsPath = p.join(lyricsDirPath, lyricsFileName);
        await File(targetLyricsPath).writeAsString(_lyricsController.text);
      } else if (_lyricsFilePath != null) {
        final lyricsFile = File(_lyricsFilePath!);
        final lyricsFileName = '$baseNameNoExt.lrc';
        targetLyricsPath = p.join(lyricsDirPath, lyricsFileName);
        
        if (p.normalize(lyricsFile.path) != p.normalize(targetLyricsPath)) {
          await lyricsFile.copy(targetLyricsPath);
        }
      }

      // 7. Create Song object with final persistent paths
      final song = Song(
        id: targetAudioPath,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim().isEmpty ? null : _albumController.text.trim(),
        audioPath: targetAudioPath,
        coverPath: targetCoverPath,
        genre: _genreController.text.trim(),
        lyricsPath: targetLyricsPath,
      );

      if (mounted) {
        final provider = Provider.of<AudioProvider>(context, listen: false);
        provider.addSongToLibrary(song);
        _showSnackBar('"${song.title}" saved and added to library!');
        _resetForm();
      }
    } catch (e) {
      _showSnackBar('Failed to save song: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFFA54BFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add Song',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.music_note_rounded, color: Color(0xFFA54BFF), size: 24),
                        ],
                      ),
                      Text(
                        'Upload your music and complete the details',
                        style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Main Content Body (Scrollable) ────────────────────
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Left Column: Upload & Info ──
                        Expanded(
                          flex: 55,
                          child: _SectionCard(
                            theme: theme,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(title: 'Upload Files', theme: theme),
                                const SizedBox(height: 20),
                                _UploadTile(
                                  label: 'Music File (MP3)',
                                  icon: Icons.audiotrack_rounded,
                                  iconLabel: 'MP3',
                                  hint: _audioFileName ?? 'Click to upload',
                                  subHint: _audioFilePath != null
                                      ? '✓ File selected'
                                      : 'Only MP3 files • Max 50MB',
                                  isSelected: _audioFilePath != null,
                                  onTap: _pickMusicFile,
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                                _UploadTile(
                                  label: 'Cover Image',
                                  icon: Icons.image_rounded,
                                  iconLabel: '',
                                  hint: _coverImageName ?? 'Click to upload',
                                  subHint: _coverImagePath != null
                                      ? '✓ Image selected'
                                      : 'JPG, PNG • Square image • Max 5MB',
                                  isSelected: _coverImagePath != null,
                                  onTap: _pickCoverImage,
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                                _UploadTile(
                                  label: 'Lyrics File (Optional)',
                                  icon: Icons.description_rounded,
                                  iconLabel: 'LRC',
                                  hint: _lyricsFileName ?? 'Upload .lrc or .txt file',
                                  subHint: _lyricsFilePath != null
                                      ? '✓ Lyrics selected'
                                      : 'Optional • Max 1MB',
                                  isSelected: _lyricsFilePath != null,
                                  onTap: _pickLyricsFile,
                                  theme: theme,
                                ),

                                const SizedBox(height: 32),

                                _SectionTitle(title: 'Song Information', theme: theme),
                                const SizedBox(height: 20),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.8,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 16,
                                  children: [
                                    _InputField(label: 'Song Title', hint: 'Enter song title', controller: _titleController, required: true, theme: theme),
                                    _InputField(label: 'Artist', hint: 'Enter artist name', controller: _artistController, required: true, theme: theme),
                                    _InputField(label: 'Album', hint: 'Enter album name', controller: _albumController, theme: theme),
                                    _InputField(
                                      label: 'Genre', 
                                      hint: 'Select genre', 
                                      controller: _genreController, 
                                      required: true, 
                                      isDropdown: true, 
                                      onTap: _showGenrePicker,
                                      theme: theme
                                    ),
                                    _InputField(label: 'Year', hint: 'e.g. 2024', controller: _yearController, isDate: true, theme: theme),
                                    _InputField(label: 'Track Number (Optional)', hint: 'e.g. 1', controller: _trackController, theme: theme),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // ── Right Column: Preview & Lyrics ──
                        Expanded(
                          flex: 45,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionCard(
                                theme: theme,
                                child: _PreviewSection(
                                  title: _titleController.text.isEmpty ? 'Song Title' : _titleController.text,
                                  artist: _artistController.text.isEmpty ? 'Artist Name' : _artistController.text,
                                  genre: _genreController.text.isEmpty ? 'Genre' : _genreController.text,
                                  genreStyle: getGenreStyle(_genreController.text),
                                  coverImagePath: _coverImagePath,
                                  theme: theme,
                                ),
                              ),

                              const SizedBox(height: 24),

                              _SectionCard(
                                theme: theme,
                                child: _LyricsSection(
                                  controller: _lyricsController, 
                                  charCount: _lyricsCharCount,
                                  onAutoDetect: _autoDetectLyrics,
                                  theme: theme,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Footer Buttons ──
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _ActionButton(
                                      label: 'Reset',
                                      icon: Icons.refresh_rounded,
                                      onTap: _resetForm,
                                      isPrimary: false,
                                      theme: theme,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 7,
                                    child: _ActionButton(
                                      label: _isAdding ? 'Adding...' : 'Add to Library',
                                      icon: _isAdding ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded,
                                      onTap: _isAdding ? () {} : _addToLibrary,
                                      isPrimary: true,
                                      theme: theme,
                                    ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final AppThemeExtension theme;
  const _SectionCard({required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderColor.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppThemeExtension theme;
  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _UploadTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final String iconLabel;
  final String hint;
  final String subHint;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeExtension theme;

  const _UploadTile({
    required this.label,
    required this.icon,
    required this.iconLabel,
    required this.hint,
    required this.subHint,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFA54BFF);
    final color = widget.isSelected ? accent : accent;

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            widget.label,
            style: TextStyle(color: widget.theme.textSecondaryColor, fontSize: 13),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withOpacity(0.2)
                : accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? accent : accent.withOpacity(0.2),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.isSelected ? Icons.check_circle_rounded : widget.icon,
                color: color,
                size: 28,
              ),
              if (widget.iconLabel.isNotEmpty && !widget.isSelected)
                Positioned(
                  bottom: 8,
                  child: Text(
                    widget.iconLabel,
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _hovered
                      ? accent.withOpacity(0.06)
                      : (widget.isSelected ? accent.withOpacity(0.04) : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? accent.withOpacity(0.4)
                        : (_hovered ? accent.withOpacity(0.3) : widget.theme.textColor.withOpacity(0.1)),
                    width: 1.5,
                    style: widget.isSelected ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected ? Icons.insert_drive_file_rounded : Icons.cloud_upload_outlined,
                      color: widget.isSelected ? accent : widget.theme.textSecondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hint,
                            style: TextStyle(
                              color: widget.isSelected ? accent : widget.theme.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.subHint,
                            style: TextStyle(
                              color: widget.isSelected
                                  ? accent.withOpacity(0.7)
                                  : widget.theme.textSecondaryColor,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool required;
  final bool isDropdown;
  final bool isDate;
  final VoidCallback? onTap;
  final AppThemeExtension theme;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.required = false,
    this.isDropdown = false,
    this.isDate = false,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: (isDropdown || isDate) ? SystemMouseCursors.click : SystemMouseCursors.text,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      readOnly: isDropdown || isDate,
                      enabled: !(isDropdown || isDate), // Disable text input for non-text fields
                      style: TextStyle(color: theme.textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(color: theme.textSecondaryColor.withOpacity(0.4), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onTap: onTap,
                    ),
                  ),
                  if (isDropdown)
                    Icon(Icons.keyboard_arrow_down_rounded, color: theme.textSecondaryColor, size: 20),
                  if (isDate)
                    Icon(Icons.calendar_month_outlined, color: theme.textSecondaryColor, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final String artist;
  final String genre;
  final GenreStyle genreStyle;
  final String? coverImagePath;
  final AppThemeExtension theme;

  const _PreviewSection({
    required this.title,
    required this.artist,
    required this.genre,
    required this.genreStyle,
    this.coverImagePath,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Preview', theme: theme),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              // Cover art preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: coverImagePath != null
                    ? Image.file(
                        File(coverImagePath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultCover(),
                      )
                    : _defaultCover(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: genreStyle.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(genreStyle.icon, size: 10, color: genreStyle.color),
                          const SizedBox(width: 6),
                          Text(
                            genre.isEmpty ? 'Genre' : genre,
                            style: TextStyle(color: genreStyle.color, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: theme.textSecondaryColor, size: 14),
                        const SizedBox(width: 6),
                        Text('00:00', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaultCover() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.music_note_rounded, color: Color(0xFFA54BFF), size: 48),
    );
  }
}

class _LyricsSection extends StatelessWidget {
  final TextEditingController controller;
  final int charCount;
  final VoidCallback onAutoDetect;
  final AppThemeExtension theme;

  const _LyricsSection({
    required this.controller, 
    required this.charCount,
    required this.onAutoDetect,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(title: 'Lyrics (Optional)', theme: theme),
            TextButton.icon(
              onPressed: onAutoDetect,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: const Text('Auto-detect from file', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFA54BFF)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a lyrics file or paste lyrics below',
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                maxLines: null,
                style: TextStyle(color: theme.textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter lyrics here or upload a file...',
                  hintStyle: TextStyle(color: theme.textSecondaryColor.withOpacity(0.3), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Text(
                  '$charCount / 5000',
                  style: TextStyle(color: theme.textSecondaryColor.withOpacity(0.5), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final AppThemeExtension theme;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFA54BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPrimary ? Colors.transparent : theme.borderColor),
          boxShadow: isPrimary
              ? [BoxShadow(color: const Color(0xFFA54BFF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : theme.textColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: isPrimary ? Colors.white : theme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final rRect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(12));
    final path = Path()..addRRect(rRect);

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(metric.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
