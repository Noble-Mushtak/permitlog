import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Class that manages a list of Firebase keys
/// that all link to complete data sets.
class SafeFirebaseList {
  /// List of Firebase keys
  List<String> keys;
  /// Callback which checks if data is complete
  bool Function(dynamic) _isDataComplete;
  /// Original callbacks for onChildAdded, onChildChanged, onChildRemoved
  void Function(Event) _addedCallback, _changedCallback, _removedCallback;
  /// In constructor, initialize callbacks.
  SafeFirebaseList({@required bool Function(dynamic) completeCallback, @required void Function(Event) addedCallback, @required void Function(Event) changedCallback, @required void Function(Event) removedCallback})
      : _isDataComplete = completeCallback,
        _addedCallback = addedCallback,
        _changedCallback = changedCallback,
        _removedCallback = removedCallback;

  /// This callback only invokes _addedCallback if the event has complete data.
  void safeAddedCallback(Event event) {
    /// If there is complete data, update keys and invoke _addedCallback.
    if (_isDataComplete(event.snapshot.value)) {
      keys.add(event.snapshot.key);
      _addedCallback(event.snapshot.value);
    }
  }
  /// This callback invokes safeAddedCallback if event is not in keys
  /// and invokes _changedCallback otherwise if the event has complete data.
  void safeChangedCallback(Event event) {
    /// If event is not in keys, invoke safeAddedCallback.
    if (!keys.contains(event.snapshot.key)) safeAddedCallback(event);
    /// If the event has complete data, invoke _changedCallback.
    else if (_isDataComplete(event.snapshot.value)) _changedCallback(event);
  }
  /// This callback only invokes _removedCallback if event is in keys.
  void safeRemovedCallback(Event event) {
    /// If event is in keys, invoke _removedCallback and update keys.
    if (keys.contains(event.snapshot.key)) {
      _removedCallback(event);
      keys.remove(event.snapshot.key);
    }
  }
}