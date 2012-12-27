import 'ray.dart';

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