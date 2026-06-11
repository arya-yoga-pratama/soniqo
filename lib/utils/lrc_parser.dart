import 'dart:io';
import '../models/lyric_line.dart';

Future<List<LyricLine>> parseLrc(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    final List<LyricLine> lyrics = [];

    // Regex for [mm:ss.xx] or [mm:ss:xx] or [mm:ss]
    final RegExp timeRegex = RegExp(r'\[(\d+):(\d+)(?:[:\.](\d+))?\]');

    for (var line in lines) {
      final matches = timeRegex.allMatches(line);
      if (matches.isEmpty) continue;

      // Extract the text part (after all timestamps)
      final text = line.replaceAll(timeRegex, '').trim();

      for (var match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisecondsStr = match.group(3) ?? '0';
        
        // Handle cases like .xx (centiseconds) or .xxx (milliseconds)
        int milliseconds = int.parse(millisecondsStr);
        if (millisecondsStr.length == 2) {
          milliseconds *= 10;
        }

        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lyrics.add(LyricLine(time: time, text: text));
      }
    }

    // LRC files aren't always sorted by time if there are multiple timestamps per line
    lyrics.sort((a, b) => a.time.compareTo(b.time));
    return lyrics;
  } catch (e) {
    print('Error parsing LRC: $e');
    return [];
  }
}
