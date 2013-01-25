library rt_test_suite;

import 'package:unittest/unittest.dart';
import 'package:vector_math/vector_math_console.dart';
import 'test_framework.dart';
import '../math/algebra.dart';

import '../rt/basics.dart';
import '../rt/renderer.dart';
import '../rt/scene.dart';

part 'ray_test.dart';
part 'prim_test.dart';
part 'output_matrix_test.dart';

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