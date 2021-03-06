part of tracebuddy_test_suite;

/**
 * Contains a test set for the ray implementation.
 */
class RayTests extends TestSet {

  get name => 'Ray Tests';

  get testFunctions => {
    'Ray Creation': rayCreation,
    'Ray Position': rayPosition
  };

  void initTests() {
    r1 = new Ray(new Point3.zero(), new Vector3(1.0,0.0,0.0));
    r2 = new Ray(new Point3(1.0,-1.0,1.0), new Vector3(0.0,1.0,0.0));
  }

  /*
   *  Tests and variables.
   */
  Ray r1, r2;

  rayCreation() {
    expect(r1.origin, equals(new Vector3.zero()));
    expect(r1.direction.x, equals(1));
    expect(r1.direction.y, equals(0));
    expect(r1.direction.z, equals(0));

    expect(r2.origin, equals(new Vector3(1.0,-1.0,1.0)));
    expect(r2.direction.x, equals(0));
    expect(r2.direction.y, equals(1));
    expect(r2.direction.z, equals(0));
  }

  rayPosition() {
    expect(r1.getPoint3(5.0), equals(new Point3(5.0, 0.0, 0.0)));
    expect(r1.getPoint3(-0.66).x, closeTo(-0.66, EPS));
    expect(r1.getPoint3(0.0), equals(new Point3.zero()));

    expect(r2.getPoint3(3.0), equals(new Point3(1.0, 2.0, 1.0)));
    expect(r2.getPoint3(-0.66).y, closeTo(-1.66, EPS));
    expect(r2.getPoint3(-0.0), equals(new Point3(1.0, -1.0, 1.0)));
  }
}

/**
 * Contains a test set for the Bounding Box implementation.
 */
class BBoxTests extends TestSet {

  get name => 'BBox Tests';

  get testFunctions => {
    'BBox Creation': bboxCreation,
    'BBox Extension': bboxExtension,
    'BBox Intersection Aligned': bboxIntersectAligned,
    'BBox Intersection Unaligned': bboxIntersectUnaligned
  };

  void initTests() {
    // easy, aligned rays
    r1 = new Ray(new Point3.zero(), new Vector3(1.0, 0.0, 0.0));
    r2 = new Ray(new Point3(1.0, -10.0, 1.0), new Vector3(0.0, 1.0, 0.0));
    // something harder
    r3 = new Ray(new Point3(0.153, 0.1365, -0.367), new Vector3(0.25, 0.25, 0.25));

    // aligned boxes
    bbox1 = new BoundingBox(new Point3(2.0, -1.0, -1.0), new Point3(3.0, 1.0, 1.0));
    bbox2 = new BoundingBox(new Point3(-1.0, 0.0, -1.0), new Point3(3.0, 10.0, 2.0));

    // big box.
    bbox3 = new BoundingBox(new Point3(-30.0084, 1.111, -30.212), new Point3(4687.99, 500.2135, 135.11));
  }

  /*
   *  Tests and variables.
   */
  BoundingBox bbox1, bbox2, bbox3;
  Ray r1, r2, r3;

  bboxCreation() {
    expect(bbox1.minCorner.x, equals(2));
    expect(bbox1.minCorner.y, equals(-1));
    expect(bbox1.minCorner.z, equals(-1));

    expect(bbox1.maxCorner.x, equals(3));
    expect(bbox1.maxCorner.y, equals(1));
    expect(bbox1.maxCorner.z, equals(1));

    expect(bbox2.minCorner.x, equals(-1));
    expect(bbox2.minCorner.y, equals(0));
    expect(bbox2.minCorner.z, equals(-1));

    expect(bbox2.maxCorner.x, equals(3));
    expect(bbox2.maxCorner.y, equals(10));
    expect(bbox2.maxCorner.z, equals(2));
  }

  bboxExtension() {
    // TODO implement bbox extension test
    expect(0, equals(1));
  }

  bboxIntersectAligned() {
    Vector2 result = bbox1.intersect(r1);
    print(result);
    expect(result.x, equals(2));
    expect(result.y, equals(3));

    result = bbox1.intersect(r2);
    print(result);
    expect(result.x > result.y, isTrue);

    result = bbox2.intersect(r1);
    print(result);
    expect(result.x > result.y, isTrue);

    result = bbox2.intersect(r2);
    print(result);
    expect(result.x, equals(10));
    expect(result.y, equals(20));
  }

  bboxIntersectUnaligned() {
    Vector2 result = bbox3.intersect(r3);
    print(result);

    //TODO find exact intersection distances
    expect(result.x , inInclusiveRange(3.8, 4.0));
    expect(result.y, greaterThan(100));
  }
}
