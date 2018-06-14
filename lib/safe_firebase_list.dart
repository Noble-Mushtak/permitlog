import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Class that manages a list of Firebase keys
/// that all link to complete data sets.
class SafeFirebaseList {
  /// List of Firebase keys
  List<String> keys = <String>[];
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
      _addedCallback(event);
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

  /// Stores subscriptions to onChildAdded, onChildChanged, onChildRemoved events.
  StreamSubscription<Event> _addedSubscription;
  StreamSubscription<Event> _changedSubscription;
  StreamSubscription<Event> _removedSubscription;
  /// Boolean that keeps track of if subscriptions are listening.
  bool isListening = false;
  /// Starts subscriptions to some Firebase reference (which may be null).
  void startSubscriptions(DatabaseReference dataRef) {
    /// Only make changes if subscriptions are not yet listening.
    if (!isListening) {
      /// Start the subscriptions using the safe callbacks.
      _addedSubscription = dataRef?.onChildAdded?.listen(safeAddedCallback);
      _changedSubscription = dataRef?.onChildChanged?.listen(safeChangedCallback);
      _removedSubscription = dataRef?.onChildRemoved?.listen(safeRemovedCallback);
      /// Update isListening.
      isListening = true;
    }
  }
  /// Cancels subscriptions.
  Future<void> cancelSubscriptions() async {
    /// Only make changes if subscriptions are already listening.
    if (isListening) {
      /// Cancel all subscriptions.
      await _addedSubscription?.cancel();
      await _changedSubscription?.cancel();
      await _removedSubscription?.cancel();
      /// Clear the data.
      keys.clear();
      /// Update isListening.
      isListening = false;
    }
  }
}