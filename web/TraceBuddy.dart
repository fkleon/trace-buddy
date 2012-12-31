import 'dart:html';
import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/algebra.dart';
import 'package:vector_math/vector_math_console.dart';

void main() {
  CanvasElement imageCanvas = query("#image");
  imageCanvas.width = 100;
  imageCanvas.height = 100;
  
  Sampler sampler = new DefaultSampler();
  Camera camera = new PerspectiveCamera(
      new Point3D.zero(),
      new vec3.raw(0,1,0),
      new vec3.raw(1,0,0),
      60,
      new vec2.raw(10, 10));
  
  Renderer r = new Renderer(sampler,camera);
  OutputMatrix om = r.render();
  
  writeToCanvas2d(om, imageCanvas);
}

writeToCanvas2d(OutputMatrix om, CanvasElement canvas) {
  ImageData id = canvas.context2d.createImageData(om.rows, om.columns);
  
  int i = 0;
  for (vec3 color in om.getSerialized()) {
    // set RGBA
    id.data[i++] = color[0].toInt()*255;
    id.data[i++] = color[1].toInt()*255;
    id.data[i++] = color[2].toInt()*255;
    id.data[i++] = 255;
  }
  
  canvas.context2d.putImageData(id, 0, 0);
}