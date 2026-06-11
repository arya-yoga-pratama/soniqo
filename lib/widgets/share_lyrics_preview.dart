import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import 'image_helper.dart';

class ShareLyricsPreviewModal extends StatefulWidget {
  final Song song;
  final List<String> selectedLyrics;

  const ShareLyricsPreviewModal({
    super.key,
    required this.song,
    required this.selectedLyrics,
  });

  @override
  State<ShareLyricsPreviewModal> createState() => _ShareLyricsPreviewModalState();
}

class _ShareLyricsPreviewModalState extends State<ShareLyricsPreviewModal> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isRendering = false;
  
  // Customization options
  int _themeIndex = 0;
  final List<List<Color>> _themes = [
    [const Color(0xFF2D1B4E), const Color(0xFF6C3BFF)], // Default Purple
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Deep Space
    [const Color(0xFF141E30), const Color(0xFF243B55)], // Night Sky
    [const Color(0xFF1F1C2C), const Color(0xFF928DAB)], // Greyish
  ];

  Future<Uint8List?> _generatePreviewImage() async {
    // Small delay to ensure the UI is fully painted and any loading state is shown
    await Future.delayed(const Duration(milliseconds: 50));

    final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Could not find boundary');
    }

    // Render the image with higher pixel ratio for better quality
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareAndSaveImage() async {
    if (_isRendering) return;
    setState(() => _isRendering = true);

    try {
      final pngBytes = await _generatePreviewImage();
      if (pngBytes == null) throw Exception('Failed to encode image');

      // Save to Documents/Melodix Shares directory
      final docsDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${docsDir.path}/Melodix Shares');
      
      // Create directory if it doesn't exist
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final safeTitle = widget.song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '${safeTitle}_lyrics_${DateTime.now().millisecondsSinceEpoch}.png';
      String outputFile = '${saveDir.path}/$fileName';
      if (Platform.isWindows) {
        outputFile = outputFile.replaceAll('/', '\\');
      }
      
      final file = File(outputFile);
      
      // Sangat penting di Windows: gunakan flush: true agar file benar-benar selesai ditulis ke disk
      await file.writeAsBytes(pngBytes, flush: true);

      // Delay kecil (300ms) agar Windows melepaskan lock dari file yang baru dibuat
      await Future.delayed(const Duration(milliseconds: 300));

      // Share via share_plus
      await Share.shareXFiles(
        [XFile(outputFile)],
        text: 'Check out these lyrics from ${widget.song.title}!',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to Melodix Shares folder and Share opened'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () {
                if (Platform.isWindows) {
                  Process.run('explorer', [saveDir.path]);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save & share: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  void _cycleTheme() {
    setState(() {
      _themeIndex = (_themeIndex + 1) % _themes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.color_lens_rounded, color: Colors.white70),
                            onPressed: _cycleTheme,
                            tooltip: 'Change Theme',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Cancel',
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Preview Area
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: RepaintBoundary(
                        key: _previewKey,
                        child: AspectRatio(
                          aspectRatio: 2.1, // Ultrawide cinematic landscape ratio (similar to user's red box)
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF080808), // Darker cinematic background
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _themes[_themeIndex].last.withValues(alpha: 0.3), // Thinner premium border
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _themes[_themeIndex].last.withValues(alpha: 0.15), // Soft glow
                                  blurRadius: 40,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Blurred background image (More subtle)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.12,
                                    child: buildCoverImage(widget.song.coverPath ?? '', fit: BoxFit.cover),
                                  ),
                                ),
                                // Glossy dark overlay effect
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.4), // Darker top tint
                                          Colors.black.withValues(alpha: 0.25), // Darker mid tint
                                          Colors.black.withValues(alpha: 0.65), // Very dark bottom tint for footer contrast
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Lyrics (Auto-fit area)
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.topLeft,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: constraints.maxWidth,
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 12.0),
                                                    child: Text(
                                                      '"${widget.selectedLyrics.join('\n')}"',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 26, // Elegant, smaller size
                                                        fontWeight: FontWeight.w600, // Not too heavy
                                                        height: 1.6, // Breathable spacing
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Song Info Row (Fixed Footer)
                                      Row(
                                        children: [
                                          // Album Cover
                                          Container(
                                            width: 40, // Smaller cover
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: buildCoverImage(widget.song.coverPath ?? '', fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Title & Artist
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.song.title,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.9), // Subtler
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  widget.song.artist,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.6), // Subtler
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Small app branding
                                          Icon(Icons.music_note_rounded, color: Colors.white.withValues(alpha: 0.35), size: 20),
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
                    ),
                  ),
                ),

                // Footer Controls
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: _isRendering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.share_rounded),
                      label: Text(
                        _isRendering ? "Preparing..." : "Share to Social Media",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _isRendering ? null : _shareAndSaveImage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
