import 'package:flutter/material.dart';

/// View that allows the user to change their goals.
class GoalsView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Text("Put some goals"),
    );
  }
}