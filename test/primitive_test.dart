import 'package:/unittest/unittest.dart';
import 'package:vector_math/vector_math_console.dart';
import '../rt/algebra.dart';
import '../rt/ray.dart';
import 'dart:math' as math;

Sphere s1,s2;
InfinitePlane p1,p2;
Ray r1,r2,r3,r4;
double EPS = 0.0001;
Point3D origin;

void initPrimitive_test(){
  origin = new Point3D.zero();
  s1 = new Sphere(new Point3D(10, 0, 0), 1);
  s2 = new Sphere(new Point3D(-10, -10, -10), 2);
  p1 = new InfinitePlane(new Point3D(0, 2, 0), new vec3.raw(0, 1, 0));
  r1 = new Ray(origin,new vec3.raw(1, 0, 0));
  r2 = new Ray(origin,new vec3.raw(10, 1, 0).normalize());
  r3 = new Ray(origin,new vec3.raw(10, 2, 0));
  r4 = new Ray(origin,new vec3.raw(0, 1, 0));
}

void sphereCreationValid(){
  expect(s1.center, equals(new Point3D(10, 0, 0)));
  expect(s1.radius, equals(1));
  expect(s2.center, equals(new Point3D(-10,-10,-10)));
  expect(s2.radius, equals(2));
}

void sphereCreationInvalid(){
  expect(()=> new Sphere(origin,-1),throwsArgumentError);
  expect(()=> new Sphere(origin,0),throwsArgumentError);
}

void sphereIntersection(){
  Intersection i1 = s1.intersect(r1, 999999999);
  expect(i1.distance, closeTo(9,EPS));
  expect(i1.prim,equals(s1));
  
  print('${s1.center}, ${s1.radius}');
  print(r2.getPoint3D(math.sqrt(101)));
  print(r2.getPoint3D(9.85086818307881));

  Intersection i2 = s1.intersect(r2, 999999999);
  //expect(i2.distance, closeTo(math.sqrt(101) ,EPS));
  expect(i2.prim,equals(s1));
}

void infinitePlaneCreation(){
  expect(isEqual(p1.equation, new vec4.raw(0, 1, 0, -2)), isTrue );
}

void infinitePlaneInbtersection(){
  Intersection i3 = p1.intersect(r4, 999999999);
  expect(i3.distance, closeTo(2,EPS));
  expect(i3.prim,equals(p1));
}


bool isEqual(vec4 x,vec4 y) => x.x == y.x && x.y == y.y && x.z == y.z && x.w == y.w;

void main() {
  group('Primitive Tests', () {
    setUp(initPrimitive_test);
    test('Sphere Creation Valid', sphereCreationValid);
    test('Sphere Creation Invalid', sphereCreationInvalid);
    test('Sphere Intersection', sphereIntersection);
    test('Plane Creation', infinitePlaneCreation);
    test('Plane Intersection',infinitePlaneInbtersection);
  });
}