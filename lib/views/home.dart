import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// View that serves as the home screen for the PermitLog app. Displays
/// the current drive timer and totals for the user's goals.
class HomeView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Firebase Auth API Interface
  final FirebaseAuth _auth = FirebaseAuth.instance;
  /// Subscription that listens for changes to authentication:
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Firebase User Object
  FirebaseUser _curUser;

  @override
  Widget build(BuildContext context) {
    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    /// Only enable the start button if we know who the user is:
    VoidCallback startCallback;
    if (_curUser != null) {
      startCallback = () {};
    }
    /// Subscribe to changes to authentication if we haven't already:
    if (_authSubscription == null) {
      _authSubscription = _auth.onAuthStateChanged.listen((FirebaseUser user) =>
          /// Update _curUser according to the subscription:
          setState(() {
            _curUser = user;
          }));
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
                    children: <Widget>[
                      new Text("Time Completed", style: textTheme.headline),
                      new Text("Total: 00:00/00:00", style: textTheme.headline),
                      new Text("Day: 00:00/00:00", style: textTheme.headline),
                      new Text("Night: 00:00/00:00", style: textTheme.headline),
                      new Text("Weather: 00:00/00:00", style: textTheme.headline),
                      new Text("Adverse: 00:00/00:00", style: textTheme.headline)
                    ],
                  )
              )
            ]
        )
      );
  }

  /// When we are done with this widget, cancel the auth subscription.
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}