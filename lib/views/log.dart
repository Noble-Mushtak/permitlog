import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/log_model.dart';

/// View to that lists previously logged drives.
class LogView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _LogViewState();
}

class _LogViewState extends State<LogView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Model that manages log data.
  LogModel _logModel;
  /// List of summaries for logs.
  List<String> _logSummaries;

  Future<void> _updateUser(FirebaseUser user) async {
    /// Cancel any pending subscriptions.
    await _logModel.cancelSubscriptions();
    setState(() {
      if (user != null) {
        /// Update _logModel for new user.
        DatabaseReference userRef = _data.reference().child(user.uid);
        _logModel = new LogModel(
          userRef: userRef,
          callback: (List<String> logIds, List<String> logSummaries, DrivingTimes timeElapsed, Map<String, Map> logData) {
            /// Update _logSummaries.
            setState(() { _logSummaries = logSummaries; });
          }
        );
        /// Start listening to log data.
        _logModel.startSubscriptions();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize _logModel and _logSummaries.
    _logModel = new LogModel(userRef: null, callback: null);
    _logSummaries = _logModel.logSummaries;
  }

  /// Show a list of drives logged.
  @override
  Widget build(BuildContext context) {
    return new ListView(
      shrinkWrap: true,
      padding: new EdgeInsets.all(8.0),
      children: _logSummaries.map(
        (String summary) => new ListTile(title: new Text(summary))
      ).toList()
    );
  }

  /// When we are done with this widget, cancel the subscriptions.
  @override
  void dispose() {
    _authSubscription.cancel();
    _logModel.cancelSubscriptions();
    super.dispose();
  }
}