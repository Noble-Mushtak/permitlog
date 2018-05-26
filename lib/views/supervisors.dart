import 'package:flutter/material.dart';

/// View to that lists supervising drivers.
class SupervisorsView extends StatelessWidget {
  /// Show a list of supervising drivers.
  @override
  Widget build(BuildContext context) {
    return new ListView(
      shrinkWrap: true,
      padding: new EdgeInsets.all(8.0),
      children: <Widget>[
        new ListTile(
          title: new Text("TODO"),
        ),
        new ListTile(
          title: new Text("Grab data from Firebase."),
        ),
      ],
    );
  }
}