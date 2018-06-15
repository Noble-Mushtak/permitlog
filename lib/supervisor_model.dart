import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/safe_firebase_list.dart';

/// Class that manages subscriptions and data related to supervisors.
class SupervisorModel {
  /// Object that holds list of keys to supervisor data
  /// and safe listeners for managing the supervisor data.
  SafeFirebaseList _supervisorList;
  /// List of supervisor keys.
  List<String> get supervisorIds => _supervisorList.keys;
  /// List of supervisor names.
  List<String> supervisorNames = <String>["No supervisors"];
  /// List of supervisor data.
  Map<String, Map> supervisorData = <String, Map>{};
  /// Callback provided by constructor in order to notify widget of data changes.
  void Function(List<String>, List<String>, Map<String, Map>) _notifyDataChanged;

  /// Checks if supervisor data has a complete name.
  static bool hasCompleteName(dynamic supervisorData) {
    /// If this is a Map and supervisorData["name"] is a Map,
    /// then check if the "first" and "last" keys are present.
    if (supervisorData is Map && (supervisorData["name"] is Map)) {
      return supervisorData["name"].containsKey("first")
          && supervisorData["name"].containsKey("last");
    }
    /// Otherwise, just return false.
    else return false;
  }
  /// Generates name for a supervisor based off the Map containing its data.
  static String createSupervisorName(Map supervisorData) {
    return supervisorData["name"]["first"]+" "+supervisorData["name"]["last"];
  }

  /// DatabaseReference to supervisor data.
  DatabaseReference _supervisorRef;
  /// onChildAdded callback for supervisors data.
  void _supervisorAdded(Event event) {
    /// If supervisorData is empty, then supervisorNames likely has "No supervisors"
    /// so get rid of that.
    if (supervisorData.isEmpty) supervisorNames.clear();
    /// Add supervisor data to supervisorNames and supervisorData.
    supervisorNames.add(createSupervisorName(event.snapshot.value));
    supervisorData[event.snapshot.key] = event.snapshot.value;
    /// Notify the widget.
    _notifyDataChanged(supervisorIds, supervisorNames, supervisorData);
  }
  /// onChildChanged callback.
  void _supervisorChanged(Event event) {
    /// Get the index of the item changed.
    int supervisorIndex = _supervisorList.keys.indexOf(event.snapshot.key);
    /// Update supervisorNames, supervisorData.
    supervisorNames[supervisorIndex] = createSupervisorName(event.snapshot.value);
    supervisorData[event.snapshot.key] = event.snapshot.value;
    /// Notify the widget.
    _notifyDataChanged(supervisorIds, supervisorNames, supervisorData);
  }
  /// onChildRemoved callback.
  void _supervisorRemoved(Event event) {
    /// Get the index of the item changed.
    int supervisorIndex = _supervisorList.keys.indexOf(event.snapshot.key);
    /// Update supervisorNames, supervisorData.
    supervisorNames.removeAt(supervisorIndex);
    supervisorData.remove(event.snapshot.key);
    /// Add "No supervisors" if supervisorNames is empty.
    if (supervisorNames.isEmpty) supervisorNames.add("No supervisors");
    /// Notify the widget.
    _notifyDataChanged(supervisorIds, supervisorNames, supervisorData);
  }

  /// Constructor which initializes instance variables
  SupervisorModel({@required DatabaseReference userRef, @required void Function(List<String>, List<String>, Map<String, Map>) callback})
    : _supervisorRef = userRef?.child("drivers"),
      _notifyDataChanged = callback {
    /// Instantiate the safe Firebase list.
    _supervisorList = new SafeFirebaseList(
        completeCallback: hasCompleteName,
        addedCallback: _supervisorAdded,
        changedCallback: _supervisorChanged,
        removedCallback: _supervisorRemoved
    );
  }

  /// Starts subscriptions to _supervisorRef.
  void startSubscriptions() {
    _supervisorList.startSubscriptions(_supervisorRef);
  }
  /// Cancels subscriptions to _supervisorRef.
  Future<void> cancelSubscriptions() async {
    /// Cancel all subscriptions.
    await _supervisorList.cancelSubscriptions();
    /// Clear all the data.
    supervisorNames.clear();
    supervisorData.clear();
    /// Add a default placeholder for the name.
    supervisorNames.add("No supervisors");
  }
}