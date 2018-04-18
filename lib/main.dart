import 'package:flutter/material.dart';

import 'views/about.dart';
import 'views/home.dart';
import 'views/log.dart';
import 'views/supervisors.dart';

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
  /// Style for [Drawer] menu items.
  final TextStyle menuText = new TextStyle(color: Colors.white);

  /// Content for the current state.
  var title = 'Home';
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
        default:
          break;
      }
    });
    Navigator.pop(context);
  }

  /// Builds the current state.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(this.title),
        backgroundColor: Colors.blueAccent,
      ),
      body: this.content,
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
                leading: new Icon(Icons.alarm, color: Colors.white,),
                title: new Text("About", style: this.menuText,),
                onTap: () => this._navTo("About"),
              ),
              new ListTile(
                leading: new Icon(Icons.exit_to_app, color: Colors.white,),
                title: new Text("Sign Out", style: this.menuText,),
                onTap: () {
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