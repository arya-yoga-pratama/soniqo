import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/audio_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/equalizer_provider.dart';
import 'screens/home_screen.dart';
import 'data/songs_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // Required for media_kit video background

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initializeTheme();

  // Initialize audio provider
  final audioProvider = AudioProvider();

  // Initialize equalizer provider
  final equalizerProvider = EqualizerProvider();
  await equalizerProvider.load();
  
  // Scan songs from local directory
  final songs = await scanSongs();
  
  // Load persistent favourites
  await audioProvider.loadFavourites();
  
  // Load persistent play history
  await audioProvider.loadPlayHistory();

  // Load persistent top charts rankings
  await audioProvider.loadTopChartsRankings();

  // Load user playlists
  await audioProvider.loadUserPlaylists();
  
  if (songs.isNotEmpty) {
    // Pre-load a random song so the player bar is populated on startup
    final randomSong = songs[Random().nextInt(songs.length)];
    await audioProvider.setInitialSong(randomSong, songs);
  }

  // Bridge: whenever EQ settings change, push the simulated volume to AudioProvider
  equalizerProvider.addListener(() {
    audioProvider.applyEqMultiplier(equalizerProvider.simulatedVolumeMultiplier);
  });
  // Apply initial EQ state
  audioProvider.applyEqMultiplier(equalizerProvider.simulatedVolumeMultiplier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: audioProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider.value(value: equalizerProvider),
      ],
      child: const SoniqoApp(),
    ),
  );
}

class SoniqoApp extends StatelessWidget {
  const SoniqoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Soniqo',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const HomeScreen(),
        );
      },
    );
  }
}
