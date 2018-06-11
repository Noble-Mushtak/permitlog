import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'views/about.dart';
import 'views/emailform.dart';
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

/// Enum representing the different tabs in the drawer.
enum _PermitLogTabs {
  home,
  log,
  supervisors,
  about,
  goals
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
  void _navTo(_PermitLogTabs tab, {bool fromDrawer = false}) {
    setState(() {
      switch(tab) {
        case _PermitLogTabs.home:
          this.title = "Home";
          this.content = new HomeView();
          break;
        case _PermitLogTabs.log:
          this.title = "Log";
          this.content = new LogView();
          break;
        case _PermitLogTabs.supervisors:
          this.title = "Supervisors";
          this.content = new SupervisorsView();
          break;
        case _PermitLogTabs.about:
          this.title = "About";
          this.content = new AboutView();
          break;
        case _PermitLogTabs.goals:
          this.title = "Goals";
          this.content = new GoalsView();
          break;
        default:
          break;
      }
    });
    /// If this method was called because the user clicked one of the drawer tabs,
    /// close the drawer.
    if (fromDrawer) Navigator.pop(context);
  }

  /// Tells the user that authentication failed and they need to try again.
  void _tryAuthenticationAgain(BuildContext context, [String message]) {
    Scaffold.of(context).removeCurrentSnackBar();
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text(message ?? "Authentication failed. Please try again")
    ));
  }

  /// Update _curUser and transition to HomeFragment
  void _updateUser(FirebaseUser user) {
    _curUser = user;
    _navTo(_PermitLogTabs.home);
  }

  /// Call _updateUser and then exit dialog
  void _updateUserAndExit(FirebaseUser user) {
    _updateUser(user);
    Navigator.pop(context);
  }

  /// Authenticates the user using Google sign-in.
  Future<void> _authenticateUserGoogle(BuildContext context) async {
    /// This object represents the user in the Google API.
    GoogleSignInAccount googleUser = _googleSignIn.currentUser;

    /// If the user is not signed in, sign the user in using an interactive dialog:
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
    await _auth.signInWithGoogle(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken
    ).then(_updateUser)
    /// If there is an error, retry authentication.
    .catchError((Object error) => _tryAuthenticationAgain(context));
  }

  Future<void> _authenticateUserEmail(BuildContext outerContext) async {
    /// Create the key and controllers necessary for an e-mail form.
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    TextEditingController emailController = new TextEditingController();
    TextEditingController passwordController = new TextEditingController();
    /// Ask the user to enter the e-mail and password.
    await showDialog<void>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext context) => new AlertDialog(
        content: new EmailForm(
          key: formKey,
          emailController: emailController,
          passwordController: passwordController
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text("Sign In"),
            onPressed: () async {
              /// Validate the form.
              if (formKey.currentState.validate()) {
                /// Finally, try to sign the user in with the e-mail and password
                String email = emailController.text, password = passwordController.text;
                _auth.signInWithEmailAndPassword(email: email, password: password)
                  .then(_updateUserAndExit, onError: (Object error) async {
                    /// If this is a PlatformException:
                    if (error is PlatformException) {
                      /// If this is because the user does not exist,
                      /// then try creating the user.
                      if (error.message.contains("There is no user record corresponding to this identifier. The user may have been deleted.")) {
                        await _auth.createUserWithEmailAndPassword(email: email, password: password)
                          .then(_updateUserAndExit);
                        return;
                      }
                    }
                    /// If the error has not been dealt with, rethrow it.
                    throw error;
                  })
                  .catchError((Object error) { /// If there is another error...
                    /// Create an error message to show the user.
                    String message;
                    /// If this is a PlatformException, print message for debugging.
                    if (error is PlatformException) {
                      print(error.message);
                      /// Invalid e-mail message:
                      if (error.message.contains("The email address is badly formatted.")) {
                        message = "Please enter a valid e-mail.";
                      }
                      /// Invalid password message:
                      if (error.message.contains("The password is invalid or the user does not have a password.")) {
                        message = "Invalid password.";
                      }
                    }
                    /// Try authentication again.
                    _tryAuthenticationAgain(outerContext, message);
                  });
              }
            }
          )
        ],
      )
    );
  }

  Future<void> _authenticateUserFacebook(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => new AlertDialog(
        content: new Text("Coming soon!")
      )
    );
  }

  /// Authenticates the user using one of the sign-in options.
  Future<void> _authenticateUser(BuildContext context) async {
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
    /// Keep trying to authenticate the user until it works:
    while (await _auth.currentUser() == null) {
      /// Call different authentication methods depending on what is chosen:
      switch (option) {
      case _SignInOptions.google:
        await _authenticateUserGoogle(context);
        break;
      case _SignInOptions.email:
        await _authenticateUserEmail(context);
        break;
      case _SignInOptions.facebook:
        await _authenticateUserFacebook(context);
        break;
      }
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
                onTap: () => this._navTo(_PermitLogTabs.home, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.assignment, color: Colors.white,),
                title: new Text("Log", style: this.menuText,),
                onTap: () => this._navTo(_PermitLogTabs.log, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.supervisor_account, color: Colors.white,),
                title: new Text("Supervisors", style: this.menuText,),
                onTap: () => this._navTo(_PermitLogTabs.supervisors, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.settings, color: Colors.white,),
                title: new Text("Goals", style: this.menuText,),
                onTap: () => this._navTo(_PermitLogTabs.goals, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.alarm, color: Colors.white,),
                title: new Text("About", style: this.menuText,),
                onTap: () => this._navTo(_PermitLogTabs.about, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.exit_to_app, color: Colors.white,),
                title: new Text("Sign Out", style: this.menuText,),
                onTap: () {
                  /// Sign the user out, reset _curUser, and call setState:
                  _auth.signOut().then((e) => setState(() { _curUser = null; }));
                  /// Close the drawer
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