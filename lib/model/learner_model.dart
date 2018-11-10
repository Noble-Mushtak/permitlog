import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/safe_firebase_list.dart';
import 'package:permitlog/utilities.dart';

/// Class that manages subscription and data related to learners.
class LearnerModel {
  /// Firebase API Interface.
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// References to learner data in Firebase.
  DatabaseReference _defaultLeanerRef;
  DatabaseReference _learnersRef;
  /// Subscription that listens for changes in default learner's name.
  StreamSubscription<Event> _defaultLearnerSubscription;
  /// Object that holds keys and listeners for learner data.
  /// Does not contain key for default learner.
  SafeFirebaseList _learnerList;
  /// List of learner keys.
  List<String> get learnerIds => _learnerList.keys;
  /// List of learner names.
  List<String> learnerNames = <String>["Default Learner"];
  /// Callback used to notify widget of data changes.
  void Function(List<String>, List<String>) _notifyDataChanged;

  /// onValue callback for default learner.
  void _defaultLearnerChanged(Event event) {
    /// Update default learner's name if it is complete.
    bool completeName = false;
    if (event.snapshot.value is Map) {
      Map name = event.snapshot.value;
      if (name.containsKey("first") && name.containsKey("last")) {
        learnerNames[0] = name["first"] + " " + name["last"];
        completeName = true;
      }
    }
    /// If name is incomplete, just use "Default Learner".
    if (!completeName) learnerNames[0] = "Default Learner";
    /// Notify the widget of changes.
    _notifyDataChanged(learnerIds, learnerNames);
  }
  /// onChildAdded callback for learner data.
  void _learnerAdded(Event event) {
    /// Update learnerNames.
    learnerNames.add(createName(event.snapshot.value));
    /// Notify the widget.
    _notifyDataChanged(learnerIds, learnerNames);
  }
  /// onChildChanged callback.
  void _learnerChanged(Event event) {
    /// Update learnerNames.
    int learnerIndex = learnerIds.indexOf(event.snapshot.key)+1;
    learnerNames[learnerIndex] = createName(event.snapshot.value);
    /// Notify the widget.
    _notifyDataChanged(learnerIds, learnerNames);
  }
  /// onChildRemoved callback.
  void _learnerRemoved(Event event) {
    /// Delete name from learnerNames.
    int learnerIndex = learnerIds.indexOf(event.snapshot.key)+1;
    learnerNames.removeAt(learnerIndex);
    /// Notify the widget.
    _notifyDataChanged(learnerIds, learnerNames);
  }

  /// Initialize all of the Firebase References, the SafeFirebaseList,
  /// and the callback
  LearnerModel({@required DatabaseReference userRef, @required void Function(List<String>, List<String>) callback})
    : _defaultLeanerRef = userRef?.child("name"),
      _learnersRef = userRef?.child("learners"),
      _notifyDataChanged = callback {
    _learnerList = new SafeFirebaseList(
      completeCallback: hasCompleteName,
      addedCallback: _learnerAdded,
      changedCallback: _learnerChanged,
      removedCallback: _learnerRemoved
    );
  }

  /// Start subscriptions to _defaultLearnerRef, _learnersRef.
  void startSubscriptions() {
    _defaultLearnerSubscription = _defaultLeanerRef.onValue.listen(_defaultLearnerChanged);
    _learnerList.startSubscriptions(_learnersRef);
  }
  /// Cancel subscriptions.
  Future<void> cancelSubscriptions() async {
    await _learnerList.cancelSubscriptions();
    await _defaultLearnerSubscription?.cancel();
    /// Reset learnerNames.
    learnerNames = <String>["Default Learner"];
  }
}