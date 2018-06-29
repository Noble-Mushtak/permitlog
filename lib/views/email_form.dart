import 'package:flutter/material.dart';

/// View that shows a form for the user to enter their e-mail and password.
class EmailForm extends StatefulWidget {
  /// Stores the form key and controllers to be used in this widget.
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController, passwordController;
  /// Takes in the form key and controllers to be used in this widget.
  EmailForm({@required GlobalKey<FormState> key, @required TextEditingController emailController, @required TextEditingController passwordController}) :
        formKey = key,
        emailController = emailController,
        passwordController = passwordController;

  /// Creates the state for this widget.
  @override
  State<StatefulWidget> createState() => new _EmailFormState(formKey, emailController, passwordController);
}

class _EmailFormState extends State<EmailForm> {
  /// This key is used to validate the form.
  final GlobalKey<FormState> formKey;
  /// These controllers store the user's e-mail and password.
  final TextEditingController emailController, passwordController;
  /// Regexp to identify e-mail pattern.
  /// https://html.spec.whatwg.org/multipage/input.html#e-mail-state-(type%3Demail)
  final RegExp emailFormat = new RegExp(r"""^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$""");
  /// Takes in the form key and controllers to be used in this state.
  _EmailFormState(GlobalKey<FormState> formKey, TextEditingController emailController, TextEditingController passwordController) :
        formKey = formKey,
        emailController = emailController,
        passwordController = passwordController;

  @override
  Widget build(BuildContext context) {
    return new Form(
      key: formKey,
      /// Put the column in a ScrollView to avoid errors about space limits.
      child: new SingleChildScrollView(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text("Please enter your e-mail and password."),
            new TextFormField(
              decoration: new InputDecoration(hintText: "E-mail"),
              controller: emailController,
              /// Make sure the input is an e-mail.
              validator: (String val) => !emailFormat.hasMatch(val) ? 'Please enter a valid e-mail.' : null
            ),
            new TextFormField(
              decoration: new InputDecoration(hintText: "Password"),
              obscureText: true,
              controller: passwordController,
              /// Make sure the input is at least 6 characters (Firebase requirement).
              validator: (String val) => val.length < 6 ? 'Password needs >=6 characters.' : null
            )
          ],
        )
      )
    );
  }
}