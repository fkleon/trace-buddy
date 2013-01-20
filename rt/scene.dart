library rt_primitives;

import 'dart:math' as Math;

import 'package:vector_math/vector_math_console.dart';
import '../math/algebra.dart' show Point3D, Interval;
import '../math/math_expressions.dart' as Expr;

import 'basics.dart' show EPS, Ray, IdGen, Intersection;
import 'shaders.dart' show Shader, AmbientShader, PluggableShader;

/**
 * A [Primitive] is an arbitrary object which can be part of a scene and
 * rendered by the ray tracer.
 *
 * Any concrete implementation of a [Primitive] needs to implement the
 * intersect method, which tests for ray/primitive intersection.
 * A primitive can be any geometric shape, mathematical function, etc.
 *
 * Every primitive has an unique ID, and a shader. When creating your
 * own primitive, don't forget to call the super() contructor to auto-
 * matically generate the id.
 */
abstract class Primitive {

  /// Unique id of the primitive.
  final int id;

  /// The shader is responsible for the primitive's appearance.
  Shader _shader;

  /**
   * Creates a new [Primitive] and assigns an unique id to it.
   * The optional parameter `shader` can be used to set a shader for this
   * primitive. If no shader is assigned, a default [AmbientShader] will
   * be created.
   */
  Primitive([Shader this._shader]) : id = new IdGen().nextId() {
    if (_shader == null) {
      _shader = new AmbientShader(new vec4.raw(1,0,0,0));
    }
  }

  /**
   * Performs a ray - primitive intersection test.
   * Returns an [Intersection] object with the associated information.
   *
   * If the ray did not hit the primitive, the distance will be negative.
   */
  Intersection intersect(Ray ray, num previousBestDistance);

  /**
   * Returns the shader for a given intersection point.
   */
  Shader getShader(Intersection intersect);

  /*
   * The following getters are only used to display information in the GUI.
   */
  /// The origin of the primitive (only used for GUI).
  Point3D get origin => null;

  /// The primary color of the primitive as vector4 (only used for GUI).
  vec4 get color => _shader == null ? new vec4.zero() : _shader.getAmbientCoeff();

  /// The primary color of the primitive as CSS rgba string (only used for GUI).
  String get colorString => 'rgba(${(color.r*255).toInt()},'
                                 '${(color.g*255).toInt()},'
                                 '${(color.b*255).toInt()},'
                                 '1)';
}

/**
 * A [Scene] basically is a collection of [Primitive]s which together
 * form the scene to be rendered.
 *
 * The [Scene] itself is a primitive as well, and offers an intersect method.
 */
class Scene extends Primitive {

  /// The cartesian coordinate system of this scene.
  CartesianCoordinateSystem ccs;

  /// A list of non-indexable primitives in the scene.
  List<Primitive> nonIdxPrimitives;

  /**
   * Creates a new [Scene]. Takes an optional parameter `primitives`,
   * which initialized the scene with the given primitives instead
   * of creating an empty one.
   */
  Scene([Collection<Primitive> primitives]) {
    if (?primitives) {
      this.nonIdxPrimitives = new List<Primitive>.from(primitives);
    } else {
      this.nonIdxPrimitives = new List<Primitive>();
    }

    ccs = new CartesianCoordinateSystem();
  }

  /**
   * Adds the given [Primitive] to this scene.
   */
  void add(Primitive p) {
    this.nonIdxPrimitives.add(p);
  }

  /**
   * Removes the [Primitive] with given id from this scene.
   */
  void remove(int primId) {
    int i = 0;
    bool found = false;
    for (Primitive prim in nonIdxPrimitives) {
      if (prim.id == primId) {
        found = true;
        break;
      }
      i++;
    }

    if (found) nonIdxPrimitives.removeAt(i);
  }

  /**
   * Given parameter determines if the cartesian coordinate system will be
   * rendered in this scene.
   */
  void displayCCS(bool displayCCS) {
    if (displayCCS && !nonIdxPrimitives.contains(ccs)) {
      nonIdxPrimitives.add(ccs);
    }

    if (!displayCCS) {
      remove(ccs.id);
    }
  }


  /**
   * Performs a ray - scene intersection.
   *
   * Iterates over all primitives and calls their intersect.
   * Will only return hit points which are closer than the specified
   * `prevBestDistance`.
   */
  Intersection intersect(Ray r, num prevBestDistance) {

    num bestDistance = prevBestDistance;
    Primitive bestPrimitive = null;

    //print('Finding intersetion with ${nonIdxPrimitives.length} primitives..');

    // iterate over non-indexable primitives
    for (Primitive p in this.nonIdxPrimitives) {
      var curHit = p.intersect(r, bestDistance);

      // check if we have a better hit
      if (curHit.distance < bestDistance && curHit.distance > EPS) {
        // yep.
        bestDistance = curHit.distance;
        bestPrimitive = p;
      }
    }

    // TODO iterate over indexable primitives

    // package everything nicely
    Intersection bestHit = new Intersection(bestDistance, bestPrimitive, r.getPoint3D(bestDistance));
    return bestHit;
  }

  Shader getShader(Intersection intersect) => intersect.prim.getShader(intersect);

  // TODO indexable primitives
  // TODO acceleration structure / rebuild index?
}

/**
 * An [InfinitePlane] is specified by its plane equation.
 */
class InfinitePlane extends Primitive {

  /// The plane equation.
  vec4 equation;

  /// The plane origin.
  Point3D origin;

  /**
   * Creates a new [InfinitePlane] from the given origin, normal and shader.
   */
  InfinitePlane(Point3D this.origin, vec3 normal, [Shader shader]) : super(shader){
    num w = -normal.dot(origin.toVec3());
    equation = new vec4(normal,w);
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();

    // perform calculations in homogeneous space
    // check if ray is orthogonal to normal (= parallel to plane)
    var div = new vec4(r.direction).dot(equation);

    if (div.abs() > EPS) {
      // calculate distance from ray origin to plane
      var dist = (-r.origin.toVec4().dot(equation)) / div;

      intersect.distance = dist;
      intersect.prim = this;
      intersect.hitPoint = r.getPoint3D(dist);
    }

    return intersect;
  }

  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;
    ret.normal = equation.xyz;

    return ret;
  }
}

/**
 * A [CartesianCoordinateSystem] is a special primitive,
 * it represents the x,y and z-axes. Only one instance of the
 * CartesianCoordinateSystem can exist per scene, therefore
 * it is implemented as singleton.
 */
class CartesianCoordinateSystem extends Primitive {

  static Primitive _instance;

  /// Threshold value for determine if an axis intersection occured.
  final double THRESH = 0.02;

  InfinitePlane _xAxis, _yAxis, _zAxis;

  /**
   * Returns always the same instance of CartesianCoordinateSystem in the
   * context of an application.
   */
  factory CartesianCoordinateSystem() {
    if (_instance == null) {
      _instance = new CartesianCoordinateSystem._internal();
    }
    return _instance;
  }

  /**
   * Internal constructor to realize singleton implementation.
   */
  CartesianCoordinateSystem._internal() {
    var origin = new Point3D.zero();
    this._xAxis = new InfinitePlane(origin, new vec3.raw(0, 1, 0));
    this._yAxis = new InfinitePlane(origin, new vec3.raw(1, 0, 0));
    this._zAxis = new InfinitePlane(origin, new vec3.raw(0, 1, 0));
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intRet = _xAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near x axis;
    if (intRet.distance > 0 && abs(intRet.hitPoint.z) < THRESH && abs(intRet.hitPoint.y) < THRESH) {
      return intRet;
    }

    intRet = _yAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near y axis;
    if (intRet.distance > 0 && abs(intRet.hitPoint.x) < THRESH && abs(intRet.hitPoint.z) < THRESH) {
      return intRet;
    }

    intRet = _zAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near z axis;
    if (intRet.distance > 0 && abs(intRet.hitPoint.x) < THRESH && abs(intRet.hitPoint.y) < THRESH) {
      return intRet;
    }

    // no hit at all..
    return new Intersection();
  }

  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;

    return ret;
  }
}

/**
 * A [Sphere], defined by its center point and radius.
 */
class Sphere extends Primitive {

  /// The center of this sphere.
  Point3D center;

  /// The radius of this sphere.
  num radius;

  Point3D get origin => center;

  /**
   * Creates a new [Sphere] with the given center, radius and shader.
   *
   * The radius of a sphere must not be zero or less.
   */
  Sphere(Point3D this.center, num this.radius, [Shader shader]) : super(shader) {
    if (radius<=0) throw new ArgumentError('Radius of sphere must not be zero or less');
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();

    /*
    vec3 distance = r.origin-this.center;
    double B = distance.dot(r.direction);
    double C = B*B - distance.length2 + (this.radius*this.radius);
    double l1 = C >= 0.0 ? -B - sqrt(C) : -1.0;

    if (l1 < 0) {
      return intersect;
    } else {
      intersect.distance = l1;
      intersect.hitPoint = r.getPoint3D(l1);
      intersect.prim = this;
      return intersect;
    }
    */

    num A = r.direction.dot(r.direction);
    num B = (r.origin - this.center).dot(r.direction) * 2;
    num C = (r.origin - this.center).dot(r.origin - this.center) - (this.radius * this.radius);
    num det = B * B - 4 * A * C;

    if (det >= 0) {
      num sol1 = (-B + sqrt(det)) / (2 * A);
      num sol2 = (-B - sqrt(det)) / (2 * A);

      num minDist,maxDist;
      if (sol1 >= sol2) {
        maxDist = sol1;
        minDist = sol2;
      }else{
        maxDist = sol2;
        minDist = sol1;
      }

      num dist = minDist > EPS ? minDist : maxDist;

      intersect.distance = dist;
      intersect.prim = this;
      intersect.hitPoint = r.getPoint3D(dist);
    }

    return intersect;
  }

  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;
    ret.normal = intersect.hitPoint - this.origin;

    return ret;
  }
}

/**
 * A [ImplicitFunction] is defined by a [MathFunction].
 *
 * Its intersect uses Interval arithmetic and Newton's method to determine
 * roots.
 */
class ImplicitFunction extends Primitive {

  final num maxDistance = 100;
  Expr.MathFunction f; // only contains x, y, z
  Expr.ContextModel cm;

  ImplicitFunction(Expr.MathFunction this.f, [Shader shader]) : super(shader) {
    this.cm = new Expr.ContextModel();
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Expr.Variable x = new Expr.Variable('x'), y = new Expr.Variable('y'), z = new Expr.Variable('z');
    Expr.Variable t = new Expr.Variable('t');

    Expr.Expression xExpr = new Expr.Number(r.origin.x) + (t * new Expr.Number(r.direction.x));
    Expr.Expression yExpr = new Expr.Number(r.origin.y) + (t * new Expr.Number(r.direction.y));
    Expr.Expression zExpr = new Expr.Number(r.origin.z) + (t * new Expr.Number(r.direction.z));

    cm.bindGlobalVariable(x, xExpr);
    cm.bindGlobalVariable(y, yExpr);
    cm.bindGlobalVariable(z, zExpr);

    // Composition G(t) = F(x,y,z) o r(t)
    //Function g = compose(f, r);

    // Replace all numbers with intervals
    //g.replace();

    // Starting interval [0, maxDistance]
    Interval i = new Interval(0, 50);

    //Interval i = f.evaluate(Expr.EvaluationType.INTERVAL, cm);
    //print(i);

    num distance = findRootBF(f, i);
    //findRoot(g, i);

    Intersection int = new Intersection(distance, this, r.getPoint3D(distance));
    return int;
  }

  num findRootBF(Expr.MathFunction g, Interval i) {
    //print('Analyze $i');
    if (i.length() < 0.1) {
      return i.min;
    }

    Expr.Expression tExpr = new Expr.Interval(new Expr.Number(i.min), new Expr.Number(i.max));
    Expr.Variable t = new Expr.Variable('t');
    cm.bindGlobalVariable(t, tExpr);

    Interval gEval = g.evaluate(Expr.EvaluationType.INTERVAL, cm);

    if (gEval.containsZero()) {
      num r1 = findRootBF(g, new Interval(i.min, (i.min + i.max) / 2.0));
      num r2 = findRootBF(g, new Interval((i.min + i.max) / 2.0, i.max));
      return Math.min(r1, r2); // Return root ar minimal distance.
    } else {
      return 9999999;
    }
  }

  /*
  num findRoot(Expr.MathFunction g, Interval i) {

    Expr.Expression tExpr = new Expr.Interval(new Expr.Number(0), new Expr.Number(maxDistance));
    Expr.Variable t = new Expr.Variable('t');
    cm.bindGlobalVariable(t, tExpr);

    // Calculate value of the function at interval borders
    // G(i.min), G(i.max)
    Interval gEval = g.evaluate(Expr.EvaluationType.INTERVAL, cm);
    //Interval gEval = g.evaluate(i);

    // If interval contains 0, derive G(t)
    if (gEval.containsZero()) {
      Function gDerived = g.derive();
      Interval gDerivedEval = gDerived.evaluate(i);

      if (gDerivedEval.containsZero()) {
        // Monotonous part of function.
        // -> calculate root
        newtonRoot(g, i);
      } else {
        // Recursively split.
        num r1 = findRoot(new Interval(i.min, (i.min+i.max)/2.0));
        num r2 = findRoot(new Interval((i.min+i.max)/2.0, i.max));
        return Math.min(r1,r2); // Return root ar minimal distance.
      }
    } else {
      // No root.
      // Return negative value for no hit.
      return -1;
    }
  }
  
  num newtonRoot(Function f, num startValue) {
    Function g = f.derive();
    return _newtonRoot(f, g, startValue);
  }

  num _newtonRoot(Function f, Function g, num startValue) {
    num x_i = startValue - (f.evaluate(startValue)/g(evaluate(startValue)));

    if ((x_i - startValue).abs() < EPS) {
      return x_i;
    } else {
      return _newtonRoot(f, g, x_i);
    }
  }
  */
  
  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;

    // To determine normal, derive function in all directions (gradient).
    Expr.MathFunction fDx = f.derive('x');
    Expr.MathFunction fDy = f.derive('y');
    Expr.MathFunction fDz = f.derive('z');

    cm.bindGlobalVariableName('x', new Expr.Number(intersect.hitPoint.x));
    cm.bindGlobalVariableName('y', new Expr.Number(intersect.hitPoint.y));
    cm.bindGlobalVariableName('z', new Expr.Number(intersect.hitPoint.z));

    num gradX = fDx.evaluate(Expr.EvaluationType.REAL, cm);
    num gradY = fDy.evaluate(Expr.EvaluationType.REAL, cm);
    num gradZ = fDz.evaluate(Expr.EvaluationType.REAL, cm);

    ret.normal = new vec3.raw(gradX, gradY, gradZ);

    return ret;
  }

  String toString() => 'ImplicitFunction[${f.toFullString()}]';
}