import 'dart:math' as math;

import 'package:vector_math/vector_math_console.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import '../math/algebra.dart';

class IntersectionBenchmark extends BenchmarkBase {
  
  IntersectionBenchmark(String name): super(name);
      
  // Not measured: setup code executed before the benchmark runs.
  void setup() {
    // init sphere
    c = new Point3D(10, 0, 0);
    r = 1.0;
    
    // init ray with 2 hitpoints
    o1 = new Point3D.zero();
    d1 = new vec3.raw(10,1,0).normalize();
    
    // init ray with 1 hitpoint
    o2 = new Point3D(0,1,0);
    d2 = new vec3.raw(10, 0, 0).normalize();

    // init ray with no hitpoint
    o3 = new Point3D(0,0,0);
    d3 = new vec3.raw(1, 1, 0).normalize();
  }

  // Not measured: teardown code executed after the benchmark runs.
  void teardown() { }
  
  const double EPS = 0.00001;
  Point3D c, o1, o2, o3;
  double r;
  vec3 d1, d2, d3;
  
  // expects normalized direction vector
  double calcDet(Point3D o, vec3 d, Point3D c, num r) {
    //print('-- CALC DET --');
    
    double A = d.dot(d);
    //print('A/d2: $A');
  
    double B = (o-c).dot(d) * 2.0;
    //print('B: $B');
    
    double C = (o-c).dot(o-c) - (r*r);
    //print('C: $C');
    
    double det = (B*B) - (4.0 * A * C);
    //print('det: $det');
    
    if (det < 0) {
      //print('no hit');
      return -1.0;
    }
    
    double l1 = (-B + math.sqrt(det))/(2.0*A);
    double l2 = (-B - math.sqrt(det))/(2.0*A);
    
    //print('hit -> l1: $l1, l2: $l2');
    //print('-------------------');
    
    return l1;
  }
  
  // expects normalized direction vector
  double calcRT(Point3D o, vec3 d, Point3D c, num r) {
    //print('-- CALC RT --');
  
    vec3 distance = o-c;
    //print('dist: $distance');
    double B = distance.dot(d);
    //print('B: $B');
    double C = B*B - distance.length2 + (r*r);
    //print('C: $C');
    double l1 = C >= 0.0 ? -B - sqrt(C) : -1.0;
    //double l2 = C >= 0.0 ? -B + sqrt(C) : -1.0; // unnecessary, l1 will always be the nearest hitpoint
    
    if (l1 < 0) {
      //print('no hit');
      return l1;
    }
    
    //print('hit -> l1: $l1, l2: $l2');
    //print('-------------------');
    
    return l1;
  }
  
  // buggy
  double calcGeom(Point3D o, vec3 d, Point3D c, num r) {
    //print('-- CALC GEOM --');
  
    vec3 b = d.scale((c-o).dot(d));
    //print('b: $b');
    Point3D B = new Point3D(b.x, b.y, b.z);
    //print('B: $B');
    
    vec3 dist = B-c;
    //print('dist_len: ${dist.length}');
    
    double hitDist = (r*r) - dist.length2;
    //print('hitDist: $hitDist');
  
    double l1 = b.length - hitDist;
    double l2 = b.length + hitDist;
    
    //print('l1: $l1, l2: $l2');
    //print('-------------------');
    
    return l1;
  }
}

class IntersectionDetBenchmark extends IntersectionBenchmark {
  
  IntersectionDetBenchmark(): super("IntersectionDet");
  
  static void go() {
    new IntersectionDetBenchmark().report();
  }
  
  // The benchmark code.
  void run() {
    // expect two hit points
    calcDet(o1, d1, c, r);
    // expect one hit point
    calcDet(o2, d2, c, r);    
    // expect no hit point
    calcDet(o3, d3, c, r);
  }
}

class IntersectionRTBenchmark extends IntersectionBenchmark {
  
  IntersectionRTBenchmark(): super("IntersectionRT");
  
  static void go() {
    new IntersectionRTBenchmark().report();
  }
  
  // The benchmark code.
  void run() {
    // expect two hit points
    calcRT(o1, d1, c, r);
    // expect one hit point
    calcRT(o2, d2, c, r);    
    // expect no hit point
    calcRT(o3, d3, c, r);
  }
}

void main() {
  IntersectionDetBenchmark.go();
  IntersectionRTBenchmark.go();
}
