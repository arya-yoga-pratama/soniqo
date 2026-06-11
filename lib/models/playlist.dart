import 'package:flutter/material.dart';
import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverPath;
  final List<Color> gradientColors;
  final List<Song> songs;
  final String? about;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverPath,
    required this.gradientColors,
    required this.songs,
    this.about,
  });
}
