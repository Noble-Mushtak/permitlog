import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/supervisor_manager.dart';

/// View that serves as the home screen for the PermitLog app. Displays
/// the current drive timer and totals for the user's goals.
class HomeView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Firebase User Object
  FirebaseUser _curUser;
  /// Reference to all of the user's data.
  DatabaseReference _userRef;
  /// Object that holds all of the user's goals.
  DrivingTimes _userGoals = new DrivingTimes();
  /// Subscription that listens for changes to user's goal data.
  StreamSubscription<Event> _goalSubscription;
  /// Object that manages all of the supervisor data.
  SupervisorManager _supervisorManager;
  /// Index of selected supervisor.
  int _supervisorIndex = 0;

  /// Callback for when user is updated.
  Future<void> _updateUser(FirebaseUser user) async {
    /// When the user changes, stop all subscriptions:
    await _goalSubscription?.cancel();
    await _supervisorManager?.cancelSubscriptions();
    setState(() {
      /// Update _curUser.
      _curUser = user;
      /// If _curUser is null, then _userRef is null.
      if (_curUser == null) _userRef = null;
      /// Otherwise, if we know who the user is, update _userRef:
      else {
        _userRef = _data.reference().child(_curUser.uid);
        /// Also, start the subscriptions.
        _goalSubscription = _userRef?.child("goals")?.onValue?.listen(_goalsListener);
        _supervisorManager = new SupervisorManager(userRef: _userRef, callback: () {
          /// Invoke setState since _supervisorManager has changed.
          setState(() {});
        });
        _supervisorManager.startSubscriptions();
      }
    });
  }
  /// Callback for when new data about the goals come in.
  void _goalsListener(Event event) {
    /// Encapsulate this in setState because it updates _userGoals.
    setState(() {
      /// Get the data and go through every type of goal.
      /// (If the user has not set goals yet, use an empty Map.)
      Map data = event.snapshot.value ?? new Map();
      for (String type in DrivingTimes.TIME_TYPES) {
        /// If the user has this goal, update _userGoals.
        if (data.containsKey(type)) _userGoals.setTime(type, data[type]);
        /// Otherwise, set the goal to 0.
        else _userGoals.setTime(type, 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Subscribe to changes to authentication if we haven't already:
    if (_authSubscription == null) {
      _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    }

    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    /// Only enable the start button if we know who the user is:
    VoidCallback startCallback;
    if (_curUser != null) {
      startCallback = () {};
    }

    /// Array holding all Text objects for the different goals the user has.
    List<Widget> goalTextObjs = <Widget>[
      new Text("Time Completed", style: textTheme.headline)
    ];
    /// Numerical format for goals.
    final NumberFormat goalFormat = new NumberFormat("00");
    /// Loop through the goal types.
    for (String type in DrivingTimes.TIME_TYPES) {
      /// If the user has this goal:
      if (_userGoals.getTime(type) > 0) {
        /// Capitalize the goal type:
        String typeCapitalized = type[0].toUpperCase()+type.substring(1);
        /// Add this goal to goalTextObjs.
        goalTextObjs.add(new Text(typeCapitalized+": 00:00/"+goalFormat.format(_userGoals.getTime(type))+":00", style: textTheme.headline));
      }
    }

    /// List of items for each supervisor.
    List<DropdownMenuItem<num>> supervisorItems = <DropdownMenuItem<num>>[];
    /// If the supervisor manager has not started yet, just state "No supervisors".
    if (_supervisorManager == null) supervisorItems = <DropdownMenuItem<num>>[
      new DropdownMenuItem<num>(value: 0, child: new Text("No supervisors"))
    ];
    /// Otherwise, make an item for each supervisor.
    else {
      for (int i = 0; i < _supervisorManager.supervisorNames.length; i++) {
        String supervisorName = _supervisorManager.supervisorNames[i];
        supervisorItems.add(
          new DropdownMenuItem<num>(value: i, child: new Text(supervisorName))
        );
      }
      /// Also, make sure _supervisorIndex is a valid index.
      _supervisorIndex = min(
          _supervisorIndex,
          _supervisorManager.supervisorNames.length-1
      );
    }

    return new SingleChildScrollView(
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Card(
                  child: new Column(
                      children: <Widget>[
                        new Text("00:00:00", textAlign: TextAlign.center, style: textTheme.headline),
                        new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new RaisedButton(
                                  onPressed: startCallback,
                                  child: new Text("Start Drive"),
                                  color: Theme.of(context).buttonColor
                              ),
                              new RaisedButton(
                                  onPressed: null,
                                  child: new Text("Stop Drive"),
                                  color: Theme.of(context).buttonColor
                              )
                            ]
                        ),
                        new DropdownButton<num>(
                            value: _supervisorIndex,
                            items: supervisorItems,
                            /// When user selects supervisor,
                            /// update _supervisorIndex.
                            onChanged: (num index) {
                              setState(() { _supervisorIndex = index; });
                            }
                        )
                      ]
                  )
              ),
              new Card(
                  child: new Column(
                    children: goalTextObjs,
                  )
              )
            ]
        )
      );
  }

  /// When we are done with this widget, cancel the subscriptions.
  @override
  void dispose() {
    _authSubscription.cancel();
    _goalSubscription?.cancel();
    _supervisorManager?.cancelSubscriptions();
    super.dispose();
  }
}