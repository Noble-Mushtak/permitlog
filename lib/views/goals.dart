import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permitlog/driving_times.dart';

/// View that allows the user to change their goals.
class GoalsView extends StatefulWidget {
  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  /// Key used to identify form
  GlobalKey<FormState> _formKey;
  /// Instructions for user.
  String _instructions = "Choose your state, or \"Custom\" to enter your own goals. You can edit your goals before you save them, and afterwards. Leave any goal you don't want to track blank.";
  /// Label texts for all the different textboxes.
  Map<String, String> _labelTexts = <String, String>{
    "total": "Total Hours Required",
    "day": "Day Hours",
    "night": "Night Hours",
    "weather": "Poor Weather Hours",
    "adverse": "Adverse Condition Hours"
  };
  /// Maps for finding controllers for each goal type.
  Map<String, TextEditingController> _textControllers = {};
  /// User's previous goals.
  DrivingTimes _userGoals = new DrivingTimes();
  /// This is the user's state.
  String _userState = "Custom";
  /// This is all of the info about all of the states.
  Map<String, dynamic> _stateData = <String, dynamic>{};
  /// This is the first option in the dropdown of states.
  static final String _fillerState = "Select a State";
  /// This is the state selected in the dropdown.
  String _stateSelected = _fillerState;

  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription for listening to changes in user.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Subscription for listening to changes in user's goals.
  StreamSubscription<Event> _goalSubscription;
  /// Reference to the user's Firebase data.
  DatabaseReference _userRef;

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication.
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// Initialize _formKey
    _formKey = new GlobalKey<FormState>();
  }

  /// Called when auth state changes.
  Future<void> _updateUser(FirebaseUser user) async {
    /// Cancel all subscriptions.
    await _goalSubscription?.cancel();
    setState(() {
      /// Reset the variables related to the user.
      _userRef = null;
      _goalSubscription = null;
      _userGoals = new DrivingTimes();
      _userState = "Custom";
      /// If the user is non-null, update _userRef.
      if (user != null) {
        _userRef = _data.reference().child(user.uid);
        /// Also, start the subscriptions.
        _goalSubscription = _userRef.child("goals").onValue.listen(_goalsListener);
      }
    });
  }

  /// Called when goal data comes in from Firebase.
  Future<void> _goalsListener(Event event) async {
    setState(() {
      /// Update _userGoals with the event.
      _userGoals.updateWithEvent(event);
      /// Update _userState as well, where Custom is the default state.
      Map goalData = event.snapshot.value ?? new Map();
      _userState = goalData["stateName"] ?? _fillerState;
      /// By default, select the user's current state.
      _stateSelected = _userState;
    });
  }

  /// Returns error message is val is not empty and is not int
  /// (Used in form validation)
  String _emptyOrInt(String val) {
    /// Don't check anything if val is empty
    if ((val == null) || val.isEmpty) return null;
    /// Return error message if tryParse() fails
    int valAsInt = int.tryParse(val);
    return (valAsInt == null) ? "All goals must be integer." : null;
  }

  /// Builds a TextFormField for a goal type based off the goal value.
  TextFormField _createField(String type, int goal) {
    /// If the user doesn't have this goal, then leave make the textbox empty.
    if (goal == 0) {
      _textControllers[type] = new TextEditingController();
      return new TextFormField(
        decoration: new InputDecoration(labelText: _labelTexts[type]),
        controller: _textControllers[type],
        keyboardType: TextInputType.number,
        validator: _emptyOrInt
      );
    }
    /// If the user does have this goal, put an initial value in the controller.
    else {
      _textControllers[type] = new TextEditingController.fromValue(
        new TextEditingValue(text: goal.toString())
      );
      return new TextFormField(
        decoration: new InputDecoration(labelText: _labelTexts[type]),
        controller: _textControllers[type],
        keyboardType: TextInputType.number,
        validator: _emptyOrInt
      );
    }
  }

  /// Called when user clicks save.
  void _saveGoals() {
    /// Don't do anything if the user is signed in
    /// or if they haven't selected a state.
    if (_userRef == null) return;
    /// Don't do anything if form validation fails
    if (!_formKey.currentState.validate()) return;

    if (!_stateData.containsKey(_stateSelected)) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Please select a state.")
      ));
      return;
    }
    /// Save the user's state and goals.
    DatabaseReference goalsRef = _userRef.child("goals");
    goalsRef.child("stateName").set(_stateSelected);
    for (String type in DrivingTimes.TIME_TYPES) {
      /// If the goal is not an integer for some reason, set it to 0.
      goalsRef.child(type).set(int.tryParse(_textControllers[type]?.text ?? "") ?? 0);
    }
    /// Show the user a success message.
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Goals successfully saved.")
    ));
  }

  /// Called in order to build widget with state data.
  Widget _innerBuild(BuildContext context, AsyncSnapshot<String> snapshot) {
    /// If the state data is available, parse it.
    if ((snapshot.connectionState == ConnectionState.done) && !snapshot.hasError) {
      JsonCodec json = new JsonCodec();
      _stateData = json.decode(snapshot.data);
    }
    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;

    /// List of all TextFormFields for goals.
    List<TextFormField> goalInputs = [];
    /// Only add goal inputs if a state has been selected.
    if (_stateData.containsKey(_stateSelected)) {
      for (String type in DrivingTimes.TIME_TYPES) {
        /// Get the goal of this type for this state.
        int goal = _stateData[_stateSelected][type];
        /// However, if this is the Custom state or the user's own state,
        /// then use the user's goal.
        if ((_stateSelected == "Custom") || (_stateSelected == _userState)) {
          goal = _userGoals.getTime(type);
        }
        /// If this goal is non-zero or if this is Custom state,
        /// then add a goal input for this state.
        if ((goal > 0) || (_stateSelected == "Custom")) {
          goalInputs.add(_createField(type, goal));
        }
        /// Otherwise, set the controller for this type to null
        /// to signify this field is not being shown.
        else _textControllers[type] = null;
      }
    }

    /// This is the dropdown of all the states:
    DropdownButton<String> stateDropdown;
    /// If there's no state data yet, then put Loading in the Dropdown button.
    if (_stateData.isEmpty) {
      stateDropdown = new DropdownButton<String>(
        value: "",
        items: [new DropdownMenuItem<String>(value: "", child: new Text("Loading..."))],
        onChanged: (String _) {}
      );
    }
    /// If there is state data, put all of the states in a dropdown button.
    else {
      /// Create a DropdownMenuItem for each state.
      List<DropdownMenuItem<String>> stateItems = [
        /// Add an item for the filler state.
        new DropdownMenuItem<String>(
          value: _fillerState, child: new Text(_fillerState)
        )
      ];
      for (String state in _stateData.keys) {
        stateItems.add(new DropdownMenuItem<String>(
          value: state, child: new Text(state)
        ));
      }
      /// Create the DropdownButton with all the states.
      stateDropdown = new DropdownButton<String>(
        value: _stateSelected,
        items: stateItems,
        /// Update _stateSelected when user picks a new state.
        onChanged: (String state) { setState(() { _stateSelected = state; }); }
      );
    }

    return new Form(
      key: _formKey,
      child: new SingleChildScrollView(
        child: new Padding(
          padding: new EdgeInsets.all(8.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Text(_instructions, style: textTheme.body1),
              stateDropdown
            ]
            /// Add all of the goal inputs.
            +goalInputs
            +<Widget>[
              new RaisedButton(
                onPressed: _saveGoals,
                child: new Text("Save"),
                color: Theme.of(context).buttonColor
              )
            ]
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Build the widget using the data from states.json.
    return new FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString("assets/states.json"),
      builder: _innerBuild
    );
  }

  @override
  void dispose() {
    /// Cancel any subscriptions.
    _authSubscription.cancel();
    _goalSubscription?.cancel();
    super.dispose();
  }
}