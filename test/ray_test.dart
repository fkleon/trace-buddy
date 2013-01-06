part of rt_test_suite;

Ray r1, r2;

void initRayTests() {
  r1 = new Ray(new Point3D.zero(), new vec3.raw(1,0,0));
  r2 = new Ray(new Point3D(1,-1,1), new vec3.raw(0,1,0));
}

rayCreation() {
  expect(r1.origin, equals(new Point3D.zero()));
  expect(r1.direction.x, equals(1));
  expect(r1.direction.y, equals(0));
  expect(r1.direction.z, equals(0));
  
  expect(r2.origin, equals(new Point3D(1,-1,1)));
  expect(r2.direction.x, equals(0));
  expect(r2.direction.y, equals(1));
  expect(r2.direction.z, equals(0));
}

rayPosition() {
  expect(r1.getPoint3D(5), equals(new Point3D(5, 0, 0)));
  expect(r1.getPoint3D(-0.66).x, closeTo(-0.66, EPS));
  expect(r1.getPoint3D(0), equals(new Point3D.zero()));
  
  expect(r2.getPoint3D(3), equals(new Point3D(1, 2, 1)));
  expect(r2.getPoint3D(-0.66).y, closeTo(-1.66, EPS));
  expect(r2.getPoint3D(-0), equals(new Point3D(1, -1, 1)));
}