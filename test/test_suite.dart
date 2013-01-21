library rt_test_suite;

import 'package:unittest/unittest.dart';
import 'package:vector_math/vector_math_console.dart';
import '../math/algebra.dart';

import '../rt/basics.dart';
import '../rt/renderer.dart';
import '../rt/scene.dart';

part 'algebra_test.dart';
part 'ray_test.dart';
part 'prim_test.dart';
part 'output_matrix_test.dart';

/**
 * Registers all test sets and executes the test suite afterwards.
 */
void main() {
  testSets = new List();

  TestSet at = new AlgebraTests();
  TestSet pt = new PrimTests();
  TestSet rt = new RayTests();
  TestSet omt = new OutputMatrixTests();

  testSets.addAll([at, rt, pt, omt]);

  runTests();
}

/// Contains all registered test sets.
List<TestSet> testSets;

/**
 * Registers the given test set for execution.
 */
void registerTestSet(TestSet set) => testSets.add(set);

/**
 * Executes the test suite.
 */
void runTests() {
  // For each test set, createa a test group with the set's name,
  // initialize the tests and create test calls for each test function
  // offered by the set.
  for (TestSet set in testSets) {
    group(set.name, () {
      setUp(set.initTests);
      set.testFunctions.forEach((k,v) {
        test(k, v);
      });
    });
  }
}

/**
 * Any set of tests should inherit from TestSet.
 * It offers methods for the test suite to automatically discover and
 * perform its test functions.
 *
 * This allows variable encapsulation to easily create and integrate large
 * test suites.
 */
abstract class TestSet {
  /// Returns the designated name of this test set.
  String get name;

  /**
   * Initializes any requirements for the tests to run.
   */
  void initTests();

  /**
   * Returns a map containing test function names and associated function calls.
   */
  //TODO Use Reflection/Mirror API once available in Dart.
  Map<String, Function> get testFunctions;
}