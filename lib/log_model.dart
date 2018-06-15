import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/safe_firebase_list.dart';
import 'package:permitlog/utilities.dart';

/// Class that manages subscription and data related to log data.
class LogModel {
  /// Reference to log data in Firebase.
  DatabaseReference _timesRef;
  /// Object that holds list of keys and listeners for log data.
  SafeFirebaseList _logList;
  /// List of log keys.
  List<String> get logIds => _logList.keys;
  /// List of log summaries.
  List<String> logSummaries = <String>["No logs"];
  /// Map that pairs keys to log data to the log data
  Map<String, Map> logData = <String, Map>{};
  /// Object that stores the time the user has driven for each category.
  /// NOTE: These times are stored in milliseconds.
  DrivingTimes timeElapsed = new DrivingTimes();
  /// Callback provided by constructor to notify widget of data changes.
  void Function(List<String>, List<String>, DrivingTimes, Map<String, Map>) _notifyDataChanged;

  /// Generate summary for log.
  static String genLogSummary(Map logData) {
    /// Get the date that the drive started on.
    DateTime startingDateTime = new DateTime.fromMillisecondsSinceEpoch(logData["start"]);
    String dateFormatted = new DateFormat.yMd().format(startingDateTime);
    /// Get the duration of the drive.
    int driveDuration = logData["end"]-logData["start"];
    /// Combine this information into a string:
    return "Drove ${formatMilliseconds(driveDuration)} on $dateFormatted";
  }

  /// Adds to or subtracts from timeElapsed using log data corresponding to key.
  void _updateTimeElapsed(String key, {bool subtract=false}) {
    /// Use negative numbers if we are subtracting time.
    int sign = subtract ? -1 : 1;

    /// Update the time totals.
    int duration = logData[key]["end"] - logData[key]["start"];
    timeElapsed.addTime("total", sign * duration);
    /// Update night if this log was at night, otherwise, update day.
    String nightOrDay = "day";
    if (logData[key]["night"] ?? false) nightOrDay = "night";
    timeElapsed.addTime(nightOrDay, sign * duration);
    if (logData[key]["weather"] ?? false) {
      timeElapsed.addTime("weather", sign * duration);
    }
    if (logData[key]["adverse"] ?? false) {
      timeElapsed.addTime("adverse", sign * duration);
    }
  }
  /// onChildAdded callback for log data.
  void _logAdded(Event event) {
    /// If logData is empty, then logSummaries has "No logs", so fix that.
    if (logData.isEmpty) logSummaries.clear();
    /// Update logData and logSummaries.
    logData[event.snapshot.key] = event.snapshot.value;
    logSummaries.add(genLogSummary(event.snapshot.value));
    /// Update the time totals appropriately.
    _updateTimeElapsed(event.snapshot.key);
    /// Notify the widget.
    _notifyDataChanged(logIds, logSummaries, timeElapsed, logData);
  }
  /// onChildChanged callback.
  void _logChanged(Event event) {
    /// Subtract the time from the old log.
    _updateTimeElapsed(event.snapshot.key, subtract: true);
    /// Now, act as if the log is being added.
    logData[event.snapshot.key] = event.snapshot.value;
    _updateTimeElapsed(event.snapshot.key);
    /// Update logSummaries.
    int logIndex = logIds.indexOf(event.snapshot.key);
    logSummaries[logIndex] = genLogSummary(event.snapshot.value);
    /// Notify the widget.
    _notifyDataChanged(logIds, logSummaries, timeElapsed, logData);
  }
  /// onChildRemoved callback.
  void _logRemoved(Event event) {
    /// Subtract the time from the old log.
    _updateTimeElapsed(event.snapshot.key, subtract: true);
    /// Update logData and logSummaries.
    logData.remove(event.snapshot.key);
    int logIndex = logIds.indexOf(event.snapshot.key);
    logSummaries.removeAt(logIndex);
    /// Add "No logs" if logSummaries is empty.
    if (logSummaries.isEmpty) logSummaries.add("No logs");
    /// Notify the widget.
    _notifyDataChanged(logIds, logSummaries, timeElapsed, logData);
  }

  LogModel({@required DatabaseReference userRef, @required void Function(List<String>, List<String>, DrivingTimes, Map<String, Map>) callback})
    : _timesRef = userRef?.child("times"),
      _notifyDataChanged = callback {
    _logList = new SafeFirebaseList(
        completeCallback: logIsValid,
        addedCallback: _logAdded,
        changedCallback: _logChanged,
        removedCallback: _logRemoved
    );
  }

  /// Start subscriptions to _timesRef.
  void startSubscriptions() {
    _logList.startSubscriptions(_timesRef);
  }
  /// Cancels subscriptions to _timesRef.
  Future<void> cancelSubscriptions() async {
    await _logList.cancelSubscriptions();
    /// Clear logData and the DrivingTimes object.
    logData.clear();
    for (String type in DrivingTimes.TIME_TYPES) timeElapsed.setTime(type, 0);
    /// Reset logSummaries.
    logSummaries.clear();
    logSummaries.add("No logs");
  }
}