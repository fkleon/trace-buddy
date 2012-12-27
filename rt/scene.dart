import 'ray.dart';
import 'algebra.dart';
import 'package:vector_math/vector_math_console.dart';

// floating-point relative accuracy
const num EPS = 0.000001; 

// represents a ray/object intersection point
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
}

// basically a collection of primitives which together form the scene to be rendered
class Scene extends Primitive {
  // non indexable primitives
  List<Primitive> nonIdxPrimitives;
  
  // creates a new scene, can be initialized with the given primitives
  Scene({List<Primitive> primitives}) {
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
  
  InfinitePlane(Point origin, vec3 normal) {
    var w = -normal.dot(origin.toVec3());
    equation = new vec4(normal, w);
  }
  
  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();
    
    var div = new vec4(r.direction).dot(equation);
    if (div.abs() > EPS) {
      var dist = (-new vec4(r.origin).dot(equation)) / div;
      intersect.distance = dist;
      intersect.prim = this;
    }
    
    return intersect;
  }
}

// a sphere
class Sphere extends Primitive {
  
  Point center;
  num radius;
  
  Sphere(Point this.center, num this.radius);
  
  Intersection intersect(Ray r, num prevBestDistance) {
    Intersection intersect = new Intersection();
    
    var A = r.direction * r.direction;
    var B = 2 * (r.origin - this.center) * r.direction;
    vec3 v3 = (r.origin-this.center);
    var C = (r.origin - this.center) * (r.origin - this.center) - (this.radius * this.radius);
  }
}