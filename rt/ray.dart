library rt_basics;

import 'package:vector_math/vector_math_console.dart';
import 'algebra.dart';
import 'shaders.dart';

part 'scene.dart';

// represents a ray
class Ray {
  
  Point3D origin;
  vec3 direction;
  
  // creates a ray from given Point3D and direction vector
  Ray(Point3D this.origin, vec3 this.direction);
  
  // returns the Point3D in space after the ray has traveled the given distance from its origin
  Point3D getPoint3D(num distance) => this.origin + (this.direction*distance);

  String toString() => "Ray [$origin --> $direction].";
}
