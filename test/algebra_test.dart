part of rt_test_suite;

/**
 * Contains methods to test the math algebra implementation.
 */
// TODO interval arithmetic tests
class AlgebraTests extends TestSet {

  get name => 'Algebra Tests';

  get testFunctions => {
    'Point Creation': pointCreation,
    'Point Equality': pointEquality,
    'Point Subtraction': pointSubtraction,
    'Point Addition': pointAddition,
    'Point LERP': pointLerp
  };

  // Initialises the test points and vectors
  void initTests() {
    // do some funky stuff
    p0 = new Point3D.zero();
    p1 = new Point3D(1,2,3);
    p2 = new Point3D(4,-5,7);
    v1 = new vec3.raw(1,-2,5);
    v2 = new vec3.raw(-1,0,-7);
  }

  /*
   *  Tests and variables.
   */
  Point3D p0,p1,p2;
  vec3 v1,v2;

  // Tests the expected state after point creation.
  pointCreation() {
    expect(p0.x, equals(0));
    expect(p0.y, equals(0));
    expect(p0.z, equals(0));

    expect(p1.x, equals(1));
    expect(p1.y, equals(2));
    expect(p1.z, equals(3));

    expect(p2.x, equals(4));
    expect(p2.y, equals(-5));
    expect(p2.z, equals(7));
  }

  // Tests the point equality operator.
  pointEquality() {
    expect(p0 == p0, isTrue);
    expect(p0 == p1, isFalse);
    expect(p1 == p0, isFalse);
    expect(p1 == p2, isFalse);
    expect(p2 == p2, isTrue);
  }

  // Tests the unary minus and point subtraction operators.
  pointSubtraction() {
    // unary minus
    Point3D pMinus = -p0;
    expect(pMinus.x, equals(0));
    expect(pMinus.y, equals(0));
    expect(pMinus.z, equals(0));

    pMinus = -p2;
    expect(pMinus.x, equals(-p2.x));
    expect(pMinus.y, equals(-p2.y));
    expect(pMinus.z, equals(-p2.z));

    // subtraction
    var diff = p1-p0;
    expect(diff.x, equals(p1.x));
    expect(diff.y, equals(p1.y));
    expect(diff.z, equals(p1.z));

    diff = p0-p1;
    expect(diff.x, equals(-p1.x));
    expect(diff.y, equals(-p1.y));
    expect(diff.z, equals(-p1.z));

    diff = p1-p2;
    expect(diff.x, equals(p1.x-p2.x));
    expect(diff.y, equals(p1.y-p2.y));
    expect(diff.z, equals(p1.z-p2.z));
  }

  // Tests the point addition operator.
  pointAddition() {
    var add = p1+v1;
    expect(add.x, equals(p1.x+v1.x));
    expect(add.y, equals(p1.y+v1.y));
    expect(add.z, equals(p1.z+v1.z));

    add = p0+v2;
    expect(add.x, equals(v2.x));
    expect(add.y, equals(v2.y));
    expect(add.z, equals(v2.z));
  }

  // Tests the linear interpolation of points.
  pointLerp() {
    var coeff = 0.6;
    var lerped = p1.lerp(p0, coeff);
    expect(lerped.x, equals(p1.x*coeff));
    expect(lerped.y, equals(p1.y*coeff));
    expect(lerped.z, equals(p1.z*coeff));

    coeff = 0.41;
    lerped = p1.lerp(p2, coeff);
    expect(lerped.x, closeTo(2.77, EPS));
    expect(lerped.y, closeTo(-2.13, EPS));
    expect(lerped.z, closeTo(5.36, EPS));
  }
}