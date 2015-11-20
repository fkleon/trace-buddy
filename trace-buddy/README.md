trace-buddy
===========

The ray tracing core library. It can be used as a standalone library, or with
the web front end `trace-buddy-app`, which offers a rudimentary graphical user
interface.

Currently there is no support to import any common 3d model formats, and scenes
have to be defined in code.

### Developing

After importing the project in your editor of choice, run the unit test suites
to make sure that everything is set up correctly, or run:

`pub run test`

### Examples

You can find an example of trace-buddy used as a standalone ray tracer in
[standalone.dart](example/standalone.dart).
