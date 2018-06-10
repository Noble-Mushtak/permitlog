import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'views/about.dart';
import 'views/goals.dart';
import 'views/home.dart';
import 'views/log.dart';
import 'views/supervisors.dart';

/// Enum representing the different sign-in options.
enum _SignInOptions {
  google,
  email,
  facebook
}

/// Main function, creates a new [MaterialApp] whose home widget is [PermitLog].
void main() {
  runApp(
    new MaterialApp(
      home: new PermitLog(),
      title: 'PermitLog',
    )
  );
}

/// Main class for the PermitLog app.
class PermitLog extends StatefulWidget {
  /// Creates the state for the app's main widget.
  @override
  State<StatefulWidget> createState() => new _PermitLogState();
}

/// [State] for the [PermitLog] widget.
class _PermitLogState extends State<PermitLog> {
  /// Firebase Auth API Interface
  final FirebaseAuth _auth = FirebaseAuth.instance;
  /// Firebase User Object
  FirebaseUser _curUser;
  /// Create GoogleSignIn instance that allows us to access their e-mail and OpenID.
  final GoogleSignIn _googleSignIn = new GoogleSignIn(
    scopes: ['openid', 'email']
  );

  /// Style for [Drawer] menu items.
  final TextStyle menuText = new TextStyle(color: Colors.white);

  /// Content for the current state.
  String title = 'Home';
  Widget content = new HomeView();

  /// Sets the [AppBar]'s title and navigates to the view indicated.
  void _navTo(String view) {
    setState(() {
      this.title = view;
      switch(view.toLowerCase()) {
        case 'home':
          this.content = new HomeView();
          break;
        case 'log':
          this.content = new LogView();
          break;
        case 'supervisors':
          this.content = new SupervisorsView();
          break;
        case 'about':
          this.content = new AboutView();
          break;
        case 'goals':
          this.content = new GoalsView();
          break;
        default:
          break;
      }
    });
    Navigator.pop(context);
  }

  /// Tells the user that authentication failed and they need to try again.
  void _tryAuthenticationAgain(BuildContext context) {
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Authentication failed. Please try again")
    ));
  }

  /// Authenticates the user using Google sign-in.
  Future<Null> _authenticateUserGoogle(BuildContext context) async {
    /// This object represents the user in the Google API.
    GoogleSignInAccount googleUser = _googleSignIn.currentUser;

    /// If the user is not signed in, try to re-authenticate the user:
    if (googleUser == null) googleUser = await _googleSignIn.signInSilently();
    /// If this fails, sign the user in using an interactive dialog:
    if (googleUser == null) {
      /// Keep trying to get the user's authentication until it works.
      while (googleUser == null) {
        /// Start the interactive sign-in process.
        googleUser = await _googleSignIn.signIn();

        /// If authentication failed, tell the user to try again.
        if (googleUser == null) _tryAuthenticationAgain(context);
      }
    }

    /// Get the object with the user's data.
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    /// Get the FirebaseUser from the googleAuth object.
    _auth.signInWithGoogle(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken
    ).then(
      /// Set _curUser inside setState to update the widget:
      (FirebaseUser user) =>
      setState(() {
        _curUser = user;
        print("signed in " + _curUser?.uid.toString());
      })
    );
  }

  /// Authenticates the user using one of the sign-in options.
  Future<Null> _authenticateUser(BuildContext context) async {
    /// First, try to get the user from FirebaseAuth:
    FirebaseUser user = await _auth.currentUser();
    /// If user is non-null, update _curUser and return:
    if (user != null) {
      setState(() { _curUser = user; });
      return;
    }
    /// Otherwise, we need to sign the user in.

    /// Ask the user to select a sign-in option.
    _SignInOptions option = await showDialog<_SignInOptions>(
      context: context,
      builder: (BuildContext context) => new AlertDialog(
        content: new Text("Select a sign-in option."),
        actions: <Widget>[
          new FlatButton(
              child: new Text("Google"),
              onPressed: () => Navigator.pop(context, _SignInOptions.google)
          ),
          new FlatButton(
              child: new Text("E-mail"),
              onPressed: () => Navigator.pop(context, _SignInOptions.email)
          ),
          new FlatButton(
              child: new Text("Facebook"),
              onPressed: () => Navigator.pop(context, _SignInOptions.facebook)
          ),
        ]
      )
    );
    /// Call different authentication methods depending on what is chosen:
    switch (option) {
      case _SignInOptions.google:
        _authenticateUserGoogle(context);
        break;
      case _SignInOptions.email:
        /// Coming soon!
        break;
      case _SignInOptions.facebook:
        /// Coming soon!
        break;
    }
  }

  /// Builds the current state.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(this.title),
        backgroundColor: Colors.blueAccent,
      ),
      /// Authenticate the user inside a Builder
      /// so that the context has access to the Scaffold.
      body: new Builder(
        builder: (BuildContext context) {
          /// Try to authenticate the user as soon as possible:
          if (_curUser == null) _authenticateUser(context);

          return this.content;
        }
      ),
      drawer: new Drawer(
        child: new Container(
          color: Colors.blueAccent,
          child: new ListView(
            children: <Widget>[
              new ListTile(
                leading: new Icon(Icons.home, color: Colors.white,),
                title: new Text("Home", style: this.menuText,),
                onTap: () => this._navTo("Home"),
              ),
              new ListTile(
                leading: new Icon(Icons.assignment, color: Colors.white,),
                title: new Text("Log", style: this.menuText,),
                onTap: () => this._navTo("Log"),
              ),
              new ListTile(
                leading: new Icon(Icons.supervisor_account, color: Colors.white,),
                title: new Text("Supervisors", style: this.menuText,),
                onTap: () => this._navTo("Supervisors"),
              ),
              new ListTile(
                leading: new Icon(Icons.settings, color: Colors.white,),
                title: new Text("Goals", style: this.menuText,),
                onTap: () => this._navTo("Goals"),
              ),
              new ListTile(
                leading: new Icon(Icons.alarm, color: Colors.white,),
                title: new Text("About", style: this.menuText,),
                onTap: () => this._navTo("About"),
              ),
              new ListTile(
                leading: new Icon(Icons.exit_to_app, color: Colors.white,),
                title: new Text("Sign Out", style: this.menuText,),
                onTap: () {
                  /// Sign the user out, reset _curUser, and call setState:
                  _auth.signOut().then((e) => setState(() { _curUser = null; }));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}