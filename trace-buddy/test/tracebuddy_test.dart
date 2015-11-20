library tracebuddy_test_suite;

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart' hide Ray, Sphere;
import 'package:math_expressions/math_expressions.dart';

import 'test_framework.dart';

import '../lib/tracebuddy.dart';

part 'ray.dart';
part 'primitives.dart';
part 'output_matrix.dart';

/**
 * Registers all ray tracing test sets and executes the test suite afterwards.
 */
void main() {
  var testSets = [new PrimTests(),
                  new RayTests(),
                  new BBoxTests(),
                  new OutputMatrixTests()];

  new TestExecutor.initWith(testSets).runTests();
}
