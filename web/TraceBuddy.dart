import 'dart:html';
import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/algebra.dart';
import '../rt/ray.dart';

import 'package:vector_math/vector_math_console.dart';

int xRes, yRes;

void main() {
  xRes = 400;
  yRes = 300;
  
  CanvasElement imageCanvas = query("#image");
  imageCanvas.width = xRes;
  imageCanvas.height = yRes;
  
  Sampler sampler = new DefaultSampler();
  Camera camera = new PerspectiveCamera(
      new Point3D.zero(),
      new vec3.raw(1,0,0),
      new vec3.raw(0,1,0),
      60,
      new vec2.raw(xRes, yRes));
  
  Collection<Primitive> primitives = [new InfinitePlane(new Point3D(0,-2,0),new vec3.raw(0, 1, 0)),
                                      new Sphere(new Point3D(10,0,0),2)];
  
  Scene scene = new Scene(primitives);
  
  Renderer r = new Renderer(scene, sampler, camera);
  OutputMatrix om = r.render();
  
  AsciiDumper.dumpAsciiRGB(om);
  
  writeToCanvas2d(om, imageCanvas);
}

writeToCanvas2d(OutputMatrix om, CanvasElement canvas) {
  ImageData id = canvas.context2d.createImageData(om.columns, om.rows);
  
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

class AsciiDumper {
  static void dumpAsciiRGB(OutputMatrix om) {
    //List<String> outputMatrixString = new List<String>(om.rows);
    for (int row = 1; row < om.rows; row++) {
      List<String> rowString = new List<String>();
      for (vec3 rgb in om.getRow(row)) {
        if (isBlack(rgb)) rowString.add('-');
        else if (isWhite(rgb)) rowString.add('W');
        else if (isRed(rgb)) rowString.add('R');
        else if (isGreen(rgb)) rowString.add('G');
        else if (isBlue(rgb)) rowString.add('B');
        else rowString.add(rgb.toString());
      }
      
      print('ROW $row: $rowString');
    }
  }

  static bool isBlack(vec3 rgb) => rgb.x == 0 && rgb.y == 0 && rgb.z == 0;
  static bool isWhite(vec3 rgb) => rgb.x == 1 && rgb.y == 1 && rgb.z == 1;
  static bool isRed(vec3 rgb) => rgb.x == 1 && rgb.y == 0 && rgb.z == 0;
  static bool isGreen(vec3 rgb) => rgb.x == 0 && rgb.y == 1 && rgb.z == 0;
  static bool isBlue(vec3 rgb) => rgb.x == 0 && rgb.y == 0 && rgb.z == 1;
}