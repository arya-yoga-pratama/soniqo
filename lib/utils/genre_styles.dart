import 'package:flutter/material.dart';

class GenreStyle {
  final IconData icon;
  final Color color;

  const GenreStyle({required this.icon, required this.color});
}

GenreStyle getGenreStyle(String genre) {
  switch (genre) {
    case 'Pop':
      return const GenreStyle(icon: Icons.favorite_rounded, color: Color(0xFFFF4081));
    case 'Rock':
      return const GenreStyle(icon: Icons.electric_bolt_rounded, color: Color(0xFFFF5252));
    case 'Jazz':
      return const GenreStyle(icon: Icons.nightlife_rounded, color: Color(0xFFFFAB40));
    case 'Hip Hop':
      return const GenreStyle(icon: Icons.mic_external_on_rounded, color: Color(0xFF4CAF50));
    case 'R&B':
      return const GenreStyle(icon: Icons.water_drop_rounded, color: Color(0xFF536DFE));
    case 'Electronic':
      return const GenreStyle(icon: Icons.vibration_rounded, color: Color(0xFF00E5FF));
    case 'Classical':
      return const GenreStyle(icon: Icons.auto_awesome_rounded, color: Color(0xFFCFD8DC));
    case 'Country':
      return const GenreStyle(icon: Icons.grass_rounded, color: Color(0xFFA5D6A7));
    case 'K-Pop':
      return const GenreStyle(icon: Icons.stars_rounded, color: Color(0xFF40C4FF));
    case 'Indie':
      return const GenreStyle(icon: Icons.brush_rounded, color: Color(0xFFFFAB00));
    case 'Metal':
      return const GenreStyle(icon: Icons.whatshot_rounded, color: Color(0xFF78909C));
    case 'Lo-fi':
      return const GenreStyle(icon: Icons.coffee_rounded, color: Color(0xFFB39DDB));
    case 'Acoustic':
      return const GenreStyle(icon: Icons.music_note_rounded, color: Color(0xFFFFE082));
    case 'Blues':
      return const GenreStyle(icon: Icons.waves_rounded, color: Color(0xFF448AFF));
    case 'Soul':
      return const GenreStyle(icon: Icons.volunteer_activism_rounded, color: Color(0xFF9575CD));
    default:
      return const GenreStyle(icon: Icons.music_note_rounded, color: Color(0xFFA54BFF));
  }
}
