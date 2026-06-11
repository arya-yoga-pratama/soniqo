import 'package:flutter/material.dart';
import '../widgets/image_helper.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String audioPath;
  final String coverPath;
  String? lyricsPath;
  String? karaokePath;
  String? genre;
  String? album;
  final DateTime addedAt;
  Duration duration;
  bool isLiked;
  int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioPath,
    required this.coverPath,
    this.genre,
    this.album,
    this.lyricsPath,
    this.karaokePath,
    DateTime? addedAt,
    this.duration = Duration.zero,
    this.isLiked = false,
    this.playCount = 0,
  }) : addedAt = addedAt ?? DateTime.now();

  ImageProvider get imageProvider => getImageProvider(coverPath);
}
