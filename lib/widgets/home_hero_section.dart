import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../data/songs_data.dart';
import '../models/song.dart';
import 'image_helper.dart';

class HeroItem {
  final String artist;
  final String tagline;
  final String imagePath;
  final String songId;
  final Color accentColor;

  HeroItem({
    required this.artist,
    required this.tagline,
    required this.imagePath,
    required this.songId,
    this.accentColor = const Color(0xFFA54BFF),
  });
}

class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key});

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<HeroItem> _heroItems = [
    HeroItem(
      artist: 'Batas Senja',
      tagline: 'Rumah dan Baju Barumu is out now!',
      imagePath: 'assets/poster/rumahdanbajubarumu.jpg',
      songId: 'bs3',
    ),
    HeroItem(
      artist: 'Pamungkas',
      tagline: 'Kenangan Manis is out now!',
      imagePath: 'assets/poster/OnlyOne.png',
      songId: 'pm4',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Text
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(text: 'Good Evening, '),
              TextSpan(
                text: 'Alex',
                style: TextStyle(color: Color(0xFFA54BFF)),
              ),
              TextSpan(text: ' 👋'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Let's play something you love",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        // Hero Banner Carousel
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _heroItems.length,
                itemBuilder: (context, index) {
                  return _buildHeroBanner(_heroItems[index]);
                },
              ),
              
              // Dots Indicator
              Positioned(
                bottom: 16,
                right: 24,
                child: Row(
                  children: List.generate(
                    _heroItems.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFA54BFF)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(HeroItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: getImageProvider(item.imagePath),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.accentColor.withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    'NEW RELEASE',
                    style: TextStyle(
                      color: Color(0xFFA54BFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.artist,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.tagline,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
                    final song = allSongsData.firstWhere((s) => s.id == item.songId);
                    audioProvider.playSong(song, playlist: allSongsData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: item.accentColor.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Listen Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.play_circle_fill, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

