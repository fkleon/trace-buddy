#!/usr/bin/env dart

/** Build logic that lets the Dart editor build the app in the background. */
library build;
import 'package:web_ui/component_build.dart';
import 'dart:io';

void main() {
  build(new Options().arguments,
      ['web/TraceBuddy.html']);
}