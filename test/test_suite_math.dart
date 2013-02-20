library math_test_suite;

import 'dart:math' as Math;

import 'package:unittest/unittest.dart';
import 'package:vector_math/vector_math.dart';

import 'test_framework.dart';
import '../math/algebra.dart' as Alg;
import '../math/math_expressions.dart';

part 'algebra_test.dart';
part 'expression_test.dart';
part 'parser_test.dart';

/// relative accuracy for floating-point calculations
const num EPS = 0.000001;

/**
 * Registers all math test sets and executes the test suite afterwards.
 */
void main() {
  var testSets = [new AlgebraTests(),
                  new ExpressionTests(),
                  new ParserTests()];

  new TestExecutor.initWith(testSets).runTests();
}