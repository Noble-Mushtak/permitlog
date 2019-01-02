import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permitlog/model/driving_times.dart';
import 'package:permitlog/model/learner_model.dart';
import 'package:permitlog/model/log_model.dart';
import 'package:permitlog/views/stateful_checkbox.dart';
import 'package:permitlog/model/supervisor_model.dart';
import 'package:permitlog/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// Reference to all of the user's data, learner's data.
  DatabaseReference _userRef, _learnerRef;
  /// Object used to edit preferences.
  SharedPreferences _prefs;
  /// Object that holds time the user has completed in each category.
  /// These times are stored in milliseconds.
  DrivingTimes _userTimes = new DrivingTimes();
  /// Object that holds all of the user's goals.
  /// These times are stored in hours.
  DrivingTimes _userGoals = new DrivingTimes();
  /// True if onValue event listener for goals has fired at least once
  /// for the current user.
  bool _goalsFound = false;
  /// Subscription that listens for changes to user's goal data.
  StreamSubscription<Event> _goalSubscription;
  /// Model that manages all of the supervisor data.
  SupervisorModel _supervisorModel;
  /// Model that manages all of the learner data.
  LearnerModel _learnerModel;
  /// Model that calculates the time the user has driven in each category.
  LogModel _logModel;
  /// List of all the supervisor names.
  List<String> _supervisorNames;

  /// Index of selected supervisor.
  int _supervisorIndex = 0;
  /// Key and name of current learner (key is empty if default learner).
  String _currentLearnerKey, _currentLearnerName = "";
  /// Objects that store starting and ending time of ongoing drive.
  DateTime _startingTime, _endingTime;
  /// Duration of time from _startingTime to now.
  Duration _ongoingDuration;
  /// Timer that updates ongoing drive time.
  Timer _ongoingTimer;
  /// True if _ongoingTimer is running.
  bool _timerRunning = false;
  /// True if dialog about ongoing drive is currently being shown.
  bool _dialogShowing = false;

  /// Tells user to add supervisor.
  void _supervisorWarning() {
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Please add the supervisor accompanying you by tapping the button in the bottom right"),
        duration: new Duration(seconds: 5),
    ));
  }
  /// Warns user something has gone wrong with preferences.
  void _preferencesWarning() {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Something went wrong when trying to start or stop drive in preferences."),
    ));
  }

  /// Callback for when user is updated.
  Future<void> _updateUser(FirebaseUser user) async {
    /// When the user changes, stop all subscriptions:
    await _goalSubscription?.cancel();
    await _supervisorModel.cancelSubscriptions();
    await _learnerModel.cancelSubscriptions();
    await _logModel.cancelSubscriptions();
    /// Initialize _prefs if necessary.
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    setState(() {
      /// Update _curUser.
      _curUser = user;
      /// Reset other user-related vairables.
      _goalsFound = false;
      /// If _curUser is null, then _userRef is null.
      if (_curUser == null) _userRef = null;
      /// Otherwise, if we know who the user is, update _userRef:
      else {
        _userRef = _data.reference().child(_curUser.uid);
        /// Start listening to supervisor data.
        _supervisorModel = new SupervisorModel(
          userRef: _userRef,
          callback: (List<String> ids, List<String> names, Map<String, Map> data) {
            /// Invoke setState since _supervisorNames has changed.
            setState(() { _supervisorNames = names; });
          }
        );
        _supervisorModel.startSubscriptions();
        /// Start listening to learner data.
        _learnerModel = new LearnerModel(
          userRef: _userRef,
          callback: _updateLearner
        );
        _learnerModel.startSubscriptions();

        /// Update _currentLearnerKey, _learnerRef, _logModel.
        _currentLearnerKey = _prefs.getString("current_learner") ?? "";
        _learnerRef = getCurrentLearnerRef(_userRef, _currentLearnerKey);
        _logModel = new LogModel(
          learnerRef: _learnerRef,
          callback: (List<String> logIds, List<String> logSummaries, DrivingTimes timesData, Map<String, Map> logData) {
            /// Invoke setState since _userTimes has changed.
            setState(() { _userTimes = timesData; });
          }
        );
        /// Start listening to new logs and goals.
        _logModel.startSubscriptions();
        _goalSubscription = _learnerRef.child("goals").onValue.listen(_goalsListener);
      }
    });
  }

  /// Updates the current learner.
  Future<void> _updateLearner(List<String> learnerIds, List<String> learnerNames) async {
    /// Get the index of the current learner (use 0 by default).
    int currentLearnerIndex = 0;
    if (learnerIds.contains(_currentLearnerKey)) {
      currentLearnerIndex = learnerIds.indexOf(_currentLearnerKey)+1;
    }
    /// Update learner name.
    setState(() { _currentLearnerName = learnerNames[currentLearnerIndex]; });
  }

  /// Callback for when new data about the goals come in.
  void _goalsListener(Event event) {
    setState(() {
      /// Update _userGoals with the event.
      _userGoals.updateWithEvent(event);
      /// Set _goalsFound flag.
      _goalsFound = true;
    });
  }
  /// Callback for when user clicks "Start Drive".
  void _startDrive() async {
    /// If there are no supervisors, tell the user to add a supervisor.
    if (_supervisorModel.supervisorData.isEmpty) {
      _supervisorWarning();
      return;
    }
    /// Otherwise, start the ongoing drive.
    else {
      /// Set the _startingTime.
      _startingTime = new DateTime.now();
      /// Initialize _ongoingDuration.
      _ongoingDuration = new Duration(seconds: 0);
      /// Mark that drive has started in the preferences.
      bool success = await _prefs.setBool("drive_ongoing", true);
      success = success && (await _prefs.setInt("drive_start_time", _startingTime.millisecondsSinceEpoch));
      /// Show error message if there is an error setting preferences.
      if (!success) {
        _preferencesWarning();
        return;
      }

      /// Start the timer and update UI.
      setState(_startTimer);
    }
  }
  /// Starts the timer.
  void _startTimer() {
    /// Set _timerRunning flag.
    _timerRunning = true;
    /// Make the timer run a function every second.
    _ongoingTimer = new Timer.periodic(new Duration(seconds: 1), (_) {
      setState(_updateOngoingDuration);
    });
  }
  /// Updates _ongoingDuration variable.
  void _updateOngoingDuration() {
    /// Update the duration between _startingTime and now.
    _ongoingDuration = (new DateTime.now()).difference(_startingTime);
  }
  /// Callback for when user clicks "Stop Drive".
  void _stopDrive() async {
    /// If there are no supervisors, tell the user to add a supervisor.
    if (_supervisorModel.supervisorData.isEmpty) {
      _supervisorWarning();
      return;
    }
    /// Save the supervisor ID in preferences.
    String supervisorId = _supervisorModel.supervisorIds[_supervisorIndex];
    bool success = await _prefs.setString("drive_supervisor", supervisorId);
    /// Save the stop time in Firebase.
    _endingTime = new DateTime.now();
    success = success && (await _prefs.setInt("drive_end_time", _endingTime.millisecondsSinceEpoch));
    /// Show error message if there is an error setting preferences.
    if (!success) {
      _preferencesWarning();
      return;
    }

    /// Show dialog about drive so user can save drive.
    _dialogShowing = true;
    /// It is important that setState() comes after setting flag so build()
    /// does not accidentally restart timer or start duplicate dialog.
    setState(() {
      /// Unset _timerRunning flag.
      _timerRunning = false;
      /// Cancel the timer.
      _ongoingTimer.cancel();
    });
    await _showDialog(supervisorId);
  }
  /// Shows dialog allowing user to put drive into categories.
  Future<void> _showDialog(String supervisorId) async {
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
    if (categoryCheckboxes.isEmpty) {
      _saveDrive(driveCategories, supervisorId);
      /// We never actually showed the dialog, so unset _dialogShowing flag.
      _dialogShowing = false;
    }
    /// Otherwise, show the user a dialog
    /// so they can choose which categories apply here.
    else {
      /// For the dialog's content, prepend the checkboxes with some text.
      List<Widget> content = <Widget>[new Text("Select all that apply.")];
      content += categoryCheckboxes;
      /// Now, keep trying to show the dialog until it works.
      while (_dialogShowing) {
        /// Await 100 milliseconds in between each attempt.
        await new Future.delayed(new Duration(milliseconds: 100));
        try {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext innerContext) => new AlertDialog(
              content: new Column(mainAxisSize: MainAxisSize.min, children: content),
              actions: <Widget>[
                new FlatButton(
                  child: new Text("Cancel"),
                  /// Show error message if the user clicks cancel.
                  onPressed: () async {
                    /// Mark that drive has ended in preferences.
                    bool success = await resetPreferences();
                    /// Show a different error message if setting preferences fails.
                    String message = "Drive cancelled.";
                    if (!success) {
                      message = "Cancelling drive failed.";
                    }
                    /// Show error message.
                    Scaffold.of(context).showSnackBar(new SnackBar(
                      content: new Text(message)
                    ));
                    /// Exit the dialog if setting preferences succeeded.
                    if (success) setState(() {
                      /// Unset _dialogShowing flag.
                      _dialogShowing = false;
                      Navigator.pop(innerContext);
                    });
                  },
                ),
                new FlatButton(
                  child: new Text("Save"),
                  onPressed: () async {
                    /// Try to save the drive.
                    bool success = await _saveDrive(driveCategories, supervisorId);
                    /// Exit the dialog if save is successful.
                    if (success) setState(() {
                      /// Unset _dialogShowing flag.
                      _dialogShowing = false;
                      Navigator.pop(innerContext);
                    });
                  }
                )
              ]
            )
          );
        }
        /// Print any errors from showDialog() to console.
        /// The most likely error is that there is still a build going on,
        /// which will eventually go away after enough attempts.
        catch (e) {
         print(e.toString());
        }
      }
    }
  }
  /// Saves drive with _startingTime and _endingTime.
  Future<bool> _saveDrive(List<bool> categories, String supervisorId) async {
    /// Set endingTime so the difference in times is exact in minutes.
    _ongoingDuration = _endingTime.difference(_startingTime);
    int msDifference = _ongoingDuration.inMicroseconds % Duration.microsecondsPerMinute;
    _endingTime = _endingTime.subtract(new Duration(microseconds: msDifference));
    /// Create a new drive in the database.
    DatabaseReference driveRef = _learnerRef.child("times").push();

    /// This is the success/error message we will show the user.
    String message = "Drive successfully saved.";
    /// This is false if some error occurs below.
    bool success = true;
    try {
      /// Save the drive in database.
      await driveRef.set(<String, dynamic>{
        "start": _startingTime.millisecondsSinceEpoch,
        "end": _endingTime.millisecondsSinceEpoch,
        "night": categories[0],
        "weather": categories[1],
        "adverse": categories[2],
        "driver_id": supervisorId
      });
      /// Stop drive in preferences.
      success = await resetPreferences();
      /// Show user error message if preference editing fails.
      if (!success) {
        message = "Drive saved successfully, but cancelling drive failed.";
      }
    } catch (e) {
      /// Show user error message, return false for failure.
      message = "Error occurred while saving drive.";
      success = false;
    }
    /// Update UI and show user success/error message.
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text(message)
    ));
    /// Return true for success, false for failure.
    return success;
  }

  /// Resets preferences related to ongoing drive.
  Future<bool> resetPreferences() async {
    /// Set drive_ongoing to false, remove all other preferences.
    bool success = await _prefs.setBool("drive_ongoing", false);
    success = success && (await _prefs.remove("drive_start_time"));
    success = success && (await _prefs.remove("drive_end_time"));
    success = success && (await _prefs.remove("drive_supervisor"));
    return success;
  }

  @override
  void initState() {
    super.initState();
    /// Subscribe to changes to authentication:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
    /// As a placeholder, initialize _supervisorModel and _supervisorNames.
    _supervisorModel = new SupervisorModel(userRef: null, callback: null);
    _supervisorNames = _supervisorModel.supervisorNames;
    /// Also, initialize _logModel, _learnerModel.
    _learnerModel = new LearnerModel(userRef: null, callback: null);
    _logModel = new LogModel(learnerRef: null, callback: null);
  }

  @override
  Widget build(BuildContext context) {
    /// Numerical format for two-digit number..
    final NumberFormat twoDigitFormat = new NumberFormat("00");
    VoidCallback startCallback, stopCallback;
    String ongoingLabel = "00:00:00";
    /// If we know who the user is and what their goals are:
    if ((_curUser != null) && _goalsFound) {
      /// Enable the stop button if there is an ongoing drive.
      if (_prefs.getBool("drive_ongoing") ?? false) {
        stopCallback = _stopDrive;

        /// Get other data from preferences.
        int startingTimeMillis = _prefs.getInt("drive_start_time");
        int endingTimeMillis = _prefs.getInt("drive_end_time");
        String supervisorId = _prefs.getString("drive_supervisor");
        /// For Debug:
        /// print(startingTimeMillis.toString()+" "+endingTimeMillis.toString()+" "+supervisorId.toString());

        /// Update _startingTime if possible.
        if (startingTimeMillis != null) {
          _startingTime = new DateTime.fromMillisecondsSinceEpoch(startingTimeMillis);
          /// If drive has been finished, but not saved:
          if ((endingTimeMillis != null) && (supervisorId != null)) {
            /// Update _endingTime and _ongoingDuration.
            _endingTime = new DateTime.fromMillisecondsSinceEpoch(endingTimeMillis);
            _ongoingDuration = _endingTime.difference(_startingTime);
            /// Show dialog if not already showing.
            if (!_dialogShowing) {
              _dialogShowing = true;
              _showDialog(supervisorId);
            }
          }
          /// If drive has not been finished:
          else {
            /// Update _ongoingDuration and start timer
            /// if the timer's not running already.
            if (!_timerRunning) {
              _updateOngoingDuration();
              _startTimer();
            }
          }
        }

        /// Update ongoingLabel using _ongoingDuration.
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
    for (String type in DrivingTimes.types) {
      /// If the user has this goal:
      if (_userGoals.getTime(type) > 0) {
        /// Capitalize the goal type:
        String typeCapitalized = type[0].toUpperCase()+type.substring(1);
        /// Format the time elapsed in _userTimes.
        String elapsedFormatted = formatMilliseconds(_userTimes.getTime(type));
        /// Add this goal to goalTextObjs.
        goalTextObjs.add(new Text("$typeCapitalized: $elapsedFormatted/${_userGoals.getTime(type)}:00", style: textTheme.headline));
      }
    }

    /// List of items for each supervisor.
    List<DropdownMenuItem<num>> supervisorItems = createDropdownItems(_supervisorNames);
    /// Also, make sure _supervisorIndex is a valid index of _supervisorNames.
    _supervisorIndex = min(_supervisorIndex, _supervisorNames.length-1);

    return Padding(
      padding: const EdgeInsets.only(top:16, left:16, right:16),
      child: new SingleChildScrollView(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Card(
              child: new Text("Hello, $_currentLearnerName", textAlign: TextAlign.center, style: textTheme.headline,)
            ),
            new Card(
              child: new Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top:8.0),
                    child: new Text(ongoingLabel, textAlign: TextAlign.center, style: textTheme.headline),
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: new RaisedButton(
                          onPressed: startCallback,
                          child: new Text("Start Drive"),
                          color: Theme.of(context).buttonColor
                        ),
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
      ),
    );
  }

  /// When we are done with this widget, cancel the timers/subscriptions.
  @override
  void dispose() {
    _authSubscription.cancel();
    _goalSubscription?.cancel();
    _supervisorModel.cancelSubscriptions();
    _logModel.cancelSubscriptions();
    _learnerModel.cancelSubscriptions();
    _ongoingTimer?.cancel();
    super.dispose();
  }
}