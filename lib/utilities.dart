import 'package:intl/intl.dart';

/// Returns a String in H:MM format based off milliseconds.
String formatMilliseconds(int mseconds) {
  NumberFormat twoDigitFormat = new NumberFormat("00");
  Duration duration = new Duration(milliseconds: mseconds);
  int minutes = duration.inMinutes % Duration.minutesPerHour;
  return "${duration.inHours}:${twoDigitFormat.format(minutes)}";
}

/// Checks if log has all necessary data.
bool logIsValid(dynamic logData) {
  if (logData is Map) {
    /// Make sure start, end, night, driver_id keys are present.
    return logData.containsKey("start") && logData.containsKey("end")
        && logData.containsKey("night") && logData.containsKey("driver_id");
  }
  /// If it's not a Map, it's not valid.
  return false;
}