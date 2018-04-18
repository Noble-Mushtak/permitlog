import 'package:flutter/material.dart';

import 'views/about.dart';

/// Main function, creates a new [MaterialApp] 
void main() {
  runApp(
    new MaterialApp(
      home: new PermitLog(),
      title: 'PermitLog',
    )
  );
}

// TODO: document
class PermitLog extends StatefulWidget {
  // Todo: docs
  @override
  State<StatefulWidget> createState() => new _PermitLogState();
}

// Todo: docs
class _PermitLogState extends State<PermitLog> {
  final TextStyle menuText = new TextStyle(color: Colors.white);

  var title = 'Home';
  Widget content = new Center(child: new Text('changeme'),);

  void navTo(String view) {
    setState(() {
      this.title = view;
      switch(view.toLowerCase()) {
        case 'about':
          this.content = new AboutView();
          break;
      }
    });
    Navigator.pop(context);
  }

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
                onTap: () => this.navTo("Home"),
              ),
              new ListTile(
                leading: new Icon(Icons.assignment, color: Colors.white,),
                title: new Text("Log", style: this.menuText,),
                onTap: () => this.navTo("Log"),
              ),
              new ListTile(
                leading: new Icon(Icons.supervisor_account, color: Colors.white,),
                title: new Text("Supervisors", style: this.menuText,),
                onTap: () => this.navTo("Supervisors"),
              ),
              new ListTile(
                leading: new Icon(Icons.alarm, color: Colors.white,),
                title: new Text("About", style: this.menuText,),
                onTap: () => this.navTo("About"),
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