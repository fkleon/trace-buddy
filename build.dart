#!/usr/bin/env dart

/** Build logic that lets the Dart editor build the app in the background. */
import 'package:web_ui/component_build.dart';
import 'dart:io';

main() =>
  build(new Options().arguments,
      ['web/TraceBuddy.html'],
      baseDir: "rt");