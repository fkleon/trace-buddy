library math_algebra;

import 'dart:math' as Math;
import 'package:vector_math/vector_math_console.dart' show vec3, vec4;

/**
 * A point in 3-dimensional space.
 * This implementation supplies common mathematical operations on points.
 */
class Point3D {

  num x,y,z;

  /**
   * Creates a new Point3D with the given coordinates.
   */
  Point3D(num this.x, num this.y, num this.z);

  /**
   * Creates a new Point3D at the coordinate origin.
   */
  Point3D.zero(): x=0, y=0, z=0;

  /**
   * Returns a new point which position is determined by moving the old point
   * along the given vector.
   */
  Point3D operator+(vec3 v) => new Point3D(this.x + v.x, this.y + v.y, this.z + v.z);

  /**
   * Returns the [vec3] pointing from the given point to this point.
   */
  vec3 operator-(Point3D p2) => new vec3(this.x - p2.x, this.y - p2.y, this.z - p2.z);

  /**
   * Negates the point's components.
   */
  Point3D operator-() => new Point3D(-this.x, -this.y, -this.z);

  /**
   * Checks for equality. Two points are considered equal, if their coordinates
   * match.
   */
  bool operator==(Object o) {
    if (o is Point3D) {
      return this.x == o.x && this.y == o.y && this.z == o.z;
    } else {
      return false;
    }
  }

  /**
   * Performs a linear interpolation between two points.
   */
  Point3D lerp(Point3D p2, num coeff) {
    return new Point3D(
        this.x * coeff + p2.x * (1-coeff),
        this.y * coeff + p2.y * (1-coeff),
        this.z * coeff + p2.z * (1-coeff)
    );
  }
  // TODO 3d lerp?

  /**
   * Transforms the point to its vector representation.
   */
  vec3 toVec3() => new vec3.raw(this.x, this.y, this.z);

  /**
   * Transforms the point to its homogeneous vector4 representation.
   * The w component is set to 1.
   */
  vec4 toVec4() => new vec4.raw(this.x, this.y, this.z, 1);

  String toString() => "$x,$y,$z";
}

/**
 * An [Interval] is defined by its minimum and maximum values.
 *
 * It supports basic interval arithmetic operations like addition,
 * subtraction, multiplication and division. Operations return a new
 * interval and will not modify the existing ones.
 */
class Interval {

  num min, max;

  /**
   * Creates a new interval with given borders.
   *
   * The parameter min must be smaller or equal than max for the interval
   * to work properly.
   */
  Interval(this.min, this.max);

  /**
   * Performs an interval addition.
   *
   *     [a, b] + [c, d] = [a + c, b + d]
   */
  operator+(Interval i) => new Interval(this.min + i.min, this.max + i.max);

  /**
   * Performs an interval subtraction.
   *
   *     [a, b] + [c, d] = [a - d, b - c]
   */
  operator-(Interval i) => new Interval(this.min - i.max, this.max - i.min);

  /**
   * Performs an interval multiplication.
   *
   *     [a, b] * [c, d] = [min(ac, ad, bc, bd), max(ac, ad, bc, bd)]
   */
  operator*(Interval i) {
    num min = _min(this.min*i.min, this.min*i.max, this.max*i.min, this.max*i.max);
    num max = _max(this.min*i.min, this.min*i.max, this.max*i.min, this.max*i.max);
    return new Interval(min, max);
  }

  /**
   * Performs an interval division.
   *
   *     [a, b] * [c, d] = [a, b] * (1/[c, d]) = [a, b] * [1/d, 1/c]
   *
   * Note: Does not handle division by zero and throws an ArgumentError instead.
   */
  operator/(Interval i) {
    if (i.containsZero()) {
      // fuck. somebody is dividing by zero, the world is going to end.
      throw new ArgumentError('Can not divide by 0');
    }

    return this * new Interval(1.0/i.max, 1.0/i.min);
  }

  /**
   * Returns true, if the interval contains zero (min <= 0 <= max).
   */
  bool containsZero() => (this.min <= 0 && this.max >= 0);

  /**
   * Returns the minimal value of four given values.
   */
  num _min(num a, num b, num c, num d) => Math.min(Math.min(a ,b), Math.min(c, d));

  /**
   * Returns the maximum value of four given values.
   */
  num _max(num a, num b, num c, num d) => Math.max(Math.max(a ,b), Math.max(c, d));

  String toString() => '[${this.min},${this.max}]';
}
