import 'dart:async';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permitlog/driving_times.dart';
import 'package:permitlog/supervisor_model.dart';
import 'package:permitlog/utilities.dart';

/// View that allows user to add or edit a log
class AddLogView extends StatefulWidget {
  /// String storing the ID of log being edited
  final String _logId;
  AddLogView({String logId}) : _logId = logId;

  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _AddLogViewState(_logId);
}

class _AddLogViewState extends State<AddLogView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Subscription that listens for changes to user's goal data
  /// or to the log being edited
  StreamSubscription<Event> _goalSubscription, _logSubscription;
  /// Database reference to all the user's data and all the user's log data
  DatabaseReference _userRef, _logRef;
  /// Database reference to all the user's goal data
  DatabaseReference _goalRef;
  /// Model for supervisor data.
  SupervisorModel _supervisorModel;
  /// List of supervisor IDs and names.
  List<String> _supervisorIds, _supervisorNames;
  /// User's goal data
  DrivingTimes _goalData;
  /// Categories of drive log
  /// 0 -> Night, 1 -> Poor Weather, 2 -> Adverse Conditions
  List<bool> _categories = [false, false, false];
  /// Strings used to describe each category to the user
  List<String> _categoryDescs = ["Night", "Poor Weather", "Adverse Conditions"];
  /// Starting and ending time of this drive log
  DateTime _startingTime, _endingTime;
  /// ID of supervisor for this drive log
  String _supervisorId;

  /// ID of log being edited
  final String _logId;
  _AddLogViewState(String logId) : _logId = logId;

  @override
  void initState() {
    super.initState();
    /// Initialize supervisor variables, goal data
    _supervisorModel = new SupervisorModel(userRef: null, callback: null);
    _supervisorIds = _supervisorModel.supervisorIds;
    _supervisorNames = _supervisorModel.supervisorNames;
    _goalData = new DrivingTimes();
    /// Initialize starting, ending time to be in UTC time,
    /// but actually have the current time of day according to local time
    /// This is a hack needed because the best way to set
    /// the year/month/day/hour/minute of a DateTime in Flutter is through
    /// the DateTime.utc() constructor, which works in UTC time.
    _startingTime = _endingTime = new DateTime.now();
    _startingTime = _endingTime = _startingTime.add(_startingTime.timeZoneOffset).toUtc();
    /// Subscribe to changes in auth state.
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
  }

  /// Called when auth state changes
  Future<void> _updateUser(FirebaseUser user) async {
    /// Cancel any pending subscriptions
    await _supervisorModel.cancelSubscriptions();
    await _goalSubscription?.cancel();
    await _logSubscription?.cancel();
    setState(() {
      /// Reset variables related to user.
      _userRef = _logRef = _goalRef = null;
      _goalData = new DrivingTimes();
      if (user != null) {
        /// If user is signed in, initialize variables related to user.
        _userRef = _data.reference().child(user.uid);
        _logRef = _userRef.child("times");
        _goalRef = _userRef.child("goals");
        /// Also, start listening to data related to goals and supervisors.
        _goalSubscription = _goalRef.onValue.listen((Event event) {
          /// Update _goalData when there is new goal data.
          setState(() { _goalData.updateWithEvent(event); });
        });
        _supervisorModel = new SupervisorModel(
          userRef: _userRef,
          callback: (List<String> ids, List<String> names, Map<String, Map> data) {
            /// Update UI after updating _supervisorIds, _supervisorNames.
            setState(() {
              _supervisorIds = ids;
              _supervisorNames = names;
            });
          }
        );
        _supervisorModel.startSubscriptions();
        /// If we are editing a log, update the log data.
        if (_logId != null) {
          _logSubscription = _logRef.child(_logId).onValue.listen(_setLogData);
        }
      }
    });
  }

  /// Sets data for log being edited
  void _setLogData(Event event) {
    setState(() {
      /// Get the log data
      Map logData = event.snapshot.value ?? new Map();
      /// Set the starting and ending time, if possible
      if (logData.containsKey("start")) {
        _startingTime = new DateTime.fromMillisecondsSinceEpoch(logData["start"]);
        /// Apply the same hack used in initState().
        _startingTime = _startingTime.add(_startingTime.timeZoneOffset).toUtc();
      }
      if (logData.containsKey("end")) {
        _endingTime = new DateTime.fromMillisecondsSinceEpoch(logData["end"]);
        _endingTime = _endingTime.add(_endingTime.timeZoneOffset).toUtc();
      }
      /// _endingTime should be on the same day as _startingTime
      _endingTime = new DateTime.utc(
        _startingTime.year, _startingTime.month, _startingTime.day,
        _endingTime.hour, _endingTime.minute,
        /// Make sure _endingTime is an even number of minutes away
        /// from _startingTime
        _startingTime.second, _startingTime.millisecond,
        _startingTime.microsecond
      );

      /// Set the supervisor ID, if possible
      _supervisorId = logData["driver_id"] ?? null;
      /// Update the categories of this log
      _categories[0] = logData["night"] ?? false;
      _categories[1] = logData["weather"] ?? false;
      _categories[2] = logData["adverse"] ?? false;
    });
  }

  /// Allow the user to change the date of this drive log
  Future<void> _changeDate(BuildContext context) async {
    DateTime newDate = await showDatePicker(
      context: context,
      initialDate: _startingTime,
      /// Allow the user to pick a date in the years 2000-2100
      firstDate: new DateTime.utc(2000),
      lastDate: new DateTime.utc(2100)
    );
    /// Don't do anything if user clicks Cancel
    if (newDate == null) return;
    setState(() {
      /// Update year, month, day of _startingTime, _endingTime
      _startingTime = new DateTime.utc(
        newDate.year, newDate.month, newDate.day,
        _startingTime.hour, _startingTime.minute
      );
      _endingTime = new DateTime.utc(
        newDate.year, newDate.month, newDate.day,
        _endingTime.hour, _endingTime.minute,
        /// Make sure _endingTime is an even number of minutes away
        /// from _startingTime
        _startingTime.second, _startingTime.millisecond,
        _startingTime.microsecond
      );
    });
  }

  /// Allow the user to change the starting/ending time of this drive log
  Future<void> _changeTime(BuildContext context, bool setStartingTime) async {
    /// Get the old time based off setStartingTime.
    DateTime oldDateTime;
    if (setStartingTime) oldDateTime = _startingTime;
    else oldDateTime = _endingTime;
    /// Ask the user to pick a time of day
    TimeOfDay newTimeOfDay = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(oldDateTime)
    );
    /// Don't do anything if user clicks Cancel
    if (newTimeOfDay == null) return;
    /// Set time to have same time of day as newTime
    DateTime newDateTime = new DateTime.utc(
      oldDateTime.year, oldDateTime.month, oldDateTime.day,
      newTimeOfDay.hour, newTimeOfDay.minute,
      /// Use the second/millisecond/microsecond from _startingTime
      /// to make sure _endingTime is an even number of minutes away
      /// from _startingTime
      _startingTime.second, _startingTime.millisecond,
      _startingTime.microsecond
    );
    setState(() {
      /// Set _startingTime or _endingTime based off setStartingTime.
      if (setStartingTime) _startingTime = newDateTime;
      else _endingTime = newDateTime;
    });
  }

  void _saveLog(BuildContext context) {
    /// If _supervisorIds is empty, tell the user to select a supervisor.
    if (_supervisorIds.isEmpty) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Please add the supervisor that accompanied you by tapping the button in the bottom right of the Home tab")
      ));
      return;
    }
    /// If _supervisorId is not in _supervisorIds
    /// then _supervisorIndex in _innerBuild() is 0,
    /// so pick the first ID in _supervisorIds:
    if (!_supervisorIds.contains(_supervisorId)) {
      _supervisorId = _supervisorIds[0];
    }

    /// If the end time is before the start time,
    /// then add a day to the end time.
    if (_endingTime.isBefore(_startingTime)) {
      _endingTime = new DateTime.utc(
        _endingTime.year, _endingTime.month, _endingTime.day+1,
        _endingTime.hour, _endingTime.minute,
        /// Make sure _endingTime is an even number of minutes away
        /// from _startingTime
        _startingTime.second, _startingTime.millisecond,
        _startingTime.microsecond
      );
    }
    /// Make sure the difference between _startingTime and _endingTime
    /// is exact in minutes.
    Duration driveDuration = _endingTime.difference(_startingTime);
    int msDifference = driveDuration.inMicroseconds % Duration.microsecondsPerMinute;
    if (msDifference != 0) {
      print("Error: _endingTime is not even number of minutes away from _startingTime");
    }
    /// Since we are now saving the log,
    /// we do the inverse of the hack in initState()
    /// to convert the times back to local time.
    _startingTime = _startingTime.toLocal();
    _startingTime = _startingTime.subtract(_startingTime.timeZoneOffset);
    _endingTime = _endingTime.toLocal();
    _endingTime = _endingTime.subtract(_endingTime.timeZoneOffset);

    DatabaseReference _curLogRef;
    /// If we are editing a log, set that to _curLogRef
    if (_logId != null) _curLogRef = _logRef.child(_logId);
    /// Otherwise, create a new log
    else _curLogRef = _logRef.push();
    /// Save the data
    _curLogRef.set(<String, dynamic>{
      "start": _startingTime.millisecondsSinceEpoch,
      "end": _endingTime.millisecondsSinceEpoch,
      "night": _categories[0],
      "weather": _categories[1],
      "adverse": _categories[2],
      "driver_id": _supervisorId
    });
    /// Exit this window with a message for the user
    Navigator.pop(context, "Drive log saved");
  }

  void _deleteLog(BuildContext context) {
    /// Delete the log
    _logRef.child(_logId).remove();
    /// Exit this window with a message for the user
    Navigator.pop(context, "Drive log deleted");
  }

  /// Creates checkbox widgets related to some category
  Widget _createCheckbox(int category, TextStyle style) {
    return new Row(
      children: <Widget>[
        new Checkbox(
          value: _categories[category],
          /// Update _categories when user clicks checkbox
          onChanged: (bool val) => setState(() { _categories[category] = val; })
        ),
        new Text(_categoryDescs[category], style: style),
      ]
    );
  }

  /// Builder function for Scaffold
  /// (Inner function is used in case this context may be needed for the SnackBar)
  Widget _innerBuild(BuildContext context) {
    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    /// Make some styles for us to use later.
    final TextStyle titleStyle = new TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: textTheme.title.fontSize
    );
    final TextStyle subheadStyle = new TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: textTheme.subhead.fontSize,
      decoration: TextDecoration.underline
    );
    /// This format object is used to show dates to the user.
    final DateFormat longDateFormat = new DateFormat.yMMMMd();
    /// This format object is used to show times to the user.
    final DateFormat timeFormat = new DateFormat.jm();

    /// List of items for each supervisor.
    List<DropdownMenuItem<num>> supervisorItems = createDropdownItems(_supervisorNames);
    /// Index of selected supervisor
    int _supervisorIndex = 0;
    /// Try to find the index of _supervisorId in _supervisorIds, if possible
    if (_supervisorIds.contains(_supervisorId)) {
      _supervisorIndex = _supervisorIds.indexOf(_supervisorId);
    }

    /// If the supervisor of this log has been deleted,
    /// this array contains a notice telling the user such.
    List<Widget> deletedSupervisorNotice = [];
    if ((_supervisorId != null) && !_supervisorIds.contains(_supervisorId)) {
      deletedSupervisorNotice.add(new Text("The supervisor that was originally set for this log has been deleted. Please set a new supervisor."));
    }
    /// If the ending time is before the starting time,
    /// this array contains a notice warning the user of what will happen.
    List<Widget> timeNotice = [];
    if (_endingTime.isBefore(_startingTime)) {
      timeNotice.add(new Text("Note that if the ending time is before the starting time, it will be assumed that the drive went into the next day."));
    }

    /// This is a list of checkboxes to mark the categories of this drive log.
    List<Widget> categoryCheckboxes = [];
    /// Let the user mark the "night" category if they have the day or night goal.
    if ((_goalData.getTime("day") > 0) || (_goalData.getTime("night") > 0)) {
      categoryCheckboxes.add(_createCheckbox(0, titleStyle));
    }
    /// Similarly, let the user mark the "weather" and "adverse" categories
    /// if they have the corresponding goals.
    if (_goalData.getTime("weather") > 0) {
      categoryCheckboxes.add(_createCheckbox(1, titleStyle));
    }
    if (_goalData.getTime("adverse") > 0) {
      categoryCheckboxes.add(_createCheckbox(2, titleStyle));
    }

    /// Enable the save/delete buttons only when the user signs in:
    VoidCallback saveCallback, deleteCallback;
    if (_userRef != null) {
      saveCallback = () => _saveLog(context);
      deleteCallback = () => _deleteLog(context);
    }

    /// This is a list of buttons the user can choose from:
    List<Widget> buttons = [
      new RaisedButton(
        onPressed: saveCallback,
        child: new Text("Save"),
        color: Theme.of(context).buttonColor
      ),
      new RaisedButton(
        /// If user clicks Cancel, go back to Home
        onPressed: () => Navigator.pop(context),
        child: new Text("Cancel"),
        color: Theme.of(context).buttonColor
      )
    ];
    /// If we are editing an existing drive, add Delete button
    if (_logId != null) {
      buttons.add(new RaisedButton(
        onPressed: deleteCallback,
        child: new Text("Delete"),
        color: Theme.of(context).buttonColor
      ));
    }

    return new SingleChildScrollView(
      child: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          /// Make sure everything is left-aligned
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Text("Date: ", style: titleStyle),
                new FlatButton(
                  child: new Text(longDateFormat.format(_startingTime), style: subheadStyle),
                  onPressed: () => _changeDate(context),
                  shape: new UnderlineInputBorder(),
                )
              ],
            ),
            new Row(
              children: <Widget>[
                new Text("Start Time: ", style: titleStyle),
                new FlatButton(
                  child: new Text(timeFormat.format(_startingTime), style: subheadStyle),
                  onPressed: () => _changeTime(context, true),
                  shape: new UnderlineInputBorder(),
                )
              ],
            ),
            new Row(
              children: <Widget>[
                new Text("End Time: ", style: titleStyle),
                new FlatButton(
                  child: new Text(timeFormat.format(_endingTime), style: subheadStyle),
                  onPressed: () => _changeTime(context, false),
                  shape: new UnderlineInputBorder(),
                )
              ],
            )
          ]
          +timeNotice
          +categoryCheckboxes
          +deletedSupervisorNotice
          +<Widget>[
            new Text("Accompanying Supervisor:", style: titleStyle),
            /// Make the dropdown take up the full width of the screen
            /// using mainAxisSize and an Expanded widget.
            new Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Expanded(
                  child: new DropdownButton<num>(
                    value: _supervisorIndex,
                    items: supervisorItems,
                    onChanged: (num index) {
                      /// If this is a valid index of _supervisorIds,
                      /// then update _supervisorId
                      if (index < _supervisorIds.length) {
                        setState(() { _supervisorId = _supervisorIds[index]; });
                      }
                    }
                  )
                )
              ]
            ),
            new Padding(padding: new EdgeInsets.all(4.0), child: new Row()),
            new Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: buttons
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Title of this widget
    String title = "Edit Drive Log";
    /// Change it if we are creating a new drive log:
    if (_logId == null) title = "Add Drive Log";

    return new Scaffold(
        appBar: new AppBar(
          title: new Text(title),
          backgroundColor: Colors.blueAccent,
        ),
        /// Use _innerBuild to get the body
        body: new Builder(builder: _innerBuild)
    );
  }

  @override
  void dispose() {
    /// Cancel all subscriptions in dispose method
    _authSubscription.cancel();
    _supervisorModel.cancelSubscriptions();
    _goalSubscription?.cancel();
    _logSubscription?.cancel();
    super.dispose();
  }
}