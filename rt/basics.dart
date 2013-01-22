library rt_basics;

import 'dart:math' as Math;

import 'package:vector_math/vector_math_browser.dart';// show vec2, vec3, vec4;
import '../math/algebra.dart' show Point3D, Interval;
import '../math/math_expressions.dart' as Expr;

import 'scene.dart';

/// relative accuracy for floating-point calculations
const num EPS = 0.000001;

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

/**
 * The [Intersection] class represents a ray/object intersection.
 * It contains the distance to the hit point, the affected [Primitive],
 * and the hit point as [Point3D].
 *
 * If there is no hit, distance will be negative.
 */
class Intersection {

  /// The distance to the intersection.
  num distance;

  /// The hit point.
  Point3D hitPoint;

  /// The affected primitive.
  Primitive prim;

  /**
   * Creates a new [Intersection] object.
   *
   * Default values are distance = -1, prim = null.
   */
  Intersection([this.distance = -1, this.prim = null, this.hitPoint]);
}

/**
 * A 3-dimensional bounding box.
 */
class BoundingBox {
  /// Corner points of this bounding box.
  Point3D minCorner, maxCorner;

  /**
   * Creates a bounding box with the given corners.
   * The constructor assumes minCorner to be smaller than maxCorner.
   */
  BoundingBox(this.minCorner, this.maxCorner);

  /**
   * Creates a new empty bounding box.
   */
  BoundingBox.empty():  this.minCorner = new Point3D.splat(double.MAX_FINITE),
                        this.maxCorner = new Point3D.splat(-double.MAX_FINITE);

  /**
   * Intersects this box with the given ray and returns a vec2 containing
   * the distances to the intersections.
   *
   * If the v.x > v.y there is no hit point.
   */
  vec2 intersect(Ray r) {
    //TODO 0-direction or 0-divisor yield in NaN and +/- Infinity
    vec3 t1 = (minCorner - r.origin) / r.direction;
    vec3 t2 = (maxCorner - r.origin) / r.direction;

    vec3 tMin = min(t1, t2);
    vec3 tMax = max(t1, t2);

    num hit1 = Math.max(Math.max(tMin.x, tMin.y), tMin.z);
    num hit2 = Math.min(Math.min(tMin.x, tMin.y), tMin.z);

    return new vec2.raw(hit1, hit2);
  }

  /**
   * Extends this bounding box with the given point.
   */
  void extend(Point3D point) {
    vec3 newMin = min(minCorner.toVec3(), point.toVec3());
    vec3 newMax = max(maxCorner.toVec3(), point.toVec3());
    minCorner = new Point3D.vec(newMin);
    maxCorner = new Point3D.vec(newMax);
  }

  /**
   * Extends this bounding box with the given bounding box.
   */
  void extendBB(BoundingBox bbox) {
    vec3 newMin = min(minCorner.toVec3(), bbox.minCorner.toVec3());
    vec3 newMax = max(maxCorner.toVec3(), bbox.maxCorner.toVec3());
    minCorner = new Point3D.vec(newMin);
    maxCorner = new Point3D.vec(newMax);
  }

  // TODO area and volume for acceleration structures
}

/**
 * The [IdGen] is a simple unique ID generator. It uses sequential ids.
 *
 * Furthermore, IdGen is a singleton. Every instance will reference the
 * same generator.
 *
 * Usage example:
 *     var id = new IdGen().nextId(); // 1
 *     id = new IdGen().nextId(); // 2
 *
 */
class IdGen {

  /// The last id generated by this generator.
  int _lastId;

  static IdGen _instance;

  /**
   * Returns always the same instance of the IdGenerator in the context of
   * an application.
   */
  factory IdGen() {
    if (_instance == null) {
      _instance = new IdGen._internal();
    }
    return _instance;
  }

  /**
   * Internal constructor for an IdGenerator.
   */
  IdGen._internal() : _lastId = 0;

  /**
   * Returns the next unique id.
   */
  int nextId() => ++_lastId;
}