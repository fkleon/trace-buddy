library rt_algebra;

import 'package:vector_math/vector_math_console.dart';

// represents a point in 3-dimensional space
class Point {
  
  double x,y,z;
  
  // creates a new point with given coordinates
  Point(num this.x, num this.y, num this.z);
  
  // moves the point to new position determined by given vector
  Point operator+(vec3 v) {
    return new Point(
        this.x + v.x,
        this.y + v.y,
        this.z + v.z
    );
  }
  
  // moves the point to new position determined by given vector
  Point operator-(vec3 v) {
    return new Point(
        this.x - v.x,
        this.y - v.y,
        this.z - v.z
    );
  }
  
  // returns the vector pointing from given point to this point
  vec3 operator-(Point p2) {
    return new vec3(
        this.x - p2.x,
        this.y - p2.y,
        this.z - p2.z
    );
  }
  
  // unary minus, negates point components
  Point operator-() {
    return new Point(
        -this.x,
        -this.y,
        -this.z
    );
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
  
  
}
