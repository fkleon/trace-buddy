library rt_algebra;

import 'package:vector_math/vector_math_console.dart';

// represents a point in 3-dimensional space
class Point {
  
  num x,y,z;
  
  // creates a new point with given coordinates
  Point(num this.x, num this.y, num this.z);
  
  // creates a new point at the origin
  Point.zero(): x=0, y=0, z=0;
  
  // moves the point to new position determined by given vector
  Point operator+(vec3 v) => new Point(this.x + v.x, this.y + v.y, this.z + v.z);
  
  // moves the point to new position determined by given vector
  //Point operator-(vec3 v) => new Point(this.x - v.x, this.y - v.y, this.z - v.z);
  
  // returns the vector pointing from given point to this point
  vec3 operator-(Point p2) => new vec3(this.x - p2.x, this.y - p2.y, this.z - p2.z);
  
  // unary minus, negates point components
  Point operator-() => new Point(-this.x, -this.y, -this.z);
  
  // equality
  bool operator==(Object o) {
    if (o is Point) {
      return this.x == o.x && this.y == o.y && this.z == o.z;
    } else {
      return false;
    }
  }
  
  // linear interpolation between 2 points
  Point lerp(Point p2, num coeff) {
    return new Point(
        this.x * coeff + p2.x * (1-coeff),
        this.y * coeff + p2.y * (1-coeff),
        this.z * coeff + p2.z * (1-coeff)
    );
  }
  // TODO 3d lerp?

  // transformation to 3d and 4d vectors
  vec3 toVec3() => new vec3.raw(this.x, this.y, this.z);
  vec4 toVec4() => new vec4.raw(this.x, this.y, this.z, 1);
}
