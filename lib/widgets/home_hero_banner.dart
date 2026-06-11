import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import 'image_helper.dart';

class HeroBannerData {
  final String imagePath;
  final String title;
  final String subtitle;
  final String badgeText;
  final Song? song;

  HeroBannerData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    this.song,
  });
}

/// Full-width hero banner with gradient overlay, badge, title, subtitle,
/// "Listen Now" button, and pagination dots, now with auto-slide functionality.
class HomeHeroBanner extends StatefulWidget {
  final List<Song> allSongs;

  const HomeHeroBanner({super.key, required this.allSongs});

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  List<HeroBannerData> _banners = [];

  @override
  void initState() {
    super.initState();
    _initBanners();
    if (_banners.length > 1) {
      _startTimer();
    }
  }

  void _initBanners() {
    _banners = [];
    
    if (widget.allSongs.isEmpty) {
      _banners.add(HeroBannerData(
        imagePath: 'assets/poster/ForRevenge.jpg',
        title: 'For Revenge',
        subtitle: 'The new album is out now!',
        badgeText: 'NEW RELEASE',
      ));
      return;
    }

    // 1. Get the single newest song for NEW RELEASE
    final recentSongs = List<Song>.from(widget.allSongs)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final newReleaseSong = recentSongs.first;
    
    _banners.add(HeroBannerData(
      imagePath: newReleaseSong.coverPath,
      title: newReleaseSong.artist,
      subtitle: newReleaseSong.title,
      badgeText: 'NEW RELEASE',
      song: newReleaseSong,
    ));

    // 2. Get top 4 trending songs based on playCount
    final trendingSongs = List<Song>.from(widget.allSongs)
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    int addedTrending = 0;
    for (var song in trendingSongs) {
      // Skip the song already featured in NEW RELEASE
      if (song.id == newReleaseSong.id) continue;

      _banners.add(HeroBannerData(
        imagePath: song.coverPath,
        title: song.artist,
        subtitle: song.title,
        badgeText: 'TRENDING',
        song: song,
      ));

      addedTrending++;
      // Limit to maximum 5 slides total (1 new release + 4 trending)
      if (addedTrending >= 4) break;
    }
  }

  @override
  void didUpdateWidget(HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always re-init to capture any playCount changes
    setState(() {
      _initBanners();
      // Ensure we don't go out of bounds if banners length decreased
      if (_currentPage >= _banners.length && _banners.isNotEmpty) {
        _currentPage = _banners.length - 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      }
    });
    
    // Restart timer if necessary
    _timer?.cancel();
    if (_banners.length > 1) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Dummy invisible content to give the banner an intrinsic height
            // This prevents the RenderViewport intrinsic dimensions error
            Opacity(
              opacity: 0.0,
              child: IgnorePointer(
                child: _buildBannerContent(_banners[0]),
              ),
            ),
            
            // PageView for swiping
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return _buildBannerContent(banner);
                },
              ),
            ),
            
            // Pagination dots positioned at the bottom left
            Positioned(
              left: 26,
              bottom: 26,
              child: Row(
                children: List.generate(
                  _banners.length,
                  (i) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuart,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: i == _currentPage ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? const Color(0xFFA54BFF)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerContent(HeroBannerData banner) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: getImageProvider(banner.song?.coverPath ?? banner.imagePath),
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.5),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFA54BFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                banner.badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const Spacer(),

            // Artist / Album title
            Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              banner.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // Listen Now button
            _ListenNowButton(
              song: banner.song,
              allSongs: widget.allSongs,
            ),

            // Space for pagination dots
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
class _ListenNowButton extends StatefulWidget {
  final Song? song;
  final List<Song> allSongs;

  const _ListenNowButton({
    required this.song,
    required this.allSongs,
  });

  @override
  State<_ListenNowButton> createState() => _ListenNowButtonState();
}

class _ListenNowButtonState extends State<_ListenNowButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.song == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          final audioProvider = Provider.of<AudioProvider>(context, listen: false);
          audioProvider.playSong(widget.song!, playlist: widget.allSongs);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFA54BFF),
            borderRadius: BorderRadius.circular(25),
            boxShadow: (_isHovered || _isPressed)
                ? [
                    BoxShadow(
                      color: const Color(0xFFA54BFF).withOpacity(0.6),
                      blurRadius: _isPressed ? 25 : 15,
                      spreadRadius: _isPressed ? 4 : 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Listen Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
