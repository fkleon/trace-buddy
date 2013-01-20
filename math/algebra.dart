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
 * An [Interval] is defined by its minimum and maximum values, where min <= max.
 *
 * It supports basic interval arithmetic operations like addition,
 * subtraction, multiplication and division. Operations return a new
 * interval and will not modify the existing ones.
 *
 * __Note__: This implementaion does not offer a complete set of operations:
 *
 * - Unbounded intervals, intervals containing +/- infinity or the empty set
 * are not represented.
 * - Therefore, interval division by zero is not supported as well.
 */
class Interval implements Comparable {

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
   * Unary minus on intervals.
   *
   *     -[a, b] = [-b, -a]
   */
  operator-() => new Interval(-max, -min);

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
   * Equals operator on intervals.
   *
   *     [a, b] == [c, d], if a == c && b == d
   */
  operator==(Interval i) => this.min == i.min && this.max == i.max;

  /**
   * Less than operator on intervals.
   *
   *     [a, b] < [c, d], if a < c && b < d
   */
  operator<(Interval i) => this.min < i.min && this.max < i.max;

  /**
   * Less or equal than operator on intervals.
   *
   *     [a, b] <= [c, d], if a <= c && b <= d
   */
  operator<=(Interval i) => this.min <= i.min && this.max <= i.max;

  /**
   * Greater than operator on intervals.
   *
   *     [a, b] > [c, d], if a > c && b > d
   */
  operator>(Interval i) => this.min > i.min && this.max > i.max;

  /**
   * Greater or equal than operator on intervals.
   *
   *     [a, b] >= [c, d], if a >= c && b >= d
   */
  operator>=(Interval i) => this.min >= i.min && this.max >= i.max;

  /**
   * Returns the greatest lower bound.
   */
  Interval glb(Interval i) =>
      new Interval(Math.min(min, i.min), Math.min(max, i.max));

  /**
   * Returns the least upper bound.
   */
  Interval lub(Interval i) =>
      new Interval(Math.max(min, i.min), Math.max(max, i.max));

  /**
   * Inclusion relation. Returns true, if the given interval is included
   * in this itnerval.
   *
   *     [a, b] subset of [c, d] <=> c <= a && b >= d
   */
  bool includes(Interval i) =>
      this.min <= i.min && i.max <= this.max;

  /**
   * Element-of relation. Returns true, if given element is included
   * in this interval.
   * Defined on a real number i and an interval:
   *
   *     i element of [a, b] <=> a <= i && i <= b
   */
  bool contains(num element) => this.min <= element && element <= this.max;

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

  /**
   * Returns the length of this interval.
   */
  num length() => max - min;

  String toString() => '[${this.min},${this.max}]';

  int compareTo(Comparable other) {
    // For now, only allow compares to other intervals.
    if (other is Interval) {
      // Equality, less and greater tests.
      if (this == other) return 0;
      if (this < other) return -1;
      if (this > other) return 1;
    } else {
      throw new ArgumentError('$other is not comparable to Interval.');
    }
  }
}
