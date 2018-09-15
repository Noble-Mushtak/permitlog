import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permitlog/learner_model.dart';
import 'package:permitlog/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// View that lists the different learners.
class LearnersView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _LearnersViewState();
}

class _LearnersViewState extends State<LearnersView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Object used to edit local preferences.
  SharedPreferences _prefs;
  /// Model for learner data.
  LearnerModel _learnerModel;
  /// List of learner IDs and names.
  List<String> _learnerIds, _learnerNames;

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize learner variables.
    _learnerModel = new LearnerModel(userRef: null, callback: null);
    _learnerIds = _learnerModel.learnerIds;
    _learnerNames = _learnerModel.learnerNames;
  }

  /// Callback for when auth state changes.
  Future<void> _updateUser(FirebaseUser user) async {
    await _learnerModel.cancelSubscriptions();
    /// Initialize _prefs if necessary.
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    setState(() {
      if (user != null) {
        /// If user is non-null, update _learnerModel.
        DatabaseReference userRef = _data.reference().child(user.uid);
        _learnerModel = new LearnerModel(
          userRef: userRef,
          callback: (List<String> ids, List<String> names) {
            /// Call setState() after updating learner variables.
            setState(() {
              _learnerIds = ids;
              _learnerNames = names;
            });
          }
        );
        /// Start listening for data from Firebase.
        _learnerModel.startSubscriptions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Get key of the current learner.
    String currentLearnerKey = _prefs?.getString("current_learner") ?? "";
    /// Convert _learnerNames into a list of Rows with ListTiles
    List<Widget> learnerTiles = [];
    for (int i = 0; i < _learnerNames.length; i++) {
      /// Get the learner id associated with this learner.
      /// (Empty for default learner).
      String learnerId = "";
      if (i > 0) learnerId = _learnerIds[i-1];
      /// Make the background color green if this is the currently
      /// selected learner.
      BoxDecoration backgroundColor;
      if (currentLearnerKey == learnerId) {
        backgroundColor = new BoxDecoration(
          color: Colors.blueGrey
        );
      }

      learnerTiles.add(new Container(
        decoration: backgroundColor,
        child: new ListTile(
          title: new Text(_learnerNames[i]),
          /// Set this learner as currently selected when the name is tapped.
          onTap: () {
            setState(() { _prefs?.setString("current_learner", learnerId); });
          },
          trailing: new FlatButton(
            child: new Icon(Icons.edit, color: Colors.black),
            /// Edit this learner when the edit icon is tapped.
            onPressed: () {
              print("hello");
            }
          )
        )
      ));
    }

    return new ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(8.0),
      children: learnerTiles
    );
  }

  /// When we are done with this widget, cancel the subscriptions.
  @override
  void dispose() {
    _authSubscription.cancel();
    _learnerModel.cancelSubscriptions();
    super.dispose();
  }
}