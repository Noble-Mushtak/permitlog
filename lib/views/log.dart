import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permitlog/model/driving_times.dart';
import 'package:permitlog/model/log_model.dart';
import 'package:permitlog/views/add_log.dart';
import 'package:permitlog/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// Reference to all the user's data.
  DatabaseReference _userRef;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Object used to manage user preferences.
  SharedPreferences _prefs;
  /// Key for current learner (empty for default learner).
  String _currentLearnerKey;
  /// Model that manages log data.
  LogModel _logModel;
  /// List of IDs and summaries for logs.
  List<String> _logIds, _logSummaries;

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize log variables.
    _logModel = new LogModel(learnerRef: null, callback: null);
    _logIds = _logModel.logIds;
    _logSummaries = _logModel.logSummaries;
  }

  Future<void> _updateUser(FirebaseUser user) async {
    /// Cancel any pending subscriptions.
    await _logModel.cancelSubscriptions();
    /// Initialize _prefs if necessary.
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    setState(() {
      if (user != null) {
        /// Update _userRef for new user.
        _userRef = _data.reference().child(user.uid);
        /// Update _currentLearnerKey, _logModel.
        _currentLearnerKey = _prefs.getString("current_learner") ?? "";
        _logModel = new LogModel(
          learnerRef: getCurrentLearnerRef(_userRef, _currentLearnerKey),
          callback: (List<String> logIds, List<String> logSummaries, DrivingTimes timeElapsed, Map<String, Map> logData) {
            /// Update _logIds and _logSummaries.
            setState(() { _logIds = logIds; _logSummaries = logSummaries; });
          }
        );
        /// Start listening to log data.
        _logModel.startSubscriptions();
      }
    });
  }

  /// Show a list of drives logged.
  @override
  Widget build(BuildContext context) {
    /// Convert _logSummaries into a list of ListTiles.
    List<ListTile> logTiles = [];
    for (int i = 0; i < _logSummaries.length; i++) {
      /// Only add an edit button if this is a valid index of _logIds.
      Widget editButton;
      if (i < _logIds.length) {
        editButton = new ButtonTheme(
          minWidth: 60.0,
          child: new FlatButton(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: new Icon(Icons.edit, color: Colors.black),
            /// Edit this log when the user taps the pencil icon.
            onPressed: () {
              /// Create a route to AddLogView.
              MaterialPageRoute<String> route = MaterialPageRoute<String>(
                builder: (context) => new AddLogView(
                  logId: _logIds[i]
                )
              );
              /// When the view is done, show the resulting message.
              route.popped.then((String msg) => showNonEmptyMessage(context, msg));
              /// Navigate to the route
              Navigator.push(context, route);
            }
          )
        );
      }

      logTiles.add(new ListTile(
        title: new Text(_logSummaries[i]),
        trailing: editButton
      ));
    }

    return new ListView(
      shrinkWrap: true,
      padding: new EdgeInsets.all(8.0),
      children: logTiles
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