import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../widgets/image_helper.dart';

List<Song> allSongsData = [];

/// Save song metadata (genre + album) to SharedPreferences
Future<void> saveSongMetadata(Song song) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Save genre
    if (song.genre != null && song.genre!.isNotEmpty) {
      final String? genresJson = prefs.getString('song_genres');
      Map<String, dynamic> genresMap = {};
      if (genresJson != null) genresMap = json.decode(genresJson);
      genresMap[song.id] = song.genre;
      await prefs.setString('song_genres', json.encode(genresMap));
    }

    // Save album
    if (song.album != null && song.album!.isNotEmpty) {
      final String? albumsJson = prefs.getString('song_albums');
      Map<String, dynamic> albumsMap = {};
      if (albumsJson != null) albumsMap = json.decode(albumsJson);
      albumsMap[song.id] = song.album;
      await prefs.setString('song_albums', json.encode(albumsMap));
    }
  } catch (e) {
    logScan('Error saving song metadata: $e');
  }
}

/// Save a lyrics file path for a song to SharedPreferences
Future<void> saveSongLyricsPath(Song song) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? lyricsJson = prefs.getString('song_lyrics_paths');
    Map<String, dynamic> lyricsMap = {};
    if (lyricsJson != null) lyricsMap = json.decode(lyricsJson);
    if (song.lyricsPath != null && song.lyricsPath!.isNotEmpty) {
      lyricsMap[song.id] = song.lyricsPath;
    } else {
      lyricsMap.remove(song.id);
    }
    await prefs.setString('song_lyrics_paths', json.encode(lyricsMap));
  } catch (e) {
    logScan('Error saving song lyrics path: $e');
  }
}

/// Save a karaoke file path for a song to SharedPreferences
Future<void> saveSongKaraokePath(Song song) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? karaokeJson = prefs.getString('song_karaoke_paths');
    Map<String, dynamic> karaokeMap = {};
    if (karaokeJson != null) karaokeMap = json.decode(karaokeJson);
    if (song.karaokePath != null && song.karaokePath!.isNotEmpty) {
      karaokeMap[song.id] = song.karaokePath;
    } else {
      karaokeMap.remove(song.id);
    }
    await prefs.setString('song_karaoke_paths', json.encode(karaokeMap));
  } catch (e) {
    logScan('Error saving song karaoke path: $e');
  }
}

/// Save song play count to SharedPreferences
Future<void> saveSongPlayCount(Song song) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? countsJson = prefs.getString('song_play_counts_map');
    
    Map<String, dynamic> countsMap = {};
    if (countsJson != null) {
      countsMap = json.decode(countsJson);
    }
    
    countsMap[song.id] = song.playCount;
    await prefs.setString('song_play_counts_map', json.encode(countsMap));
  } catch (e) {
    logScan('Error saving song play count: $e');
  }
}

/// Refactored song scanner for Soniqo.
/// Scans the local directory for .mp3 files and prepares song data.
Future<List<Song>> scanSongs() async {
  final List<Song> songs = [];
  const musicDirPath = 'D:/Soniqo/assets/musik';
  const posterDirPath = 'D:/Soniqo/assets/poster';
  
  final musicDir = Directory(musicDirPath);
  
  if (!musicDir.existsSync()) {
    logScan('Music directory not found: $musicDirPath');
    return [];
  }

  // Load saved metadata (genres, albums, play counts, lyrics paths, karaoke paths)
  Map<String, dynamic> savedGenres = {};
  Map<String, dynamic> savedAlbums = {};
  Map<String, dynamic> savedPlayCounts = {};
  Map<String, dynamic> savedLyricsPaths = {};
  Map<String, dynamic> savedKaraokePaths = {};
  try {
    final prefs = await SharedPreferences.getInstance();
    
    final String? genresJson = prefs.getString('song_genres');
    if (genresJson != null) savedGenres = json.decode(genresJson);
    
    final String? albumsJson = prefs.getString('song_albums');
    if (albumsJson != null) savedAlbums = json.decode(albumsJson);
    
    final String? countsJson = prefs.getString('song_play_counts_map');
    if (countsJson != null) savedPlayCounts = json.decode(countsJson);

    final String? lyricsPathsJson = prefs.getString('song_lyrics_paths');
    if (lyricsPathsJson != null) savedLyricsPaths = json.decode(lyricsPathsJson);

    final String? karaokePathsJson = prefs.getString('song_karaoke_paths');
    if (karaokePathsJson != null) savedKaraokePaths = json.decode(karaokePathsJson);
  } catch (e) {
    logScan('Error loading song metadata: $e');
  }

  try {
    // Perform a sync scan for simplicity in this implementation
    final files = musicDir.listSync();
    
    for (var file in files) {
      if (file is File && p.extension(file.path).toLowerCase() == '.mp3') {
        final fullPath = file.path;
        final fileNameNoExt = p.basenameWithoutExtension(fullPath);
        
        // 1. Parse Info
        final info = _parseSongInfo(fileNameNoExt);
        
        // 2. Match Cover
        final coverPath = _findCoverPath(fileNameNoExt, posterDirPath);

        // 3. Match Lyrics
        final lyricsPath = 'D:/Soniqo/assets/lyrics/$fileNameNoExt.lrc';
        String? finalLyricsPath;
        if (File(lyricsPath).existsSync()) {
          finalLyricsPath = lyricsPath;
        }

        // Retrieve saved metadata
        final String? savedGenre = savedGenres[fullPath];
        final String? savedAlbum = savedAlbums[fullPath];
        final int savedPlayCount = (savedPlayCounts[fullPath] as num?)?.toInt() ?? 0;
        // Prefer user-uploaded lyrics path over the default scanned one
        final String? savedLyricsPath = savedLyricsPaths[fullPath] as String?;
        final String? effectiveLyricsPath = (savedLyricsPath != null && File(savedLyricsPath).existsSync())
            ? savedLyricsPath
            : finalLyricsPath;
        
        final String? savedKaraokePath = savedKaraokePaths[fullPath] as String?;
        final String? effectiveKaraokePath = (savedKaraokePath != null && File(savedKaraokePath).existsSync())
            ? savedKaraokePath
            : null;

        // 4. Create Song Object
        songs.add(Song(
          id: fullPath,
          title: _capitalize(info.title),
          artist: _capitalize(info.artist),
          audioPath: fullPath,
          coverPath: coverPath,
          lyricsPath: effectiveLyricsPath,
          karaokePath: effectiveKaraokePath,
          genre: savedGenre,
          album: savedAlbum,
          duration: Duration.zero,
          playCount: savedPlayCount,
          addedAt: file.statSync().modified,
        ));
      }
    }
    
    logScan('Successfully scanned ${songs.length} songs.');
  } catch (e) {
    logScan('Error during directory scan: $e');
  }

  // Sort alphabetically by title for a predictable list
  songs.sort((a, b) => a.title.compareTo(b.title));
  
  allSongsData = songs;
  return songs;
}

/// Robustly parses Artist and Title from a filename.
/// Supports: "Artist - Title", "Artist_Title", or just "Title"
_SongInfo _parseSongInfo(String fileName) {
  String artist = 'Unknown Artist';
  String title = fileName;

  // Try "Artist - Title" first (standard separator)
  if (fileName.contains(' - ')) {
    final parts = fileName.split(' - ');
    if (parts.length >= 2) {
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
      return _SongInfo(artist: artist, title: title);
    }
  }

  // Try "Artist_Title" (legacy separator)
  if (fileName.contains('_')) {
    final parts = fileName.split('_');
    if (parts.length >= 2) {
      artist = parts[0].trim();
      title = parts.sublist(1).join('_').replaceAll('_', ' ').trim();
      return _SongInfo(artist: artist, title: title);
    }
  }

  // Fallback to just title
  return _SongInfo(artist: artist, title: title);
}

/// Finds a matching cover image in the poster directory.
/// Checks extensions in order: .jpg -> .png -> .jpeg
String _findCoverPath(String fileName, String posterDirPath) {
  const extensions = ['.jpg', '.png', '.jpeg'];
  
  for (var ext in extensions) {
    final potentialPath = p.join(posterDirPath, '$fileName$ext');
    if (File(potentialPath).existsSync()) {
      return potentialPath;
    }
  }

  return kDefaultCover;
}

/// Formats text to Capital Case for better UI presentation.
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// Safe scanner logging.
void logScan(String message) {
  // ignore: avoid_print
  print('[Soniqo Scanner] $message');
}

/// Internal helper class for song metadata.
class _SongInfo {
  final String artist;
  final String title;
  _SongInfo({required this.artist, required this.title});
}
