library rt_renderer;

import 'dart:math' as math;
import 'ray.dart';
import 'algebra.dart';
import 'samplers.dart';
import 'package:vector_math/vector_math_console.dart';

main() {
  Sampler sampler = new DefaultSampler();
  Camera camera = new PerspectiveCamera(
      new Point.zero(),
      new vec3.raw(0,1,0),
      new vec3.raw(1,0,0),
      60,
      new vec2.raw(10, 10));
  
  Renderer r = new Renderer(sampler,camera);
  r.render();
}

class Renderer {
  
  Sampler sampler;
  Camera camera;
  //Integrator integrator;
  //Image target;
  
  Renderer(this.sampler, this.camera);
   
  void render() {
    
    Collection<Sample> samples;
    Collection<Ray> primaryRays;
    
    Collection<Primitive> primitives = [new InfinitePlane(new Point(0,-2,0),new vec3.raw(0, 1, 0)),
                                        new Sphere(new Point(0,-10,0),4)];
    
    Scene scene = new Scene(primitives);
    
    // for each pixel..
    for (int x = 0; x<100; x++) {
      for (int y = 0; y<100; y++) {
        // generate samples
        samples = sampler.getSamples(x, y);
        
        // for each sample
        for (Sample s in samples) {
          primaryRays = camera.getPrimaryRays(x, y);
          // integrate..
          //TODO
          for (Ray r in primaryRays) {
            Intersection ret = scene.intersect(r, 99999);
            print ("Ret ${ret.distance} distance and ${ret.prim} primitive.");
          }
        }
      }
    }
  }
}

abstract class Camera {
  Collection<Ray> getPrimaryRays(int x, int y);
}

class PerspectiveCamera extends Camera {
  
  Point center;
  vec3 forward, up, right;
  vec3 topLeft, stepX, stepY;
  vec2 res;
  
  PerspectiveCamera(Point this.center, vec3 this.forward, vec3 up, num vertOpeningAngle, vec2 this.res) {
    num resX = res.x.toDouble();
    num resY = res.y.toDouble();
    num aspectRatio = resX/resY;
    
    // calculate axis vectors
    var forwardAxis = forward.normalize();
    var rightAxis = forward.cross(up).normalize();
    var upAxis = -(rightAxis.cross(forwardAxis).normalize());
    
    this.up = upAxis;
    this.right = rightAxis;
    
    // angle to radians
    num angleInRad = vertOpeningAngle * math.PI / 180;
    vec3 rowVector = rightAxis * (2 * tan(angleInRad*0.5) * aspectRatio);
    vec3 columnVector = upAxis * (2 * tan(angleInRad*0.5));

    this.stepX = rowVector / resX;
    this.stepY = columnVector / resY;
    this.topLeft = forwardAxis - (rowVector / 2) - (columnVector / 2);
  }
  
  Collection<Ray> getPrimaryRays(int x, int y) {
    Ray ret = new Ray(center, stepX*x + stepY*y + topLeft);
    return [ret];
  }
}