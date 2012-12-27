library rt_basics;

import 'algebra.dart';
import 'package:vector_math/vector_math_console.dart';

// represents a ray
class Ray {
  
  Point origin;
  vec3 direction;
  
  // creates a ray from given point and direction vector
  Ray(Point this.origin, vec3 this.direction);
  
  // returns the point in space after the ray has traveled the given distance from its origin
  Point getPoint(num distance) {
    return this.origin + (this.direction*distance);
  }
}
