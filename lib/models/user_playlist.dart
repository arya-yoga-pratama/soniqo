import 'dart:convert';

class UserPlaylist {
  String id;
  String title;
  String? description;
  String? coverPath;
  DateTime createdAt;
  List<String> songIds;

  UserPlaylist({
    required this.id,
    required this.title,
    this.description,
    this.coverPath,
    required this.createdAt,
    required this.songIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverPath': coverPath,
      'createdAt': createdAt.toIso8601String(),
      'songIds': songIds,
    };
  }

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverPath: json['coverPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      songIds: (json['songIds'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}
