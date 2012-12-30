import 'dart:html';
import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/algebra.dart';
import 'package:vector_math/vector_math_console.dart';

void main() {
  CanvasElement image = query("#image");
  image.width = 100;
  image.height = 100;
  
  Sampler sampler = new DefaultSampler();
  Camera camera = new PerspectiveCamera(
      new Point3D.zero(),
      new vec3.raw(0,1,0),
      new vec3.raw(1,0,0),
      60,
      new vec2.raw(10, 10));
  
  Renderer r = new Renderer(sampler,camera);
  OutputMatrix om = r.render();
  
  ImageData id = image.context2d.createImageData(100, 100);
  //ImageData id = image.context2d.getImageData(0, 0, 100, 100);
  
  int i = 0;
  for (vec3 color in om.getSerialized()) {
    // set RGBA
    id.data[i++] = color[0].toInt()*255;
    id.data[i++] = color[1].toInt()*255;
    id.data[i++] = color[2].toInt()*255;
    id.data[i++] = 255;
  }
  
  image.context2d.putImageData(id, 0, 0);
//  image.context2d.stroke();
}