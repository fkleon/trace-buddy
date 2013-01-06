import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/algebra.dart';
import '../rt/ray.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_console.dart';

void main() {
  double EPS = 0.00001;
  
  Point3D c = new Point3D(10, 0, 0);
  num r = 1.0;
  
  Point3D o = new Point3D.zero();
  //o = new Point3D(0,0.99,0);
  vec3 d = new vec3.raw(10,1,0);
  //d = new Point3D(10, 1, 0)-o;
  
  print('d: $d');
  d.normalize();
  print('d_n_length: ${d.length}');
  
  calcDet(o, d, c, r);
  calcRT(o, d, c, r);
  calcGeom(o, d, c, r);
  
  /*
  int xRes, yRes;
  xRes = 100;
  yRes = 99;
  
  Sampler sampler = new DefaultSampler();
  Camera camera = new PerspectiveCamera(
      new Point3D.zero(),
      new vec3.raw(1,0,0),
      new vec3.raw(0,1,0),
      60,
      new vec2.raw(xRes, yRes));
  
  Collection<Primitive> primitives = [new InfinitePlane(new Point3D(0,-2,0),new vec3.raw(0, 1, 0)),
                                      new Sphere(new Point3D(10,0,0),2)];
  
  Scene scene = new Scene(primitives);
  
  Renderer r = new Renderer(scene, sampler, camera);
  OutputMatrix om = r.render();
  */
}

calcDet(Point3D o, vec3 d, Point3D c, num r) {
  double A = d.dot(d);
  print('A/d2: $A');

  double B = (o-c).dot(d) * 2.0;
  print('B: $B');
  
  double C = (o-c).dot(o-c) - (r*r);
  print('C: $C');
  
  double det = (B*B) - (4.0 * A * C);
  print('det: $det');
  
  if (det < 0) {
    print('no hit');
    return;
  } else {
    if (det < EPS) print ('under EPS!');
    print ('hit');
  }
  
  double l1 = (-B + math.sqrt(det))/(2.0*A);
  double l2 = (-B - math.sqrt(det))/(2.0*A);
  print('l1: $l1, l2: $l2');
  
  print('-------------------');
}

calcRT(Point3D o, vec3 d, Point3D c, num r) {
  vec3 distance = o-c;
  print('dist: $distance');
  double B = distance.dot(d);
  print('B: $B');
  double C = B*B - distance.length2 + (r*r);
  print('C: $C');
  double l1 = C > 0.0 ? -B - sqrt(C) : -1.0;
  print('l1: $l1');
  
  print('-------------------');
}

calcGeom(Point3D o, vec3 d, Point3D c, num r) {
  vec3 b = d.scale((c-o).dot(d));
  print('b: $b');
  Point3D B = new Point3D(b.x, b.y, b.z);
  print('B: $B');
  
  vec3 dist = B-c;
  print('dist_len: ${dist.length}');
  
  double hitDist = (r*r) - dist.length2;
  print('hitDist: $hitDist');

  double zeug = b.length - hitDist;
  double zeug2 = b.length + hitDist;
  print('zeug: $zeug');
  print('zeug2: $zeug2');
}
