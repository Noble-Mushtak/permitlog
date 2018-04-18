import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// View describing the purpose of our app and the tools it uses. See below
/// for how links are generated. Ideally, we would create a class extending
/// [TextSpan] that sets the style and onTap properly.
class AboutView extends StatelessWidget {

  /// Styles used to render PermitLog's about page, which used to be HTML.
  /// In order to render links (HTML anchor tags), blue-coloured [TextSpan]s
  /// are used with [TapGestureRecognizer.onTap] and call [url_launcher.launch]
  /// to open the link.
  final h2 = new TextStyle(fontSize: 24.0,);
  final para = new TextStyle(fontSize: 16.0, color: Colors.black,);
  final link = new TextStyle(fontSize: 16.0, color: Colors.blueAccent,);

  /// Build up the about screen's contents as a single [RichText] widget
  /// with nested [TextSpan] widgets.
  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.all(8.0),
      child: new ListView(
        children: <Widget>[
          new RichText(
              text: new TextSpan(
                style: this.para,
                children: [
                  new TextSpan(
                    text: "What is this app?\n",
                    style: this.h2,
                  ),
                  new TextSpan(
                    text: "The Permit Log mobile app helps teen drivers with learner's permits accurately and easily record their driving hours. It keeps a running total of the number of hours driven and tracks all of the data required for a permit log. When the permit-holder completes all of their required hours, they can export them, either in a generic spreadsheet format or using the Maine-specific form, then print it out and send it to the DMV.\n",
                  ),
                  new TextSpan(
                    text: "Watch our video presentation to learn more.\n",
                    style: this.link,
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () => launch("https://youtu.be/Rr6QkbFO8R8"),
                  ),
                  new TextSpan(
                    text: "\nWhy did we make this?\n",
                    style: this.h2,
                  ),
                  new TextSpan(
                    text: "Every teen that wants to drive must fill out a permit log. Filling out a paper permit log, however, is not very efficient. A paper log can be easily lost, damaged, or forgotten. Other non-cloud based electronic methods aren't much better since data can be accidentally deleted and copying the hours by hand once you're done is a long and tedious process. This is the problem that Permit Log sets out to fix. Our app can automatically time your drives, syncs with the cloud as well as between phones, and can export your form automatically. All you have to do is print, sign, and mail it to the DMV.\n",
                  ),
                  new TextSpan(
                    text: "\nReferences\n",
                    style: this.h2,
                  ),
                  new TextSpan(
                    text: "This app was made using Android Studio. In order to store the user's information in the cloud, we used ",
                  ),
                  new TextSpan(
                    text: "Firebase",
                    style: this.link,
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () => launch("https://firebase.google.com/"),
                  ),
                  new TextSpan(
                    text: " as our database. Thanks Sacha Kiesman, Abby Kaye, Jay Whitesell, and Stephen Rezack for appearing in our video! The music we used in the video is Thinking Music and Local Forecast by Kevin MacLeod ",
                  ),
                  new TextSpan(
                    text: "(incompetech.com)",
                    style: this.link,
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () => launch("http://incompetech.com"),
                  ),
                  new TextSpan(
                    text: " and licensed under Creative Commons: By Attribution 3.0.\n",
                  ),
                  new TextSpan(
                    text: "\nThere's a problem with the app!\n",
                    style: this.h2,
                  ),
                  new TextSpan(
                    text: "If you have any suggestions or bugs with the app, please tell us about it at ",
                  ),
                  new TextSpan(
                    text: "teamredundancyteam2@gmail.com",
                    style: this.link,
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () => launch("mailto:teamredundancyteam2@gmail.com"),
                  ),
                  new TextSpan(
                    text: ". Please include the fact that you are using version 1.15 in your bug report.",
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
}
