part of rt_basics;

// floating-Point3D relative accuracy
const num EPS = 0.000001; 

// represents a ray/object intersection Point3D
class Intersection {
  
  // the distance to the intersection
  num distance;
  Primitive prim;
  
  //TODO default values
  Intersection([num this.distance = -1, Primitive this.prim = null]); // intersection distance defaults to -1 (no intersetion)
}

// an object which can be contained within a scene
// - can be an arbitraty geometric shape, mathematical function, etc.
abstract class Primitive {
  
  Intersection intersect(Ray ray, num previousBestDistance);
  
  vec3 get color => new vec3.raw(1,1,1); // TODO
}

// basically a collection of primitives which together form the scene to be rendered
class Scene extends Primitive {
  // non indexable primitives
  Collection<Primitive> nonIdxPrimitives;
  
  // creates a new scene, can be initialized with the given primitives
  Scene([Collection<Primitive> primitives]) {
    if (?primitives) {
      this.nonIdxPrimitives = primitives;
    } else {
      this.nonIdxPrimitives = new List<Primitive>();
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
  
  InfinitePlane(Point3D origin, vec3 normal) {
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
    }
    
    return intersect;
  }
}

// a sphere
class Sphere extends Primitive {
  
  Point3D center;
  num radius;
  
  Sphere(Point3D this.center, num this.radius);
  
  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();
    
    num A = r.direction.dot(r.direction);
    num B = (r.origin - this.center).dot(r.direction) * 2;
    num C = (r.origin - this.center).dot(r.origin - this.center) - (this.radius * this.radius);
    num det = B * B - 4 * A * C;
    
    if (det >= 0) {
      num sol1 = (-B + sqrt(det)) / (2 * A);
      num sol2 = (-B - sqrt(det)) / (2 * A);
      
      if (sol1 >= sol2) {
        swap(sol1,sol2);
      }
      
      num dist = sol1 > EPS ? sol1 : sol2;

      //TODO encapsulate hit Point3D?
      intersect.distance = dist;
      intersect.prim = this;
    }
    
    return intersect;
  }
  
  void swap(a, b) {
    var temp = a;
    a = b;
    b = temp;
  }
}