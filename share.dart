class ShareLyricPreview extends StatefulWidget {
  final SongData song;
  final List<String> selectedLyrics;

  const ShareLyricPreview({
    super.key,
    required this.song,
    required this.selectedLyrics,
  });

  @override
  State<ShareLyricPreview> createState() => _ShareLyricPreviewState();
}

class _ShareLyricPreviewState extends State<ShareLyricPreview> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _captureAndSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Ensure it is painted
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final String downloadDir = r'C:\Users\ADVAN\Downloads\Melodyfy\share';
      final Directory dir = Directory(downloadDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String fileName =
          '${widget.song.title.replaceAll(' ', '_')}_lyrics.png';
      final String outputFile = '$downloadDir\\$fileName';

      final File file = File(outputFile);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(outputFile),
      ], text: 'Check out these lyrics from ${widget.song.title}!');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $downloadDir and Share opened')),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to folder, but Share failed: $e')),
        );
        // Try to open the directory as a fallback
        Process.run('explorer.exe', [
          r'C:\Users\ADVAN\Downloads\Melodyfy\share',
        ]);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141419),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Preview",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // The Aesthetic Card wrapped in RepaintBoundary
            RepaintBoundary(
              key: _globalKey,
              child: ShareLyricCard(
                song: widget.song,
                selectedLyrics: widget.selectedLyrics,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(LucideIcons.share2),
                label: Text(
                  _isSaving ? "Preparing..." : "Share to Social Media",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: _isSaving ? null : _captureAndSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareLyricCard extends StatelessWidget {
  final SongData song;
  final List<String> selectedLyrics;

  const ShareLyricCard({
    super.key,
    required this.song,
    required this.selectedLyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 450,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: getImageProvider(song.coverFile),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dark Gradient / Glass effect overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quotes watermark
            Positioned(
              top: 30,
              left: 20,
              child: Icon(
                LucideIcons.quote,
                size: 60,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Lyrics content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ...selectedLyrics.map(
                    (lyric) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        lyric,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Footer: Song info & Logo
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(
                          image: getImageProvider(song.coverFile),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            LucideIcons.music,
                            color: Color(0xFFFFC107),
                            size: 16,
                          ),
                          Text(
                            "Melodyfy",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ],
                      ),
                    ],
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
