import 'package:flutter/material.dart';

/// Stateful version of CheckboxListTile
class StatefulCheckbox extends StatefulWidget {
  /// Properties to be passed onto State object.
  final String _title;
  final bool _initValue;
  final void Function(bool) _callback;
  /// Constructor that sets instance variables
  StatefulCheckbox({@required String title, @required bool value, @required void Function(bool) onChanged})
    : _title = title, _initValue = value, _callback = onChanged;

  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() =>
      new _StatefulCheckboxState(_title, _initValue, _callback);
}

class _StatefulCheckboxState extends State<StatefulCheckbox> {
  /// Title of CheckboxListTile.
  String _title;
  /// Value of Checkbox.
  bool _value;
  /// Callback for onChanged.
  void Function(bool) _onChanged;
  /// Constructor that sets instance variables
  _StatefulCheckboxState(String title, bool value, void Function(bool) callback)
    : _title = title, _value = value, _onChanged = callback;

  @override
  Widget build(BuildContext context) {
    return new CheckboxListTile(
      title: new Text(_title),
      value: _value,
      onChanged: (bool value) {
        /// Invoke the callback and update _value.
        _onChanged(value);
        setState(() { _value = value; });
      }
    );
  }
}