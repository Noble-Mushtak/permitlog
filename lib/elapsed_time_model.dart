import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/safe_firebase_list.dart';
import 'package:permitlog/utilities.dart';

/// Class that manages subscription and data
/// related to how much time the user has completed in each category.
class ElapsedTimeModel {
  /// Reference to log data in Firebase.
  DatabaseReference _timesRef;
  /// Object that holds list of keys and listeners for log data.
  SafeFirebaseList _logList;
  /// Map that pairs keys to log data to the log data
  Map<String, Map> _logData = <String, Map>{};
  /// Object that stores the elapsed time for each category.
  DrivingTimes timeElapsed = new DrivingTimes();
  /// Callback provided by constructor to notify widget of data changes.
  void Function(DrivingTimes) _notifyDataChanged;

  /// Adds to or subtracts from timeElapsed using log data corresponding to key.
  void _updateTimeElapsed(String key, {bool subtract=false}) {
    /// Use negative numbers if we are subtracting time.
    int sign = subtract ? -1 : 1;

    /// Update the time totals.
    int duration = _logData[key]["end"] - _logData[key]["start"];
    timeElapsed.addTime("total", sign * duration);
    /// Update night if this log was at night, otherwise, update day.
    String nightOrDay = "day";
    if (_logData[key]["night"] ?? false) nightOrDay = "night";
    timeElapsed.addTime(nightOrDay, sign * duration);
    if (_logData[key]["weather"] ?? false) {
      timeElapsed.addTime("weather", sign * duration);
    }
    if (_logData[key]["adverse"] ?? false) {
      timeElapsed.addTime("adverse", sign * duration);
    }
  }
  /// onChildAdded callback for log data.
  void _logAdded(Event event) {
    /// Update _logData.
    _logData[event.snapshot.key] = event.snapshot.value;
    /// Update the time totals appropriately.
    _updateTimeElapsed(event.snapshot.key);
    /// Notify the widget.
    _notifyDataChanged(timeElapsed);
  }
  /// onChildChanged callback.
  void _logChanged(Event event) {
    /// Subtract the time from the old log.
    _updateTimeElapsed(event.snapshot.key, subtract: true);
    /// Now, act as if the log is being added.
    _logAdded(event);
  }
  /// onChildRemoved callback.
  void _logRemoved(Event event) {
    /// Subtract the time from the old log.
    _updateTimeElapsed(event.snapshot.key, subtract: true);
    /// Update _logData.
    _logData.remove(event.snapshot.key);
    /// Notify the widget.
    _notifyDataChanged(timeElapsed);
  }

  ElapsedTimeModel({@required DatabaseReference userRef, @required void Function(DrivingTimes) callback})
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
    /// Clear _logData and the DrivingTimes object.
    _logData.clear();
    for (String type in DrivingTimes.TIME_TYPES) timeElapsed.setTime(type, 0);
  }
}