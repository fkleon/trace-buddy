library rt_test_suite;

import 'package:/unittest/unittest.dart';
import 'package:vector_math/vector_math_console.dart';
import '../math/algebra.dart';

import '../rt/basics.dart';
import '../rt/renderer.dart';

part 'algebra_test.dart';
part 'ray_test.dart';
part 'output_matrix_test.dart';

/**
 * Executes the test suite.
 */
void main() {
  group('Algebra Tests', () {
    setUp(initAlgebraTests);
    test('Point Creation', pointCreation);
    test('Point Equality', pointEquality);
    test('Point Subtraction', pointSubtraction);
    test('Point Addition', pointAddition);
    test('Point LERP', pointLerp);
  });
  group('Ray Tests', () {
    setUp(initRayTests);
    test('Ray Creation', rayCreation);
    test('Ray Position', rayPosition);
  });
  group('Output Matrix Tests', () {
    setUp(initMatrixTests);
    test('Matrix Creation', matrixCreation);
    test('Matrix Manipulation', matrixManipulation);
    test('Matrix Clear', matrixClear);
  });
}