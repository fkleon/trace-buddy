part of rt_basics;

// floating-Point3D relative accuracy
const num EPS = 0.000001; 

/**
 * The [Intersection] class represents a ray/object intersection.
 * It contains the distance to the hit point, the affected [Primitive],
 * and the hit point as [Point3D].
 * 
 * If there is no hit, distance will be negative.
 */
class Intersection {
  
  // the distance to the intersection
  num distance;
  Point3D hitPoint;

  // affected primitive
  Primitive prim;
  
  /*
   * Creates a new [Intersection object].
   * 
   * Default values are distance = -1, prim = null;
   */
  Intersection([this.distance = -1, this.prim = null, this.hitPoint]);
}

/**
 * The [IdGen] is a simple unique ID generator. It uses sequential ids.
 * 
 * Furthermore, IdGen is a singleton. Every instance will reference the
 * same generator.
 * 
 * Usage example:
 *  var id = new IdGen().nextId(); // 1
 *  id = new IdGen().nextId(); // 2
 * 
 */
class IdGen {
  int _lastId;
  
  static IdGen _instance;
 
  factory IdGen() {
    if (_instance == null) {
      _instance = new IdGen._internal();
    }
    return _instance;
  }
  
  IdGen._internal() : _lastId=0;
  
  int nextId() => ++_lastId;
}


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
  
  int id;
  Shader _shader;
  
  Primitive([Shader this._shader]) : id = new IdGen().nextId() {
    if (_shader == null) {
      _shader = new AmbientShader(new vec4.raw(1,0,0,0));
    }
  }

  /*
   * Performs a ray - primitive intersection test.
   * Returns an [Intersection] object.
   */
  Intersection intersect(Ray ray, num previousBestDistance);
  
  /*
   * Returns the shader for a given intersection point.
   */
  Shader getShader(Intersection intersect);

  /*
   * The following getters are only used to display information in the GUI.
   */
  // the origin of the primitive.
  Point3D get origin => null;
  // The primary color of the primitive as vector4.
  vec4 get color => _shader == null ? new vec4.zero() : _shader.getAmbientCoeff();
  // The primary color of the primitive as CSS rgba string.
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
  
  // non indexable primitives
  List<Primitive> nonIdxPrimitives;
  
  /*
   * Creates a new [Scene]. Takes an optional parameter primitives,
   * which initialized the scene with the given primitives instead
   * of creating an empty one.
   */
  Scene([Collection<Primitive> primitives]) {
    if (?primitives) {
      this.nonIdxPrimitives = new List<Primitive>.from(primitives);
    } else {
      this.nonIdxPrimitives = new List<Primitive>();
    }
  }
  
  /*
   * Adds the given [Primitive] to the scene.
   */
  void add(Primitive p) {
    this.nonIdxPrimitives.add(p);
  }
  
  /*
   * Removes the [Primitive] with given id from the scene.
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
  
  /*
   * Removes the cartesian coordiante system from the scene.
   * //TODO hack
   */
  void removeCartesianCoordSystems() {
    List<int> ids = new List<int>();
    
    for (int i = 0; i<nonIdxPrimitives.length; i++) {
      if (nonIdxPrimitives[i] is CartesianCoordinateSystem) ids.add(i);
    }
    
    for (int i in ids) {
      nonIdxPrimitives.removeAt(i);
    }
  }
  
  /*
   * Performs a ray - scene intersection.
   * 
   * Iterates over all primitives and calls their intersect.
   * Will only return hit points which are closer than the specified
   * prevBestDistance.
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
  // TODO acceleration structure?
  // TODO rebuild index
}

/**
 * An [InfinitePlane] is specified by its plane equation.
 */
class InfinitePlane extends Primitive {
  
  vec4 equation;
  Point3D origin;
  
  /*
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
 * it represents the x,y and z-axes.
 */
class CartesianCoordinateSystem extends Primitive {
  
  static Primitive _instance;
  
  factory CartesianCoordinateSystem() {
    if (_instance == null) {
      _instance = new CartesianCoordinateSystem._internal();
    }
    return _instance;
  }
  
  CartesianCoordinateSystem._internal() {
    var origin = new Point3D.zero();
    this._xAxis = new InfinitePlane(origin, new vec3.raw(0, 1, 0));
    this._yAxis = new InfinitePlane(origin, new vec3.raw(1, 0, 0));
    this._zAxis = new InfinitePlane(origin, new vec3.raw(0, 1, 0));
  }
  
  final double THRESH = 0.02;
  InfinitePlane _xAxis, _yAxis, _zAxis;
  
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
  
  Point3D center;
  num radius;
  
  Point3D get origin => center;
  
  Sphere(Point3D this.center, num this.radius, [Shader shader]) : super(shader) {
    if (radius<=0) throw new ArgumentError('Radius of sphere must not be zero or less');
  }
  
  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();
    
    //TODO more efficient algorithm
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