import 'song.dart';

class PlayHistoryEntry {
  final Song song;
  final DateTime playedAt;

  PlayHistoryEntry({required this.song, required this.playedAt});
}
