import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/log_model.dart';
import 'package:permitlog/views/stateful_checkbox.dart';
import 'package:permitlog/supervisor_model.dart';
import 'package:permitlog/utilities.dart';

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
  /// Object that holds time the user has completed in each category.
  /// These times are stored in milliseconds.
  DrivingTimes _userTimes = new DrivingTimes();
  /// Object that holds all of the user's goals.
  /// These times are stored in hours.
  DrivingTimes _userGoals = new DrivingTimes();
  /// Subscription that listens for changes to user's goal data.
  StreamSubscription<Event> _goalSubscription;
  /// Model that manages all of the supervisor data.
  SupervisorModel _supervisorModel;
  /// Model that calculates the time the user has driven in each category.
  LogModel _logModel;
  /// List of all the supervisor names.
  List<String> _supervisorNames;

  /// Index of selected supervisor.
  int _supervisorIndex = 0;
  /// Boolean describing if there is an ongoing drive.
  bool _ongoingDrive = false;
  /// Reference to the user's ongoing drive.
  DatabaseReference _ongoingRef;
  /// Objects that store starting and ending time of ongoing drive.
  DateTime _startingTime, _endingTime;
  /// Duration of time from _startingTime to now.
  Duration _ongoingDuration;
  /// Timer that updates ongoing drive time.
  Timer _ongoingTimer;

  /// Tells user to add supervisor.
  void _supervisorWarning() {
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Please add the supervisor accompanying you by tapping the plus sign in the bottom right, and tapping \"Add Supervisor\""),
        duration: new Duration(seconds: 5),
    ));
  }
  /// Callback for when user is updated.
  Future<void> _updateUser(FirebaseUser user) async {
    /// When the user changes, stop all subscriptions:
    await _goalSubscription?.cancel();
    await _supervisorModel.cancelSubscriptions();
    await _logModel.cancelSubscriptions();
    /// Reset any variables related to Firebase data.
    _ongoingDrive = false;
    setState(() {
      /// Update _curUser.
      _curUser = user;
      /// If _curUser is null, then _userRef is null.
      if (_curUser == null) _userRef = null;
      /// Otherwise, if we know who the user is, update _userRef:
      else {
        _userRef = _data.reference().child(_curUser.uid);
        /// Update any other DatabaseReferences.
        _ongoingRef = _userRef.child("ongoing");
        /// Also, start the subscriptions.
        _goalSubscription = _userRef.child("goals").onValue.listen(_goalsListener);
        _supervisorModel = new SupervisorModel(
          userRef: _userRef,
          callback: (List<String> ids, List<String> names, Map<String, Map> data) {
            /// Invoke setState since _supervisorNames has changed.
            setState(() { _supervisorNames = names; });
          }
        );
        _supervisorModel.startSubscriptions();
        _logModel = new LogModel(
          userRef: _userRef,
          callback: (List<String> logIds, List<String> logSummaries, DrivingTimes timesData, Map<String, Map> logData) {
            /// Invoke setState since _userTimes has changed.
            setState(() { _userTimes = timesData; });
          }
        );
        _logModel.startSubscriptions();
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
  /// Callback for when user clicks "Start Drive".
  void _startDrive() {
    /// If there are no supervisors, tell the user to add a supervisor.
    if (_supervisorModel.supervisorData.isEmpty) {
      _supervisorWarning();
      return;
    }
    /// Otherwise, start the ongoing drive.
    else {
      setState(() {
        _ongoingDrive = true;
        /// Set the _startingTime and save it in Firebase.
        _startingTime = new DateTime.now();
        _ongoingRef.child("start").set(_startingTime.millisecondsSinceEpoch);
        /// Initialize _ongoingDuration.
        _ongoingDuration = new Duration(seconds: 0);
        /// Start the timer.
        _ongoingTimer = new Timer.periodic(new Duration(seconds: 1), _updateOngoing);
      });
    }
  }
  /// Callback for _ongoingTimer.
  void _updateOngoing(Timer timer) {
    setState(() {
      /// Find the duration between _startingTime and now.
      _ongoingDuration = (new DateTime.now()).difference(_startingTime);
    });
  }
  /// Callback for when user clicks "Stop Drive".
  void _stopDrive() {
    setState(() {
      /// Cancel the timer and stop the ongoing drive.
      _ongoingTimer.cancel();
      _ongoingDrive = false;
    });
    /// If there are no supervisors, tell the user to add a supervisor.
    if (_supervisorModel.supervisorData.isEmpty) {
      _supervisorWarning();
      return;
    }
    /// Save the supervisor ID in Firebase.
    String supervisorId = _supervisorModel.supervisorIds[_supervisorIndex];
    _ongoingRef.child("driver_id").set(supervisorId);
    /// Save the stop time in Firebase.
    _endingTime = new DateTime.now();
    _ongoingRef.child("end").set(_endingTime.millisecondsSinceEpoch);
    /// Show dialog about drive so user can save drive.
    _showDialog(supervisorId);
  }
  /// Shows dialog allowing user to put drive into categories.
  void _showDialog(String supervisorId) {
    /// This is a list of Booleans representing the drive's categories.
    /// driveCategories[0] is true iff this drive was during night.
    /// driveCategories[1] is for poor weather, 2 for adverse conditions.
    List<bool> driveCategories = <bool>[false, false, false];
    /// This function returns a CheckboxListTile that toggles
    /// an element of driveCategories.
    StatefulCheckbox createCheckbox(String title, int index) {
      return new StatefulCheckbox(
        title: title,
        value: false,
        onChanged: (bool value) { driveCategories[index] = value; }
      );
    }
    /// Create a list of checkboxes to show the users.
    List<StatefulCheckbox> categoryCheckboxes = [];
    /// Add checkboxes for night, poor weather, adverse conditions
    /// if the user has goals for such categories.
    if ((_userGoals.getTime("day") > 0) || (_userGoals.getTime("night") > 0)) {
      categoryCheckboxes.add(createCheckbox("Night", 0));
    }
    if (_userGoals.getTime("weather") > 0) {
      categoryCheckboxes.add(createCheckbox("Poor Weather", 1));
    }
    if (_userGoals.getTime("adverse") > 0) {
      categoryCheckboxes.add(createCheckbox("Adverse Conditions", 2));
    }
    /// If none of the categories applied, then just save the drive already.
    if (categoryCheckboxes.isEmpty) _saveDrive(driveCategories, supervisorId);
    /// Otherwise, show the user a dialog
    /// so they can choose which categories apply here.
    else {
      /// For the dialog's content, prepend the checkboxes with some text.
      List<Widget> content = <Widget>[new Text("Select all that apply.")];
      content += categoryCheckboxes;
      /// Now, show the dialog.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext innerContext) => new AlertDialog(
          content: new Column(mainAxisSize: MainAxisSize.min, children: content),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              /// Delete the ongoing drive and show the user a failure message
              /// if the user clicks cancel.
              onPressed: () {
                _ongoingRef.remove();
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text("Drive cancelled.")
                ));
                Navigator.pop(innerContext);
              },
            ),
            new FlatButton(
              child: new Text("Save"),
              onPressed: () {
                _saveDrive(driveCategories, supervisorId);
                Navigator.pop(innerContext);
              }
            )
          ]
        )
      );
    }
  }
  /// Saves drive with _startingTime and _endingTime.
  void _saveDrive(List<bool> categories, String supervisorId) {
    /// Delete the ongoing drive since the drive has finished.
    _ongoingRef.remove();
    /// Set endingTime so the difference in times is exact in minutes.
    _ongoingDuration = _endingTime.difference(_startingTime);
    int msDifference = _ongoingDuration.inMicroseconds % Duration.microsecondsPerMinute;
    _endingTime = _endingTime.subtract(new Duration(microseconds: msDifference));
    /// Save the drive in the database.
    DatabaseReference driveRef = _userRef.child("times").push();
    driveRef.set(<String, dynamic>{
      "start": _startingTime.millisecondsSinceEpoch,
      "end": _endingTime.millisecondsSinceEpoch,
      "night": categories[0],
      "weather": categories[1],
      "adverse": categories[2],
      "driver_id": supervisorId
    });
    /// Show the user a success message.
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Drive successfully saved."),
    ));
  }

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize _supervisorModel and _supervisorNames.
    _supervisorModel = new SupervisorModel(userRef: null, callback: null);
    _supervisorNames = _supervisorModel.supervisorNames;
    /// Also, initialize _logModel.
    _logModel = new LogModel(userRef: null, callback: null);
  }

  @override
  Widget build(BuildContext context) {
    /// Numerical format for two-digit number..
    final NumberFormat twoDigitFormat = new NumberFormat("00");
    VoidCallback startCallback, stopCallback;
    String ongoingLabel = "00:00:00";
    /// If we know who the user is:
    if (_curUser != null) {
      /// Enable the stop button if there is an ongoing drive.
      if (_ongoingDrive) {
        stopCallback = _stopDrive;
        /// Also, update ongoingLabel using _ongoingDuration.
        int minutes = _ongoingDuration.inMinutes % Duration.minutesPerHour;
        int seconds = _ongoingDuration.inSeconds % Duration.secondsPerMinute;
        ongoingLabel = "${_ongoingDuration.inHours}:"+
          "${twoDigitFormat.format(minutes)}:"+
          "${twoDigitFormat.format(seconds)}";
      }
      /// Otherwise, if there is no ongoing drive, enable the start button.
      else startCallback = _startDrive;
    }

    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    /// Array holding all Text objects for the different goals the user has.
    List<Widget> goalTextObjs = <Widget>[
      new Text("Time Completed", style: textTheme.headline)
    ];
    /// Loop through the goal types.
    for (String type in DrivingTimes.TIME_TYPES) {
      /// If the user has this goal:
      if (_userGoals.getTime(type) > 0) {
        /// Capitalize the goal type:
        String typeCapitalized = type[0].toUpperCase()+type.substring(1);
        /// Format the time elapsed in _userTimes.
        String elapsedFormatted = formatMilliseconds(_userTimes.getTime(type));
        /// Add this goal to goalTextObjs.
        goalTextObjs.add(new Text("$typeCapitalized: $elapsedFormatted/${twoDigitFormat.format(_userGoals.getTime(type))}:00", style: textTheme.headline));
      }
    }

    /// List of items for each supervisor.
    List<DropdownMenuItem<num>> supervisorItems = <DropdownMenuItem<num>>[];
    /// Make an item for each supervisor.
    for (int i = 0; i < _supervisorNames.length; i++) {
      supervisorItems.add(
        new DropdownMenuItem<num>(value: i, child: new Text(_supervisorNames[i]))
      );
    }
    /// Also, make sure _supervisorIndex is a valid index of _supervisorNames.
    _supervisorIndex = min(_supervisorIndex, _supervisorNames.length-1);

    return new SingleChildScrollView(
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Card(
                  child: new Column(
                      children: <Widget>[
                        new Text(ongoingLabel, textAlign: TextAlign.center, style: textTheme.headline),
                        new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new RaisedButton(
                                  onPressed: startCallback,
                                  child: new Text("Start Drive"),
                                  color: Theme.of(context).buttonColor
                              ),
                              new RaisedButton(
                                  onPressed: stopCallback,
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
    _supervisorModel.cancelSubscriptions();
    _logModel.cancelSubscriptions();
    super.dispose();
  }
}