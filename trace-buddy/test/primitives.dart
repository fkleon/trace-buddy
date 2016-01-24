part of tracebuddy_test_suite;

/**
 * Contains a test set for primitive creation and intersection methods.
 */
class PrimTests extends TestSet {

  get name => 'Primitive Tests';

  get testFunctions => {
    'Sphere Creation Valid': sphereCreationValid,
    'Sphere Creation Invalid': sphereCreationInvalid,
    'Sphere Intersection': sphereIntersection,
    'Plane Creation': infinitePlaneCreation,
    'Plane Intersection': infinitePlaneIntersection
  };

  void initTests() {
    prim_origin = new Point3.zero();
    prim_s1 = new Sphere(new Point3(10.0, 0.0, 0.0), 1);
    prim_s2 = new Sphere(new Point3(-10.0, -10.0, -10.0), 2);
    prim_p1 = new InfinitePlane(new Point3(0.0, 2.0, 0.0), new Vector3(0.0, 1.0, 0.0));
    prim_r1 = new Ray(prim_origin, new Vector3(1.0, 0.0, 0.0));
    prim_r2 = new Ray(prim_origin, new Vector3(10.0, 1.0, 0.0).normalize());
    prim_r3 = new Ray(prim_origin, new Vector3(10.0, 2.0, 0.0));
    prim_r4 = new Ray(prim_origin, new Vector3(0.0, 1.0, 0.0));
  }

  /**
   * Tests for Vector4 equality based on member equality.
   */
  bool isEqual(Vector4 x, Vector4 y)
  => x.x == y.x && x.y == y.y && x.z == y.z && x.w == y.w;

  /*
   *  Tests and variables.
   */
  Sphere prim_s1, prim_s2;
  InfinitePlane prim_p1, prim_p2;
  Ray prim_r1, prim_r2, prim_r3, prim_r4;
  Point3 prim_origin;

  void sphereCreationValid(){
    expect(prim_s1.center, equals(new Point3(10.0, 0.0, 0.0)));
    expect(prim_s1.radius, equals(1));
    expect(prim_s2.center, equals(new Point3(-10.0, -10.0, -10.0)));
    expect(prim_s2.radius, equals(2));
  }

  void sphereCreationInvalid(){
    expect(()=> new Sphere(prim_origin, -1), throwsArgumentError);
    expect(()=> new Sphere(prim_origin, 0), throwsArgumentError);
  }

  void sphereIntersection(){
    Intersection i1 = prim_s1.intersect(prim_r1, 999999999);
    expect(i1.distance, closeTo(9, EPS));
    expect(i1.prim,equals(prim_s1));

    Intersection i2 = prim_s1.intersect(prim_r2, 999999999);
    expect(i2.distance, closeTo(9.85086818, EPS));
    expect(i2.prim,equals(prim_s1));
  }

  void infinitePlaneCreation(){
    expect(isEqual(prim_p1.equation, new Vector4(0.0, 1.0, 0.0, -2.0)), isTrue);
  }

  void infinitePlaneIntersection(){
    Intersection i3 = prim_p1.intersect(prim_r4, 999999999);
    expect(i3.distance, closeTo(2, EPS));
    expect(i3.prim,equals(prim_p1));
  }
}
