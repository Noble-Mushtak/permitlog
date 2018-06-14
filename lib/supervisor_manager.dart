import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/safefirebaselist.dart';

/// Class that manages subscriptions and data related to supervisors.
class SupervisorManager {
  /// Object that holds list of keys to supervisor data
  /// and safe listeners for managing the supervisor data.
  SafeFirebaseList _supervisorList;
  /// List of supervisor names.
  List<String> supervisorNames;
  /// List of supervisor data.
  List<Map> supervisorData;

  /// Checks if supervisor data has a complete name.
  bool hasCompleteName(dynamic supervisorData) {
    /// If this is a Map, check if the "first" and "last" keys are present.
    if (supervisorData is Map) {
      return supervisorData.containsKey("first") && supervisorData.containsKey("last");
    }
    /// Otherwise, just return false.
    else return false;
  }
  /// Generates name for a supervisor based off the Map containing its data.
  String createSupervisorName(Map supervisorData) {
    return supervisorData["name"]["first"]+" "+supervisorData["name"]["last"];
  }
  /// Callback provided by constructor in order to notify widget of data changes
  void Function() _notifyDataChanged;

  /// DatabaseReference to supervisor data
  DatabaseReference supervisorRef;
  /// This is the onChildAdded subscription and callback for the supervisors data.
  StreamSubscription<Event> _addedSubscription;
  void _supervisorAdded(Event event) {
    /// If supervisorData is empty, then supervisorNames likely has "No supervisors"
    /// so get rid of that.
    if (supervisorData.isEmpty) supervisorNames.clear();
    /// Add supervisor data to supervisorNames and supervisorData.
    supervisorNames.add(createSupervisorName(event.snapshot.value));
    supervisorData.add(event.snapshot.value);
    /// Notify the widget.
    _notifyDataChanged();
  }
  /// This is the onChildChanged subscription and callback.
  StreamSubscription<Event> _changedSubscription;
  void _supervisorChanged(Event event) {
    /// Get the index of the item changed.
    int supervisorIndex = _supervisorList.keys.indexOf(event.snapshot.key);
    /// Update supervisorNames, supervisorData.
    supervisorNames[supervisorIndex] = createSupervisorName(event.snapshot.value));
    supervisorData[supervisorIndex] = event.snapshot.value;
    /// Notify the widget.
    _notifyDataChanged();
  }
  /// This is the onChildRemoved subscription and callback.
  StreamSubscription<Event> _removedSubscription;
  void _supervisorRemoved(Event event) {
    /// Get the index of the item changed.
    int supervisorIndex = _supervisorList.keys.indexOf(event.snapshot.key);
    /// Update supervisorNames, supervisorData.
    supervisorNames.removeAt(supervisorIndex);
    supervisorData.removeAt(supervisorIndex);
    /// Add "No supervisors" if supervisorNames is empty.
    if (supervisorNames.isEmpty) supervisorNames.add("No supervisors");
    /// Notify the widget.
    _notifyDataChanged();
  }

  SupervisorManager({@required DatabaseReference userRef, @required void Function() callback})
    : supervisorRef = userRef.child("drivers"),
      _notifyDataChanged = callback {
    
  }
}