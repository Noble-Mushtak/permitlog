import 'package:flutter/material.dart';
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

/// Checks if some data about a person has a complete name.
bool hasCompleteName(dynamic personData) {
  /// If this is a Map and personData["name"] is a Map,
  /// then check if the "first" and "last" keys are present.
  if (personData is Map && (personData["name"] is Map)) {
    return personData["name"].containsKey("first")
        && personData["name"].containsKey("last");
  }
  /// Otherwise, just return false.
  else return false;
}

/// Creates name based off data about person.
String createName(Map personData) {
  return personData["name"]["first"]+" "+personData["name"]["last"];
}

/// Helper method that shows non-null messages to user on SnackBar
void showNonEmptyMessage(BuildContext context, String message) {
  /// Remove current message
  Scaffold.of(context).removeCurrentSnackBar();
  /// Don't show anything if message is null.
  if (message == null) return;
  /// Show message
  Scaffold.of(context).showSnackBar(new SnackBar(content: new Text(message)));
}

/// Returns a list of menu items that show each String in data using child,
/// but have the value of the index of that String in data
List<DropdownMenuItem<num>> createDropdownItems(List<String> data) {
  List<DropdownMenuItem<num>> items = [];
  /// Add an item for each String in data.
  for (int i = 0; i < data.length; i++) {
    items.add(
      new DropdownMenuItem<num>(value: i, child: new Text(data[i]))
    );
  }
  return items;
}