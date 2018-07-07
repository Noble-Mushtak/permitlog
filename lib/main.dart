import 'dart:async';

import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permitlog/utilities.dart';

import 'views/about.dart';
import 'views/add_log.dart';
import 'views/add_supervisor.dart';
import 'views/email_form.dart';
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

/// Enum representing the different tabs in the drawer.
enum _PermitLogTabs {
  home,
  log,
  supervisors,
  about,
  goals
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
  /// Facebook Login API Interface
  final FacebookLogin _facebookLogin = new FacebookLogin();

  /// Style for [Drawer] menu items.
  final TextStyle _menuText = new TextStyle(color: Colors.white);

  /// Content for the current state.
  String _title = 'Home';
  Widget _content = new HomeView();
  _PermitLogTabs _curTab = _PermitLogTabs.home;

  /// Sets the [AppBar]'s title and navigates to the view indicated.
  void _navTo(_PermitLogTabs tab, {bool fromDrawer = false}) {
    setState(() {
      // Update _curTab
      _curTab = tab;
      switch(tab) {
        case _PermitLogTabs.home:
          this._title = "Home";
          this._content = new HomeView();
          break;
        case _PermitLogTabs.log:
          this._title = "Log";
          this._content = new LogView();
          break;
        case _PermitLogTabs.supervisors:
          this._title = "Supervisors";
          this._content = new SupervisorsView();
          break;
        case _PermitLogTabs.about:
          this._title = "About";
          this._content = new AboutView();
          break;
        case _PermitLogTabs.goals:
          this._title = "Goals";
          this._content = new GoalsView();
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
    /// Try to sign the user into Google.
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    /// If authentication failed, tell the user to try again and do not go on.
    if (googleUser == null) {
      _tryAuthenticationAgain(context);
      return;
    }

    /// Get the object with the user's data.
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    /// Update _curUser by signing in with the Google token.
    await _auth.signInWithGoogle(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken
    ).then(_updateUser)
    /// If there is an error, retry authentication.
    .catchError((dynamic error) => _tryAuthenticationAgain(context));
  }

  /// Authenticates user using e-mail and password dialog.
  Future<void> _authenticateUserEmail(BuildContext outerContext) async {
    /// Create the key and controllers necessary for an e-mail form.
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    TextEditingController emailController = new TextEditingController();
    TextEditingController passwordController = new TextEditingController();
    /// Ask the user to enter the e-mail and password.
    await showDialog<void>(
      context: outerContext,
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
                  .then(_updateUserAndExit, onError: (dynamic error) async {
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
                  .catchError((dynamic error) { /// If there is another error...
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
    /// If authentication failed, tell the user to try again.
    if (await _auth.currentUser() == null) {
      _tryAuthenticationAgain(outerContext);
    }
  }

  /// Authenticates user using Facebook login.
  Future<void> _authenticateUserFacebook(BuildContext context) async {
    /// Try to log the user into Facebook.
    FacebookLoginResult result = await _facebookLogin.logInWithReadPermissions(["email"]);
    /// If authentication failed, tell the user to try again and do not go on.
    if (result.status != FacebookLoginStatus.loggedIn) {
      _tryAuthenticationAgain(context);
      return;
    }
    /// Update _curUser by signing in with the Facebook token.
    await _auth.signInWithFacebook(accessToken: result.accessToken.token).then(_updateUser)
    /// If there is an error, tell user authentication failed.
    .catchError((dynamic error) => _tryAuthenticationAgain(context));
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

    /// Keep trying to authenticate the user until it works:
    while (await _auth.currentUser() == null) {
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
    /// Once authentication succeeds, tell the user.
    Scaffold.of(context).removeCurrentSnackBar();
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Authentication succeeded.")
    ));
  }

  /// Opens a new widget after dialog option is selected using builder function
  void _navigateRoute(BuildContext outerContext, Widget Function(BuildContext) builder) {
    /// Closes the dialog
    Navigator.pop(context);
    /// Create a route using builder function
    MaterialPageRoute<String> route = new MaterialPageRoute<String>(
      builder: builder
    );
    /// When the view is done, show the resulting message.
    route.popped.then((String msg) => showNonEmptyMessage(outerContext, msg));
    /// Navigate to the route.
    Navigator.push(context, route);
  }

  /// Shows dialog to add supervisor or drive when fab is clicked in Home tab
  void _showAddDialog(BuildContext outerContext) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => new AlertDialog(
        content: new Text("Would you like to add a supervisor or a drive log?"),
        actions: <Widget>[
          new FlatButton(
            child: new Text("Add Supervisor"),
            /// Navigate to AddSupervisorView
            onPressed: () {
              _navigateRoute(outerContext, (context) => new AddSupervisorView());
            }
          ),
          new FlatButton(
            child: new Text("Add Drive Log"),
            /// Navigate to AddLogView
            onPressed: () {
            _navigateRoute(outerContext, (context) => new AddLogView());
            }
          )
        ],
      )
    );
  }

  /// Builds the current state.
  @override
  Widget build(BuildContext context) {
    /// The FloatingActionButton at the bottom-right side of the screen
    Widget fab;
    if (_curTab == _PermitLogTabs.home) {
      /// Allow the user to add supervisor/drive from Home tab
      fab = new Builder(
        builder: (BuildContext context) => new FloatingActionButton.extended(
          /// Pass the context into _showAddDialog for SnackBar
          onPressed: () => _showAddDialog(context),
          label: new Text("Add Supervisor or Drive"),
          icon: new Icon(Icons.add_circle, color: Colors.white),
          backgroundColor: new Color.fromARGB(255, 255, 87, 34),
        )
      );
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(this._title),
        backgroundColor: Colors.blueAccent,
      ),
      /// Authenticate the user inside a Builder
      /// so that the context has access to the Scaffold.
      body: new Builder(
        builder: (BuildContext context) {
          /// Try to authenticate the user as soon as possible:
          if (_curUser == null) _authenticateUser(context);

          return this._content;
        }
      ),
      drawer: new Drawer(
        child: new Container(
          color: Colors.blueAccent,
          child: new ListView(
            children: <Widget>[
              new ListTile(
                leading: new Icon(Icons.home, color: Colors.white,),
                title: new Text("Home", style: this._menuText,),
                onTap: () => this._navTo(_PermitLogTabs.home, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.assignment, color: Colors.white,),
                title: new Text("Log", style: this._menuText,),
                onTap: () => this._navTo(_PermitLogTabs.log, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.supervisor_account, color: Colors.white,),
                title: new Text("Supervisors", style: this._menuText,),
                onTap: () => this._navTo(_PermitLogTabs.supervisors, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.settings, color: Colors.white,),
                title: new Text("Goals", style: this._menuText,),
                onTap: () => this._navTo(_PermitLogTabs.goals, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.alarm, color: Colors.white,),
                title: new Text("About", style: this._menuText,),
                onTap: () => this._navTo(_PermitLogTabs.about, fromDrawer: true),
              ),
              new ListTile(
                leading: new Icon(Icons.exit_to_app, color: Colors.white,),
                title: new Text("Sign Out", style: this._menuText,),
                onTap: () {
                  /// Sign the user out, reset _curUser, and call setState.
                  _googleSignIn.signOut();
                  _facebookLogin.logOut();
                  _auth.signOut().then((void _) => setState(() { _curUser = null; }));
                  /// Close the drawer.
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: fab
    );
  }
}