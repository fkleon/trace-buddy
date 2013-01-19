library rt_basics;

import 'dart:math' as Math;
import 'package:vector_math/vector_math_console.dart';
import '../math/algebra.dart';
import 'shaders.dart';

part 'scene.dart';

/**
 * A [Ray] can be represented by its origin in space, direction vector and
 * time traveled:
 * 
 *     r(t) = o + td
 */
class Ray {
  
  /// The origin of this ray.
  Point3D origin;
  
  /// The direction vector of this ray.
  vec3 direction;
  
  /**
   * Creates a [Ray] from a given origin and direction vector.
   */
  Ray(Point3D this.origin, vec3 this.direction);
  
  /**
   * Returns the point in space after this ray has traveled a given distance
   * from its origin.
   */
  Point3D getPoint3D(num distance) => this.origin + (this.direction * distance);

  String toString() => "Ray [$origin --> $direction].";
}
