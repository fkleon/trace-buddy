#!/bin/bash

# Path to dartdoc executable
dartdoc="/home/freddy/Downloads/dart/dart-sdk/bin/dartdoc"

# Creates dart doc, excludes third party libraries from drocumentation
$dartdoc --no-show-private --no-code --out ./docs --exclude-lib dd_entry,unittest,mock,matcher,vector_math_browser,vector_math_console,vector_math_html -v "dartdoc_entry_point.dart"
