trace-buddy-app
===========

The web app of TraceBuddy, acting as GUI for the core ray tracing library.

### Developing

This app is build with [Web UI](https://pub.dartlang.org/packages/web_ui), the
predecessor of [Polymer.dart](https://pub.dartlang.org/packages/polymer).

Since TraceBuddy was initially written, Web UI has been long deprecated and is
not under development anymore. This app remains as Proof-of-Concept, and will
possibly be updated or re-written in the future.

#### Building

When used with the Dart Editor, the `build.dart` script of trace-buddy-app
automatically compiles the web_ui components to `web/out/`.

Otherwise run `pub run tool/build.dart` to build the application.

#### Running

Once the app is built, you can deploy it via the web server of your choice, or
use pub's development server to access it:

`pub serve`

Then go to <http://localhost:8080/out/web/TraceBuddy.html> in your browser.
