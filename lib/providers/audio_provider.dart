import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/play_history_entry.dart';
import '../models/favourite_entry.dart';
import '../models/lyric_line.dart';
import '../utils/lrc_parser.dart';
import '../data/songs_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_playlist.dart';

enum RepeatState { off, all, one }

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _metadataPlayer = AudioPlayer();
  bool _isPreloading = false;
  bool _isDisposed = false;
  // Cancellation token for preloading — incremented whenever we want to abort
  int _preloadGeneration = 0;
  
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isKaraokeMode = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.6;
  bool _isShuffle = false;
  RepeatState _loopMode = RepeatState.off;
  bool _isTransitioning = false; // guard against completion event race
  final List<PlayHistoryEntry> _playHistory = [];
  final List<FavouriteEntry> _favourites = [];
  List<LyricLine> _currentLyrics = [];
  Map<String, int> _previousRankings = {};
  DateTime? _lastRankingUpdate;
  List<UserPlaylist> _userPlaylists = [];

  AudioProvider() {
    _initStreams();
  }

  /// Pre-loads a song so the player bar is populated on startup without auto-playing.
  Future<void> setInitialSong(Song song, List<Song> playlist) async {
    _playlist = playlist;
    _currentIndex = playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex == -1) {
      _playlist = [song];
      _currentIndex = 0;
    }
    _totalDuration = song.duration;
    _currentPosition = Duration.zero;
    _loadLyrics(song);
    notifyListeners();
    
    // Trigger preloading for the entire playlist
    preloadDurations(_playlist);

    try {
      if (song.audioPath.startsWith('assets/')) {
        await _audioPlayer.setAsset(song.audioPath);
      } else {
        await _audioPlayer.setFilePath(song.audioPath);
      }
      _audioPlayer.setVolume((_volume * _eqMultiplier).clamp(0.0, 1.0));
      // Do NOT call play() — just have it ready
    } catch (e) {
      debugPrint('Error pre-loading initial song: $e');
    }
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  void _initStreams() {
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _safeNotify();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        if (currentSong != null && currentSong!.duration == Duration.zero) {
          currentSong!.duration = duration;
        }
        _safeNotify();
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      _isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      
      if (processingState == ProcessingState.completed && !_isTransitioning) {
        _isTransitioning = true;
        if (_loopMode == RepeatState.one) {
          seek(Duration.zero);
          _audioPlayer.play();
          _isTransitioning = false;
        } else if (_loopMode == RepeatState.all) {
          next();
        } else {
          next();
        }
      }
      _safeNotify();
    });
  }

  // Getters
  List<Song> get playlist => _playlist;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isKaraokeMode => _isKaraokeMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  RepeatState get loopMode => _loopMode;
  List<PlayHistoryEntry> get playHistory => List.unmodifiable(_playHistory);
  List<FavouriteEntry> get favourites => List.unmodifiable(_favourites);
  List<LyricLine> get currentLyrics => _currentLyrics;
  bool get hasLyrics => _currentLyrics.isNotEmpty;
  Map<String, int> get previousRankings => _previousRankings;
  List<UserPlaylist> get userPlaylists => List.unmodifiable(_userPlaylists);
  bool isFavourite(Song song) => _favourites.any((e) => e.song.id == song.id);

  // Actions
  void setPlaylist(List<Song> songs) {
    _playlist = songs;
    notifyListeners();
    preloadDurations(_playlist);
  }

  Future<void> preloadDurations(List<Song> songs) async {
    // Increment generation to invalidate any previous in-flight preload
    _preloadGeneration++;
    final myGeneration = _preloadGeneration;

    if (_isPreloading) return;
    _isPreloading = true;

    int updatedCount = 0;
    for (final song in songs) {
      // Abort if: disposed, user started playing, or a newer preload was requested
      if (_isDisposed || _isPlaying || myGeneration != _preloadGeneration) {
        _isPreloading = false;
        return;
      }

      // Skip if duration is already known
      if (song.duration != Duration.zero) continue;

      try {
        await _metadataPlayer.stop();
        
        // Re-check after await — state may have changed
        if (_isDisposed || _isPlaying || myGeneration != _preloadGeneration) {
          _isPreloading = false;
          return;
        }

        if (song.audioPath.startsWith('assets/')) {
          await _metadataPlayer.setAsset(song.audioPath);
        } else {
          await _metadataPlayer.setFilePath(song.audioPath);
        }

        if (_isDisposed || _isPlaying || myGeneration != _preloadGeneration) {
          _isPreloading = false;
          return;
        }

        final duration = _metadataPlayer.duration;
        if (duration != null) {
          song.duration = duration;
          updatedCount++;

          if (updatedCount % 5 == 0) {
            _safeNotify();
          }
        }
      } catch (e) {
        debugPrint('Error preloading duration for ${song.title}: $e');
      }

      // Staggered delay to reduce resource pressure
      await Future.delayed(const Duration(milliseconds: 150));
    }

    _isPreloading = false;
    _safeNotify();
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    if (playlist != null) {
      _playlist = playlist;
    }

    int index = _playlist.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      // Fallback: if not found, play it as a single-song playlist
      _playlist = [song];
      index = 0;
    }

    _currentIndex = index;
    _currentPosition = Duration.zero;
    _totalDuration = song.duration; // Set default before stream update
    _isKaraokeMode = false; // Reset karaoke mode on new song
    _loadLyrics(song);
    notifyListeners();

    try {
      // Cancel any ongoing preload before starting new audio
      _preloadGeneration++;

      await _audioPlayer.stop();
      if (song.audioPath.startsWith('assets/')) {
        await _audioPlayer.setAsset(song.audioPath);
      } else {
        await _audioPlayer.setFilePath(song.audioPath);
      }
      _audioPlayer.setVolume((_volume * _eqMultiplier).clamp(0.0, 1.0));
      
      _audioPlayer.play();
      _isTransitioning = false;
      
      // Increment play count
      song.playCount++;
      saveSongPlayCount(song);
      
      // Record to play history
      _playHistory.removeWhere((entry) => entry.song.id == song.id);
      _playHistory.insert(0, PlayHistoryEntry(song: song, playedAt: DateTime.now()));
      if (_playHistory.length > 10) {
        _playHistory.removeLast();
      }
      _savePlayHistory();
      _safeNotify();
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  Future<void> _loadLyrics(Song song) async {
    _currentLyrics = [];
    if (song.lyricsPath != null) {
      _currentLyrics = await parseLrc(song.lyricsPath!);
    }
    notifyListeners();
  }

  /// Called after user picks an .lrc file. Updates the song, saves persistently, reloads lyrics.
  Future<void> uploadLyricsPath(Song song, String filePath) async {
    song.lyricsPath = filePath;
    await saveSongLyricsPath(song);
    await _loadLyrics(song);
  }

  /// Called after user picks an mp3 file for karaoke.
  Future<void> uploadKaraokePath(Song song, String filePath) async {
    song.karaokePath = filePath;
    await saveSongKaraokePath(song);
    
    // If the song is currently playing, we might want to auto-enable it, but for now just notify
    notifyListeners();
  }

  /// Removes the karaoke file for a song and reverts playback if active.
  Future<void> removeKaraokePath(Song song) async {
    song.karaokePath = null;
    await saveSongKaraokePath(song);
    
    if (currentSong?.id == song.id && _isKaraokeMode) {
      _isKaraokeMode = false;
      notifyListeners();

      final position = _currentPosition;
      final wasPlaying = _isPlaying;
      
      try {
        await _audioPlayer.stop();
        final path = currentSong!.audioPath;
        if (path.startsWith('assets/')) {
          await _audioPlayer.setAsset(path);
        } else {
          await _audioPlayer.setFilePath(path);
        }
        _audioPlayer.setVolume((_volume * _eqMultiplier).clamp(0.0, 1.0));
        await _audioPlayer.seek(position);
        if (wasPlaying) {
          _audioPlayer.play();
        }
      } catch(e) {
        debugPrint("Error reverting karaoke mode: $e");
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> toggleKaraokeMode() async {
    if (currentSong == null) return;
    if (currentSong!.karaokePath == null) return;
    
    _isKaraokeMode = !_isKaraokeMode;
    notifyListeners();

    // Switch audio source smoothly
    final position = _currentPosition;
    final wasPlaying = _isPlaying;
    
    try {
      await _audioPlayer.stop();
      final path = _isKaraokeMode ? currentSong!.karaokePath! : currentSong!.audioPath;
      if (path.startsWith('assets/')) {
        await _audioPlayer.setAsset(path);
      } else {
        await _audioPlayer.setFilePath(path);
      }
      _audioPlayer.setVolume((_volume * _eqMultiplier).clamp(0.0, 1.0));
      await _audioPlayer.seek(position);
      if (wasPlaying) {
        _audioPlayer.play();
      }
    } catch(e) {
      debugPrint("Error switching karaoke mode: $e");
    }
  }

  void togglePlayPause() {
    if (currentSong == null) {
      if (_playlist.isNotEmpty) {
        next();
      }
      return;
    }
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
      }
      _audioPlayer.play();
    }
  }

  void next() {
    if (_playlist.isEmpty) return;
    if (_isShuffle) {
      _currentIndex = (_currentIndex + 2) % _playlist.length; // dummy shuffle
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    
    if (currentSong != null) {
      playSong(currentSong!);
    }
  }

  void previous() {
    if (_playlist.isEmpty) return;
    if (_currentPosition.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    if (currentSong != null) {
      playSong(currentSong!);
    }
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  double _eqMultiplier = 1.0; // set by EQ bridge

  void setVolume(double vol) {
    _volume = vol;
    _audioPlayer.setVolume((vol * _eqMultiplier).clamp(0.0, 1.0));
    notifyListeners();
  }

  /// Called from the EQ bridge whenever the equalizer preset/settings change.
  void applyEqMultiplier(double multiplier) {
    _eqMultiplier = multiplier;
    _audioPlayer.setVolume((_volume * _eqMultiplier).clamp(0.0, 1.0));
  }


  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    if (_loopMode == RepeatState.off) {
      _loopMode = RepeatState.all;
    } else if (_loopMode == RepeatState.all) {
      _loopMode = RepeatState.one;
    } else {
      _loopMode = RepeatState.off;
    }
    notifyListeners();
  }

  void toggleLike() {
    if (currentSong != null) {
      final song = currentSong!;
      final alreadyLiked = _favourites.any((e) => e.song.id == song.id);
      if (alreadyLiked) {
        _favourites.removeWhere((e) => e.song.id == song.id);
        song.isLiked = false;
      } else {
        _favourites.add(FavouriteEntry(song: song, addedAt: DateTime.now()));
        song.isLiked = true;
      }
      _saveFavourites();
      notifyListeners();
    }
  }

  void removeFavourite(Song song) {
    _favourites.removeWhere((e) => e.song.id == song.id);
    song.isLiked = false;
    _saveFavourites();
    notifyListeners();
  }

  void addFavourite(Song song) {
    if (!_favourites.any((e) => e.song.id == song.id)) {
      _favourites.add(FavouriteEntry(song: song, addedAt: DateTime.now()));
      song.isLiked = true;
      _saveFavourites();
      notifyListeners();
    }
  }

  // Persistence logic
  Future<void> _saveFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _favourites.map((e) => e.song.id).toList();
      await prefs.setStringList('favourite_song_ids', ids);
    } catch (e) {
      debugPrint('Error saving favourites: $e');
    }
  }

  Future<void> loadFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('favourite_song_ids');
      
      if (ids == null || ids.isEmpty) return;

      _favourites.clear();
      
      // Use allSongsData to find the actual Song objects
      for (final id in ids) {
        try {
          final song = allSongsData.firstWhere((s) => s.id == id);
          song.isLiked = true;
          _favourites.add(FavouriteEntry(song: song, addedAt: DateTime.now()));
        } catch (e) {
          // Song might have been deleted or moved
          debugPrint('Song with ID $id not found while loading favourites');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favourites: $e');
    }
  }

  Future<void> _savePlayHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonList = _playHistory.map((e) => json.encode({
        'id': e.song.id,
        'playedAt': e.playedAt.toIso8601String(),
      })).toList();
      await prefs.setStringList('play_history_list', historyJsonList);
    } catch (e) {
      debugPrint('Error saving play history: $e');
    }
  }

  Future<void> loadPlayHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonList = prefs.getStringList('play_history_list');
      
      if (historyJsonList == null || historyJsonList.isEmpty) return;

      _playHistory.clear();
      
      for (final jsonStr in historyJsonList) {
        try {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          final id = map['id'] as String;
          final playedAtStr = map['playedAt'] as String;
          final playedAt = DateTime.parse(playedAtStr);
          
          final song = allSongsData.firstWhere((s) => s.id == id);
          _playHistory.add(PlayHistoryEntry(song: song, playedAt: playedAt));
        } catch (e) {
          debugPrint('Song not found or invalid data while loading history');
        }
      }
      
      if (_playHistory.length > 10) {
        _playHistory.removeRange(10, _playHistory.length);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading play history: $e');
    }
  }

  Future<void> loadTopChartsRankings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rankingsJson = prefs.getString('top_charts_previous_rankings');
      final lastUpdateStr = prefs.getString('top_charts_last_update');

      if (rankingsJson != null) {
        final Map<String, dynamic> decoded = json.decode(rankingsJson);
        _previousRankings = decoded.map((key, value) => MapEntry(key, value as int));
      }

      if (lastUpdateStr != null) {
        _lastRankingUpdate = DateTime.parse(lastUpdateStr);
      }

      // If no rankings or older than 24h (optional logic, but let's stick to user request of persistence)
      // If none exist, we'll initialize them from current allSongsData
      if (_previousRankings.isEmpty && allSongsData.isNotEmpty) {
        updatePreviousRankings();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading top charts rankings: $e');
    }
  }

  Future<void> updatePreviousRankings() async {
    final List<Song> sorted = List.from(allSongsData);
    sorted.sort((a, b) {
      int cmp = b.playCount.compareTo(a.playCount);
      if (cmp == 0) return b.addedAt.compareTo(a.addedAt);
      return cmp;
    });

    _previousRankings = {};
    for (int i = 0; i < sorted.length; i++) {
      _previousRankings[sorted[i].id] = i + 1;
    }
    _lastRankingUpdate = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('top_charts_previous_rankings', json.encode(_previousRankings));
      await prefs.setString('top_charts_last_update', _lastRankingUpdate!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving top charts rankings: $e');
    }
    notifyListeners();
  }

  void addSongToLibrary(Song song) {
    // Save metadata persistently
    saveSongMetadata(song);

    // Add to the runtime playlist
    _playlist.add(song);
    
    // Also add to the global dataset so it shows up in Library/Explore
    if (!allSongsData.any((s) => s.id == song.id)) {
      allSongsData.add(song);
    }
    
    notifyListeners();
    // Preload duration for this new song
    preloadDurations([song]);
  }

  void clearHistory() {
    _playHistory.clear();
    _savePlayHistory();
    notifyListeners();
  }

  // ── User Playlists ────────────────────────────────────────────────────────

  Future<void> loadUserPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJsonList = prefs.getStringList('user_playlists');
      
      if (playlistsJsonList == null || playlistsJsonList.isEmpty) return;

      _userPlaylists.clear();
      for (final jsonStr in playlistsJsonList) {
        try {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          _userPlaylists.add(UserPlaylist.fromJson(map));
        } catch (e) {
          debugPrint('Error loading a playlist: $e');
        }
      }
      // Sort by newest first
      _userPlaylists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user playlists: $e');
    }
  }

  Future<void> _saveUserPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJsonList = _userPlaylists.map((p) => json.encode(p.toJson())).toList();
      await prefs.setStringList('user_playlists', playlistsJsonList);
    } catch (e) {
      debugPrint('Error saving user playlists: $e');
    }
  }

  Future<UserPlaylist> createUserPlaylist(String title, {String? description, String? coverPath}) async {
    final newPlaylist = UserPlaylist(
      id: const Uuid().v4(),
      title: title,
      description: description,
      coverPath: coverPath,
      createdAt: DateTime.now(),
      songIds: [],
    );
    _userPlaylists.insert(0, newPlaylist);
    notifyListeners();
    await _saveUserPlaylists();
    return newPlaylist;
  }

  Future<void> updateUserPlaylist(String id, String title, {String? description, String? coverPath}) async {
    final index = _userPlaylists.indexWhere((p) => p.id == id);
    if (index != -1) {
      _userPlaylists[index].title = title;
      _userPlaylists[index].description = description;
      if (coverPath != null) {
        _userPlaylists[index].coverPath = coverPath;
      }
      notifyListeners();
      await _saveUserPlaylists();
    }
  }

  Future<void> deleteUserPlaylist(String id) async {
    _userPlaylists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _saveUserPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      if (!_userPlaylists[index].songIds.contains(songId)) {
        _userPlaylists[index].songIds.add(songId);
        notifyListeners();
        await _saveUserPlaylists();
      }
    }
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      bool changed = false;
      for (final songId in songIds) {
        if (!_userPlaylists[index].songIds.contains(songId)) {
          _userPlaylists[index].songIds.add(songId);
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
        await _saveUserPlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _userPlaylists[index].songIds.remove(songId);
      notifyListeners();
      await _saveUserPlaylists();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _preloadGeneration++; // Cancel any in-flight preload
    _audioPlayer.dispose();
    _metadataPlayer.dispose();
    super.dispose();
  }
}
