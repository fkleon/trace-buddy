part of rt_basics;

// floating-Point3D relative accuracy
const num EPS = 0.000001; 

// represents a ray/object intersection Point3D
class Intersection {
  
  // the distance to the intersection
  num distance;
  Primitive prim;
  Point3D hitPoint;
  
  //TODO default values
  Intersection([num this.distance = -1, Primitive this.prim = null]); // intersection distance defaults to -1 (no intersetion)
}

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
  
  int get nextId => ++_lastId;
}

// an object which can be contained within a scene
// - can be an arbitraty geometric shape, mathematical function, etc.
abstract class Primitive {
  
  int id;
  
  Primitive() : id = new IdGen().nextId;
  
  Intersection intersect(Ray ray, num previousBestDistance);
  
  Point3D get origin => null;
  
  vec3 get color => new vec3.raw(1,1,1); // TODO
}

// basically a collection of primitives which together form the scene to be rendered
class Scene extends Primitive {
  // non indexable primitives
  List<Primitive> nonIdxPrimitives;
  
  // creates a new scene, can be initialized with the given primitives
  Scene([Collection<Primitive> primitives]) {
    if (?primitives) {
      this.nonIdxPrimitives = primitives;
    } else {
      this.nonIdxPrimitives = new List<Primitive>();
    }
  }
  
  void add(Primitive p) {
    this.nonIdxPrimitives.add(p);
  }
  
  void remove(int primId) {
    print ('remove $primId');
    
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
  
  void removeCartesianCoordSystems() {
    List<int> ids = new List<int>();
    
    for (int i = 0; i<nonIdxPrimitives.length; i++) {
      if (nonIdxPrimitives[i] is CartesianCoordinateSystem) ids.add(i);
    }
    
    for (int i in ids) {
      nonIdxPrimitives.removeAt(i);
    }
  }
  
  // performs a ray intersection with this scene
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
    Intersection bestHit = new Intersection(bestDistance, bestPrimitive);
    return bestHit;
  }
  
  // TODO indexable primitives
  // TODO acceleration structure?
  // TODO rebuild index
}

// a infinite plane specified by given equation
class InfinitePlane extends Primitive {
  
  vec4 equation;
  Point3D origin;
  
  InfinitePlane(Point3D this.origin, vec3 normal) {
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
      
      // TODO encapsulate hit Point3D?
      intersect.distance = dist;
      intersect.prim = this;
      intersect.hitPoint = r.getPoint3D(dist);
      //print('HitPoint is ${intersect.hitPoint}');
    }
    
    return intersect;
  }
}

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
}

// a sphere
class Sphere extends Primitive {
  
  Point3D center;
  num radius;
  
  Point3D get origin => center;
  
  Sphere(Point3D this.center, num this.radius) {
    if (radius<=0) throw new ArgumentError('Radius of sphere must not be zero or less');
  }
  
  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();
    
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

      //TODO encapsulate hit Point3D?
      intersect.distance = dist;
      intersect.prim = this;
    }
    
    return intersect;
  }
}