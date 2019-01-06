import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/safe_firebase_list.dart';
import 'package:permitlog/utilities.dart';

/// Represents the data and subscriptions related to learner information
/// stored in the Firebase real-time database.
class LearnerModel {
  /// References to learner data in Firebase.
  DatabaseReference _defaultLeanerRef;
  DatabaseReference _learnersRef;

  /// Subscription that listens for changes in default learner's name.
  StreamSubscription<Event> _defaultLearnerSubscription;

  /// Object that holds keys and listeners for learner data.
  /// *Note:* Does not contain key for default learner.
  SafeFirebaseList _learnerList;

  /// List of learner names.
  List<String> learnerNames = <String>["Default Learner"];

  /// Callback used to notify widget of data changes.
  void Function(List<String>, List<String>) _notifyDataChanged;

  /// Constructs a `LearnerModel` from the given user data, represented by
  /// [userRef], and a [callback] to get notified about changes to learner data.
  LearnerModel(
      {@required DatabaseReference userRef,
      @required void Function(List<String>, List<String>) callback})
      : _defaultLeanerRef = userRef?.child("name"),
        _learnersRef = userRef?.child("learners"),
        _notifyDataChanged = callback {
    _learnerList = SafeFirebaseList(
        completeCallback: hasCompleteName,
        addedCallback: _learnerAdded,
        changedCallback: _learnerChanged,
        removedCallback: _learnerRemoved);
  }

  /// Gets a list of learner IDs/keys.
  List<String> get learnerIds => _learnerList.keys;

  /// Starts listening for changes to learners' data.
  void startSubscriptions() {
    _defaultLearnerSubscription =
        _defaultLeanerRef.onValue.listen(_defaultLearnerChanged);
    _learnerList.startSubscriptions(_learnersRef);
  }

  /// Cancels all learner-related subscriptions and resets [learnerNames].
  Future<void> cancelSubscriptions() async {
    await _learnerList.cancelSubscriptions();
    await _defaultLearnerSubscription?.cancel();
    learnerNames = <String>["Default Learner"];
  }

  /// Handles when the user's name is changed (aka the name of the default
  /// learner). If the new data has a complete name, update [learnerNames] to
  /// have the new name and notify with the [_notifyDataChanged] callback.
  /// Otherwise, just use "Default Learner" as the name. This is the [onValue]
  /// callback set when subscriptions are started by [startSubscriptions].
  void _defaultLearnerChanged(Event event) {
    var completeName = false;
    if (event.snapshot.value is Map) {
      Map name = event.snapshot.value;
      if (name.containsKey("first") && name.containsKey("last")) {
        learnerNames[0] = name["first"] + " " + name["last"];
        completeName = true;
      }
    }
    if (!completeName) learnerNames[0] = "Default Learner";
    _notifyDataChanged(learnerIds, learnerNames);
  }

  /// Handles when a learner is added by adding them to [learnerNames] and
  /// notifying client widget via the [_notifyDataChanged] callback. This is
  /// the [addedCallback] for the [SafeFirebaseList] initialized in the
  /// constructor.
  void _learnerAdded(Event event) {
    learnerNames.add(createName(event.snapshot.value));
    _notifyDataChanged(learnerIds, learnerNames);
  }

  /// Handles when a learner's information is changed by updating the
  /// [learnerNames] list and notifying client widget via the
  /// [_notifyDataChanged] callback. This is the [changedCallback] for the
  /// [SafeFirebaseList] initialized in the constructor.
  void _learnerChanged(Event event) {
    int learnerIndex = learnerIds.indexOf(event.snapshot.key) + 1;
    learnerNames[learnerIndex] = createName(event.snapshot.value);
    _notifyDataChanged(learnerIds, learnerNames);
  }

  /// Handles when a learner is removed by deleting them from [learnerNames]
  /// and notifying client widget via the [_notifyDataChanged] callback. This
  /// is the [removedCallback] for the [SafeFirebaseList] initialized in the
  /// constructor.
  void _learnerRemoved(Event event) {
    int learnerIndex = learnerIds.indexOf(event.snapshot.key) + 1;
    learnerNames.removeAt(learnerIndex);
    _notifyDataChanged(learnerIds, learnerNames);
  }
}
