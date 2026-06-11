/// Formats a Duration into a string of the format "mm:ss".
/// If the duration is null, it returns "0:00".
String formatDuration(Duration? duration) {
  if (duration == null || duration == Duration.zero) {
    return "0:00";
  }
  
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
