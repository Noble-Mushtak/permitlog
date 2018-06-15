import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permitlog/supervisor_model.dart';

/// View to that lists supervising drivers.
class SupervisorsView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _SupervisorsViewState();
}

class _SupervisorsViewState extends State<SupervisorsView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Model for supervisor data.
  SupervisorModel _supervisorModel;
  /// List of supervisor names.
  List<String> _supervisorNames;

  /// Callback for when auth state changes.
  Future<void> _updateUser(FirebaseUser user) async {
    /// Cancel any pending subscriptions.
    await _supervisorModel.cancelSubscriptions();
    setState(() {
      if (user != null) {
        /// If user is non-null, update _supervisorModel.
        DatabaseReference userRef = _data.reference().child(user.uid);
        _supervisorModel = new SupervisorModel(
          userRef: userRef,
          callback: (List<String> ids, List<String> names, Map<String, Map> data) {
            /// Call setState after updating _supervisorNames.
            setState(() { _supervisorNames = names; });
          }
        );
        /// Start listening for data from Firebase.
        _supervisorModel.startSubscriptions();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize _supervisorModel and _supervisorNames.
    _supervisorModel = new SupervisorModel(userRef: null, callback: null);
    _supervisorNames = _supervisorModel.supervisorNames;
  }

  /// Show a list of supervising drivers.
  @override
  Widget build(BuildContext context) {
    return new ListView(
      shrinkWrap: true,
      padding: new EdgeInsets.all(8.0),
      /// Convert _supervisorNames into a list of ListTiles.
      children: _supervisorNames.map(
        (String name) => new ListTile(title: new Text(name))
      ).toList()
    );
  }

  /// When we are done with this widget, cancel the subscriptions.
  @override
  void dispose() {
    _authSubscription.cancel();
    _supervisorModel.cancelSubscriptions();
    super.dispose();
  }
}