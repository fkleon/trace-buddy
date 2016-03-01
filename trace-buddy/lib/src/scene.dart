part of tracebuddy;

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
      _shader = new AmbientShader(new Vector4(1.0,0.0,0.0,0.0));
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
  Point3 get origin => null;

  /// The primary color of the primitive as vector4 (only used for GUI).
  Vector4 get color => _shader == null ? new Vector4.zero() : _shader.getAmbientCoeff();

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
  Scene([List<Primitive> primitives]) {
    if (primitives != null) {
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
  Intersection intersect(Ray r, double prevBestDistance) {

    double bestDistance = prevBestDistance;
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
    Intersection bestHit = new Intersection(bestDistance, bestPrimitive, r.getPoint3(bestDistance));
    return bestHit;
  }

  Shader getShader(Intersection intersect) => intersect.prim.getShader(intersect);

  String toString() => "Scene";

  // TODO indexable primitives
  // TODO acceleration structure / rebuild index?
}

/**
 * An [InfinitePlane] is specified by its plane equation.
 */
class InfinitePlane extends Primitive {

  /// The plane equation.
  Vector4 equation;

  /// The plane origin.
  Point3 origin;

  /**
   * Creates a new [InfinitePlane] from the given origin, normal and shader.
   */
  InfinitePlane(Point3 this.origin, Vector3 normal, [Shader shader]) : super(shader){
    double w = -normal.dot(origin);
    equation = new Vector4(normal.x, normal.y, normal.z ,w);
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();

    // perform calculations in homogeneous space
    // check if ray is orthogonal to normal (= parallel to plane)
    Vector4 homDir = new Vector4(r.direction.x, r.direction.y, r.direction.z, 0.0);
    double div = homDir.dot(equation);

    if (div.abs() > EPS) {
      // calculate distance from ray origin to plane
      // use homogeneous vector4 representation
      Vector4 vec4 = -(r.origin.xyzz..w = 1.0);
      var dist = vec4.dot(equation) / div;

      intersect.distance = dist;
      intersect.prim = this;
      intersect.hitPoint = r.getPoint3(dist);
    }

    return intersect;
  }

  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;
    ret.normal = equation.xyz;

    return ret;
  }

  String toString() => "InfinitePlane";
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

  Point3 get origin => new Point3.zero();

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
    var origin = new Point3.zero();
    this._xAxis = new InfinitePlane(origin, new Vector3(0.0, 1.0, 0.0));
    this._yAxis = new InfinitePlane(origin, new Vector3(1.0, 0.0, 0.0));
    this._zAxis = new InfinitePlane(origin, new Vector3(0.0, 1.0, 0.0));
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intRet = _xAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near x axis;
    if (intRet.distance > 0 && intRet.hitPoint.z.abs() < THRESH && intRet.hitPoint.y.abs() < THRESH) {
      return intRet;
    }

    intRet = _yAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near y axis;
    if (intRet.distance > 0 && intRet.hitPoint.x.abs() < THRESH && intRet.hitPoint.z.abs() < THRESH) {
      return intRet;
    }

    intRet = _zAxis.intersect(r, prevBestDistance);
    // check if hitpoint is near z axis;
    if (intRet.distance > 0 && intRet.hitPoint.x.abs() < THRESH && intRet.hitPoint.y.abs() < THRESH) {
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

  String toString() => "CartesianCoordinateSystem";
}

/**
 * A [Sphere], defined by its center point and radius.
 */
class Sphere extends Primitive {

  /// The center of this sphere.
  Point3 center;

  /// The radius of this sphere.
  num radius;

  Point3 get origin => center;

  /**
   * Creates a new [Sphere] with the given center, radius and shader.
   *
   * The radius of a sphere must not be zero or less.
   */
  Sphere(Point3 this.center, num this.radius, [Shader shader]) : super(shader) {
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
      intersect.hitPoint = r.getPoint3(l1);
      intersect.prim = this;
      return intersect;
    }
    */

    num A = r.direction.dot(r.direction);
    num B = (r.origin - this.center).dot(r.direction) * 2;
    num C = (r.origin - this.center).dot(r.origin - this.center) - (this.radius * this.radius);
    num det = B * B - 4 * A * C;

    if (det >= 0) {
      num sol1 = (-B + Math.sqrt(det)) / (2 * A);
      num sol2 = (-B - Math.sqrt(det)) / (2 * A);

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
      intersect.hitPoint = r.getPoint3(dist);
    }

    return intersect;
  }

  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;
    ret.normal = (intersect.hitPoint - this.origin).normalize();

    return ret;
  }

  String toString() => "Sphere";
}

/**
 * A [ImplicitFunction] is defined by a [MathFunction].
 *
 * Its intersect uses Interval arithmetic and Newton's method to determine
 * roots.
 */
class ImplicitFunction extends Primitive {

  final num maxDistance = 100;
  MathFunction f; // only contains x, y, z
  ContextModel cm;

  ImplicitFunction(MathFunction this.f, [Shader shader]) : super(shader) {
    this.cm = new ContextModel();
  }

  Intersection intersect(Ray r, num prevBestDistance) {
    Variable x = new Variable('x'), y = new Variable('y'), z = new Variable('z');
    Variable t = new Variable('t');

    Expression xExpr = new Number(r.origin.x) + (t * new Number(r.direction.x));
    Expression yExpr = new Number(r.origin.y) + (t * new Number(r.direction.y));
    Expression zExpr = new Number(r.origin.z) + (t * new Number(r.direction.z));

    cm.bindVariable(x, xExpr);
    cm.bindVariable(y, yExpr);
    cm.bindVariable(z, zExpr);

    // Composition G(t) = F(x,y,z) o r(t)
    //Function g = compose(f, r);

    // Replace all numbers with intervals
    //g.replace();

    // Starting interval [0, maxDistance]
    Interval i = new Interval(0, maxDistance);

    //Interval i = f.evaluate(Expr.EvaluationType.INTERVAL, cm);
    //print(i);

    double distance = findRootBF(f, i);

    //TODO f needs to be composite for this to work, or have x, y, z substituted.
    //num distance = findRoot(f, i);
    //findRoot(g, i);

    Intersection int = new Intersection(distance, this, r.getPoint3(distance));
    return int;
  }

  double findRootBF(MathFunction g, Interval i) {
    //print('Analyze $i');
    if (i.length() < 0.001) {
      return i.min;
    }

    Expression tExpr = new IntervalLiteral(new Number(i.min), new Number(i.max));
    Variable t = new Variable('t');
    cm.bindVariable(t, tExpr);

    Interval gEval = g.evaluate(EvaluationType.INTERVAL, cm);

    if (gEval.containsZero()) {
      num r1 = findRootBF(g, new Interval(i.min, (i.min + i.max) / 2.0));
      num r2 = findRootBF(g, new Interval((i.min + i.max) / 2.0, i.max));
      return Math.min(r1, r2); // Return root ar minimal distance.
    } else {
      return MAX_DIST;
    }
  }

  num findRoot(MathFunction g, Interval i) {

    Expression tExpr = new IntervalLiteral(new Number(i.min), new Number(i.max));
    Variable t = new Variable('t');
    cm.bindVariable(t, tExpr);

    // Calculate value of the function at interval borders
    // G(i.min), G(i.max)
    Interval gEval = g.evaluate(EvaluationType.INTERVAL, cm);
    //Interval gEval = g.evaluate(i);

    // If interval contains 0, derive G(t)
    if (gEval.containsZero()) {
      MathFunction gDerived = g.derive('t');
      Interval gDerivedEval = gDerived.evaluate(EvaluationType.INTERVAL, cm);

      if (gDerivedEval.containsZero()) {
        // Monotonous part of function.
        // -> calculate root
        print(i);
        return _newtonRoot(g, gDerived, (i.min+i.max)/2.0);
      } else {
        // Recursively split.
        num r1 = findRoot(g, new Interval(i.min, (i.min+i.max)/2.0));
        num r2 = findRoot(g, new Interval((i.min+i.max)/2.0, i.max));
        return Math.min(r1,r2); // Return root ar minimal distance.
      }
    } else {
      // No root.
      // Return negative value for no hit.
//      return -1;
      return MAX_DIST;
    }
  }

  num newtonRoot(MathFunction f, num startValue) {
    MathFunction g = f.derive(f.getParam(0).name); // should be one-dimensional
    return _newtonRoot(f, g, startValue);
  }

  num _newtonRoot(MathFunction f, MathFunction g, num startValue) {
    cm.bindVariableName('t', new Number(startValue)); //TODO make it work with cmposites (set f.gerParam(i))..
    //TODO or allow to evaluate without context model.
    //print(cm.variables);
    //print(f.toFullString());
    num fEval = f.evaluate(EvaluationType.REAL, cm);

    cm.bindVariableName('t', new Number(startValue));
    num gEval = g.evaluate(EvaluationType.REAL, cm);

    print(g.toFullString());
    print('$fEval / $gEval');

    //TODO handle gEval == 0
    num x_i = startValue - (fEval/gEval);

    if ((x_i - startValue).abs() < EPS) {
      return x_i;
    } else {
      return _newtonRoot(f, g, x_i);
    }
  }


  Shader getShader(Intersection intersect) {
    PluggableShader ret = this._shader.clone();

    ret.position = intersect.hitPoint;

    // To determine normal, derive function in all directions (gradient).
    MathFunction fDx = f.derive('x')..simplify();
    MathFunction fDy = f.derive('y')..simplify();
    MathFunction fDz = f.derive('z')..simplify();

    cm.bindVariableName('x', new Number(intersect.hitPoint.x));
    cm.bindVariableName('y', new Number(intersect.hitPoint.y));
    cm.bindVariableName('z', new Number(intersect.hitPoint.z));

    double gradX = fDx.evaluate(EvaluationType.REAL, cm);
    double gradY = fDy.evaluate(EvaluationType.REAL, cm);
    double gradZ = fDz.evaluate(EvaluationType.REAL, cm);

    ret.normal = new Vector3(gradX, gradY, gradZ).normalize();

    return ret;
  }

  String toString() => 'ImplicitFunction[${f.toFullString()}]';
}
