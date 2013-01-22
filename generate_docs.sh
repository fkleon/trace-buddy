#!/bin/bash

dartdoc="/home/freddy/Downloads/dart/dart-sdk/bin/dartdoc"

$dartdoc --no-show-private --no-code --out ./docs --exclude-lib dd_entry,unittest,mock,matcher,vector_math_console,vector_math_html -v "dartdoc_entry_point.dart"
