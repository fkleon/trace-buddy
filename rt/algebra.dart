library rt_algebra;

import 'dart:math' as Math;
import 'package:vector_math/vector_math_console.dart';

// represents a Point3D in 3-dimensional space
class Point3D {
  
  num x,y,z;
  
  // creates a new Point3D with given coordinates
  Point3D(num this.x, num this.y, num this.z);
  
  // creates a new Point3D at the origin
  Point3D.zero(): x=0, y=0, z=0;
  
  // moves the Point3D to new position determined by given vector
  Point3D operator+(vec3 v) => new Point3D(this.x + v.x, this.y + v.y, this.z + v.z);
  
  // moves the Point3D to new position determined by given vector
  //Point3D operator-(vec3 v) => new Point3D(this.x - v.x, this.y - v.y, this.z - v.z);
  
  // returns the vector Point3Ding from given Point3D to this Point3D
  vec3 operator-(Point3D p2) => new vec3(this.x - p2.x, this.y - p2.y, this.z - p2.z);
  
  // unary minus, negates Point3D components
  Point3D operator-() => new Point3D(-this.x, -this.y, -this.z);
  
  // equality
  bool operator==(Object o) {
    if (o is Point3D) {
      return this.x == o.x && this.y == o.y && this.z == o.z;
    } else {
      return false;
    }
  }
  
  // linear interpolation between 2 Point3Ds
  Point3D lerp(Point3D p2, num coeff) {
    return new Point3D(
        this.x * coeff + p2.x * (1-coeff),
        this.y * coeff + p2.y * (1-coeff),
        this.z * coeff + p2.z * (1-coeff)
    );
  }
  // TODO 3d lerp?

  // transformation to 3d and 4d vectors
  vec3 toVec3() => new vec3.raw(this.x, this.y, this.z);
  vec4 toVec4() => new vec4.raw(this.x, this.y, this.z, 1);
  
  String toString() => "$x,$y,$z";
}

/**
 * An [Interval] is defined by its minimum and maximum values.
 * 
 * It supports basic interval arithmetic operations like addition,
 * subtraction, multiplication and division.
 */
class Interval {
  
  num min, max;
  
  Interval(this.min, this.max);
  
  operator+(Interval i) {
    this.min += i.min;
    this.max += i.max;
  }
  
  operator-(Interval i) {
    this.min -= i.min;
    this.max -= i.max;
  }
  
  operator*(Interval i) {
    this.min = _min(this.min*i.min, this.min*i.max, this.max*i.min, this.max*i.max);
    this.max = _max(this.min*i.min, this.min*i.max, this.max*i.min, this.max*i.max);
  }
  
  operator/(Interval i) {
    if (i.containsZero()) {
      // fuck. somebody is dividing by zero, the world is going to end.
      throw new ArgumentError('Can not divide by 0');
    }
    
    this * new Interval(1.0/i.max, 1.0/i.min);
  }
  
  bool containsZero() => (this.min <= 0 && this.max >= 0);
  
  num _min(num a, num b, num c, num d) => Math.min(Math.min(a ,b), Math.min(c, d));
  num _max(num a, num b, num c, num d) => Math.max(Math.max(a ,b), Math.max(c, d));
  
  String toString() => '[${this.min},${this.max}]';
}
