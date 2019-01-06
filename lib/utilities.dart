import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns a String in H:MM format based on the given number of milliseconds.
/// Throws an [ArgumentError] if the number of milliseconds is negative.
String formatMilliseconds(int milliseconds) {
  if (milliseconds < 0) {
    throw ArgumentError("Number of milliseconds must be positive.");
  }
  NumberFormat twoDigitFormat = new NumberFormat("00");
  Duration duration = new Duration(milliseconds: milliseconds);
  int minutes = duration.inMinutes % Duration.minutesPerHour;
  return "${duration.inHours}:${twoDigitFormat.format(minutes)}";
}

/// Gets reference to data for current learner.
DatabaseReference getCurrentLearnerRef(DatabaseReference userRef,
    String learnerKey) {
  if (userRef == null) {
    throw ArgumentError("Invalid user database reference.");
  }
  // If this is the default learner, just return userRef.
  if (learnerKey.isEmpty) return userRef;
  // Otherwise, return the appropriate subchild of learners.
  return userRef.child("learners").child(learnerKey);
}

/// Checks if the give log is valid. A valid log consists of a [Map] containing
/// the keys `start`, `end`, `night`, and `driver_id`. Each represents
/// an attributed of a logged drive.
bool logIsValid(dynamic logData) {
  if (logData is Map) {
    return logData.containsKey("start") &&
        logData.containsKey("end") &&
        logData.containsKey("night") &&
        logData.containsKey("driver_id");
  }
  return false;
}

/// Checks if the given data about a person has a complete name.
/// A complete name occurs when the given data is a [Map] with key `name`,
/// containing another [Map] with the keys `first` and `last`.
bool hasCompleteName(dynamic personData) {
  if (personData is Map && (personData["name"] is Map)) {
    return personData["name"].containsKey("first") &&
        personData["name"].containsKey("last");
  }
  return false;
}

/// Returns the full name from the given person data. If the data does not have
/// a complete name, see [hasCompleteName], throws an [ArgumentError].
String createName(Map personData) {
  if (!hasCompleteName(personData)) {
    throw new ArgumentError("Given person data does not contain a full name.");
  }
  return "${personData["name"]["first"]} ${personData["name"]["last"]}";
}

/// Helper method that shows the given message to user on a [SnackBar] if
/// the message is not null.
void showNonEmptyMessage(BuildContext context, String message) {
  // Remove current message
  Scaffold.of(context).removeCurrentSnackBar();
  // Display the new message as a SnackBar if not null
  if (message == null) return;
  Scaffold.of(context).showSnackBar(new SnackBar(content: new Text(message)));
}

/// Converts the given List of Strings into a List of [DropdownMenuItem].
/// The value of each item is its index in the original list.
List<DropdownMenuItem<num>> createDropdownItems(List<String> data) {
  List<DropdownMenuItem<num>> items = [];
  for (int i = 0; i < data.length; i++) {
    items.add(DropdownMenuItem<num>(value: i, child: Text(data[i])));
  }
  return items;
}
