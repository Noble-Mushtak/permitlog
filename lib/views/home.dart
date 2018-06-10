import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/drivingtimes.dart';

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
  /// Subscription that listens for changes to authentication:
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Firebase User Object
  FirebaseUser _curUser;
  /// Reference to all of the user's data:
  DatabaseReference _userRef;
  /// Object that holds all of the user's goals:
  DrivingTimes _userGoals = new DrivingTimes();
  /// Subscription that listens for changes to user's goal data:
  StreamSubscription<Event> _goalSubscription;

  /// This method is called whenever new data about the goals come in.
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
      _authSubscription = _auth.onAuthStateChanged.listen(
        /// Update _curUser according to the subscription:
        (FirebaseUser user) => setState(() {
          _curUser = user;
          /// When the user changes, reset all listeners:
          _goalSubscription?.cancel();
          _goalSubscription = null;
        })
      );
    }

    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    /// Only enable the start button if we know who the user is:
    VoidCallback startCallback;
    if (_curUser != null) {
      startCallback = () {};
      /// Also, if we know who the user is, update _userRef:
      _userRef = _data.reference().child(_curUser.uid);
    }
    /// Otherwise, if we don't know who the user is, reset _userRef;
    else {
      _userRef = null;
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
    /// Listen to changes in the user's goal data if there is no subscription yet:
    if (_goalSubscription == null) {
      _goalSubscription = _userRef?.child("goals")?.onValue?.listen(_goalsListener);
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
                            value: -1,
                            items: [new DropdownMenuItem<num>(value: -1, child: new Text("Select a Driver"))],
                            onChanged: (num index) {}
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
    super.dispose();
  }
}