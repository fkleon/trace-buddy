#!/usr/bin/env dart

/** Build logic that lets the Dart editor build the app in the background. */
import 'dart:io';
import 'package:web_ui/component_build.dart';

main() {
  var args = new Options().arguments.toList();
  args.addAll(['--', '--basedir', '.']);
  build(args, ['web/TraceBuddy.html']);
}