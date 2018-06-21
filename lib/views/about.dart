import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// View describing the purpose of our app and the tools it uses. See below
/// for how links are generated. Ideally, we would create a class extending
/// [TextSpan] that sets the style and onTap properly.
class AboutView extends StatelessWidget {
  /// Build up the about screen's contents, a single [Markdown] widget that
  /// has the app's about text, [_aboutText], formatted with markdown syntax.
  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: new EdgeInsets.all(8.0),
      child: new Markdown(
        data: _aboutText,
        onTapLink: (href) {
          // When the user taps a hyperlink open it.
          launch(href);
        },
      ),
    );
  }

  /// Content for the about page.
  final String _aboutText = "# What is this app?\n"
      "The Permit Log mobile app helps teen drivers with learner's permits "
      "accurately and easily record their driving hours. It keeps a running "
      "total of the number of hours driven and tracks all of the data required "
      "for a permit log. When the permit-holder completes all of their required"
      " hours, they can export them, either in a generic spreadsheet format or "
      "using the Maine-specific form, then print it out and send it to the DMV."
      " Watch our [video presentation](https://youtu.be/Rr6QkbFO8R8) to learn "
      "more.\n"
      "# Why did we make this?\n"
      "Every teen that wants to drive must fill out a permit log. Filling out a"
      " paper permit log, however, is not very efficient. A paper log can be "
      "easily lost, damaged, or forgotten. Other non-cloud based electronic "
      "methods aren't much better since data can be accidentally deleted and "
      "copying the hours by hand once you're done is a long and tedious process."
      " This is the problem that Permit Log sets out to fix. Our app can "
      "automatically time your drives, syncs with the cloud as well as between "
      "phones, and can export your form automatically. All you have to do is "
      "print, sign, and mail it to the DMV.\n"
      "# References\n"
      "This app was made using Android Studio and Flutter. In order to store "
      "the user's information in the cloud, we used [Firebase]"
      "(https://firebase.google.com/) as our database. Thanks Sacha Kiesman, "
      "Abby Kaye, Jay Whitesell, and Stephen Rezack for appearing in our video!"
      " The music we used in the video is Thinking Music and Local Forecast by "
      "[Kevin MacLeod](http://incompetech.com)  and licensed under Creative "
      "Commons: By Attribution 3.0.\n"
      "# There's a problem with the app!\n"
      "If you have any suggestions or bugs with the app, please tell us about "
      "it at [teamredundancyteam2@gmail.com]"
      "(mailto:teamredundancyteam2@gmail.com). Please include the fact that you"
      " are using version 1.15 in your bug report.";
}
