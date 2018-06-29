import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// View that allows user to add a supervisor
class AddSupervisorView extends StatefulWidget {
  /// String storing the ID of supervisor being edited
  String _supervisorId;
  AddSupervisorView({String supervisorId}) : _supervisorId = supervisorId;

  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _AddSupervisorViewState(_supervisorId);
}

class _AddSupervisorViewState extends State<AddSupervisorView> {
  /// Firebase API Interfaces
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _data = FirebaseDatabase.instance;
  /// Key used to identify form
  GlobalKey<FormState> _formKey;
  /// Subscription that listens for changes to authentication.
  StreamSubscription<FirebaseUser> _authSubscription;
  /// Database reference to all the user's supervisor data
  DatabaseReference _supervisorsRef;
  /// Controllers used to get data from text form fields
  TextEditingController _firstNameController, _lastNameController,
      _licenseController, _ageController;
  /// Data from existing supervisor
  String _oldFirstName, _oldLastName, _oldLicense, _oldAge;

  /// String storing the ID of supervisor being edited
  String _supervisorId;
  _AddSupervisorViewState(String supervisorId) : _supervisorId = supervisorId;

  @override
  void initState() {
    super.initState();
    /// Initialize _formKey and controllers:
    _formKey = new GlobalKey<FormState>();
    _firstNameController = new TextEditingController();
    _lastNameController = new TextEditingController();
    _licenseController = new TextEditingController();
    _ageController = new TextEditingController();
    /// Subscribe to auth state changes:
    _authSubscription = _auth.onAuthStateChanged.listen(_updateUser);
  }

  Future<void> _updateUser(FirebaseUser user) async {
    setState(() {
      /// Reset variables related to user.
      _supervisorsRef = null;
      if (user != null) {
        /// If user is non-null, initialize variables related to user.
        _supervisorsRef = _data.reference().child(user.uid).child("drivers");
        /// If we are editing an existing supervisor,
        /// try to get their data.
        if (_supervisorId != null) {
          _supervisorsRef.child(_supervisorId).once().then(_setSupervisorData);
        }
      }
    });
  }

  /// Sets initial data for supervisor
  void _setSupervisorData(DataSnapshot snapshot) {
    setState(() {
      /// Get the supervisor data
      Map supervisorData = snapshot.value ?? new Map();
      /// If there is a name:
      if (supervisorData.containsKey("name")) {
        /// Set the first and last name if possible
        if (supervisorData["name"].containsKey("first")) {
          _oldFirstName = supervisorData["name"]["first"];
        }
        if (supervisorData["name"].containsKey("last")) {
          _oldLastName = supervisorData["name"]["last"];
        }
      }
      /// Set the license number and age if possible
      if (supervisorData.containsKey("license_number")) {
        _oldLicense = supervisorData["license_number"];
      }
      if (supervisorData.containsKey("age")) _oldAge = supervisorData["age"];
      /// Add default values to fields for the supervisor's based off the old data.
      _firstNameController = new TextEditingController(text: _oldFirstName);
      _lastNameController = new TextEditingController(text: _oldLastName);
      _licenseController = new TextEditingController(text: _oldLicense);
      _ageController = new TextEditingController(text: _oldAge);
    });
  }

  /// Returns error message if val is empty (used for form validation)
  String _errorIfEmpty(String val, String fieldDescription) {
   return val.isEmpty ? "Please enter the supervisor's $fieldDescription." : null;
  }

  /// Validate the form and attempt to save the changes to the supervisor
  Future<void> _validateForm(BuildContext context) async {
    /// Validate the form before doing anything
    if (_formKey.currentState.validate()) {
      /// If there is no license, warn the user before saving the supervisor.
      if (_licenseController.text.isEmpty) {
        bool wantsNoLicense = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => new AlertDialog(
            content: new Text("Are you sure you want to save the supervisor without a license number?"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Yes"),
                onPressed: () => Navigator.pop(context, true)
              ),
              new FlatButton(
                child: new Text("No"),
                onPressed: () => Navigator.pop(context, false)
              ),
            ],
          )
        );
        /// If they affirm that they want no license, save the supervisor.
        if (wantsNoLicense) _saveSupervisor(context);
      }
      /// Otherwise, just save the supervisor.
      else _saveSupervisor(context);
    }
  }

  /// Save the changes to the supervisor
  void _saveSupervisor(BuildContext context) {
    DatabaseReference _supervisorRef;
    /// If there is no _supervisorId, create a new supervisor
    if (_supervisorId == null) _supervisorRef = _supervisorsRef.push();
    /// Otherwise, edit that supervisor
    else _supervisorRef = _supervisorsRef.child(_supervisorId);
    /// Save the data
    _supervisorRef.set(<String, dynamic>{
      "name": <String, dynamic>{
        "first": _firstNameController.text,
        "last": _lastNameController.text
      },
      "license_number": _licenseController.text,
      "age": _ageController.text
    });
    /// Go back to PermitLog with message for user
    Navigator.pop(context, "Supervisor saved");
  }

  /// Deletes the supervisor at _supervisorId
  void _deleteSupervisor(BuildContext context) {
    /// Delete the supervisor
    _supervisorsRef.child(_supervisorId).remove();
    /// Go back to PermitLog with message for user
    Navigator.pop(context, "Supervisor deleted");
  }

  /// Builder function for Scaffold
  /// (Inner function is used in case this context may be needed for the Snackbar)
  Widget _innerBuild(BuildContext context) {
    /// Get the TextTheme so we can style the texts:
    final TextTheme textTheme = Theme.of(context).textTheme;
    VoidCallback saveCallback, deleteCallback;
    /// Only enable the save, delete button if the user is signed in
    /// Also, pass in inner context so that they have access to snackbar
    if (_supervisorsRef != null) {
      saveCallback = () => _validateForm(context);
      deleteCallback = () => _deleteSupervisor(context);
    }

    /// List of buttons that user can choose from
    List<RaisedButton> buttons = [
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
    if (_supervisorId != null) {
      buttons.add(new RaisedButton(
        onPressed: deleteCallback,
        child: new Text("Delete"),
        color: Theme.of(context).buttonColor
      ));
    }

    return new Form(
      key: _formKey,
      child: new SingleChildScrollView(
        child: new Padding(
          padding: new EdgeInsets.all(8.0),
          child: new Column(
            children: <Widget>[
              new TextFormField(
                decoration: new InputDecoration(labelText: "Supervisor's First Name"),
                controller: _firstNameController,
                /// Make sure this field is not empty.
                validator: (String val) => _errorIfEmpty(val, "first name")
              ),
              new TextFormField(
                decoration: new InputDecoration(labelText: "Supervisor's Last Name"),
                controller: _lastNameController,
                /// Make sure this field is not empty.
                validator: (String val) => _errorIfEmpty(val, "last name")
              ),
              new Padding(padding: new EdgeInsets.all(4.0), child: new Row()),
              new Text("For privacy reasons, the license number can be left blank."),
              new TextFormField(
                decoration: new InputDecoration(labelText: "Supervisor's License"),
                controller: _licenseController
              ),
              new TextFormField(
                decoration: new InputDecoration(labelText: "Supervisor's Age"),
                controller: _ageController,
                keyboardType: TextInputType.number,
                /// Make sure this is a valid number within 21 and 117
                validator: (String val) {
                  int age = int.tryParse(val) ?? 0;
                  if ((age < 21) || (age > 117)) {
                    return "Supervisor age must be over 21 and less than 117.";
                  }
                  else return null;
                }
              ),
              new Padding(padding: new EdgeInsets.all(4.0), child: new Row()),
              new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: buttons
              )
            ],
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Title of this widget
    String title = "Edit Supervisor";
    /// Change it if we are creating a supervisor:
    if (_supervisorId == null) title = "Add Supervisor";

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
    /// Cancel any ongoing subscriptions before the widget is disposed.
    _authSubscription.cancel();
    super.dispose();
  }
}