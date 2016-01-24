import 'package:vector_math/vector_math.dart' show Vector2, Vector3, Vector4;
import 'package:math_expressions/math_expressions.dart';
import 'package:image/image.dart';
import 'dart:io' show File;

import '../lib/tracebuddy.dart';

Scene scene;
Sampler sampler;
Camera camera;
Renderer renderer;

int height, width;

/**
 * Creates the renderer and all associated objects.
*
 * The additional argument scale determines if the image will be rendered
 * in a scaled version, for example a smaller preview of half the resolution:
 * scale = 0.5.
*
 * This method performs the following steps:
*
 * 1. Create a default scene, if not yet set.
 * 2. Create a default sampler, is not yet set. This will be a [DefaultSampler].
 * 3. Create a default camera, if not yet set.
 */
void createRenderer([double scale = 1.0]) {
  // load scene
  if (scene == null) {
    Vector4 red = new Vector4(1.0,0.0,0.0,0.0);
    Vector4 green = new Vector4(0.0,1.0,0.0,0.0);
    Vector4 turquis = new Vector4(0.0,1.0,1.0,0.0);

    Shader redShader = new AmbientShader(red);
    Shader greenShader = new AmbientShader(green);
    Shader turquisShader = new AmbientShader(turquis);

    Shader phongGreenShader = new PhongShader(green, green, 50.0, green);
    Shader phongRedShader = new PhongShader(red, red, 50.0, red);
    Shader phongTurquisShader = new PhongShader(turquis, turquis, 50.0, turquis);

    List<Primitive> primitives = [new InfinitePlane(new Point3(0.0,-2.0,0.0),new Vector3(0.0, 1.0, 0.0), phongTurquisShader),
                                  new Sphere(new Point3(10.0,0.0,0.0),2,phongGreenShader),
                                  new Sphere(new Point3(-4.0,-1.0,1.0),0.2,phongRedShader)];

    Variable x = new Variable('x'), y = new Variable('y'), z = new Variable('z');
    Number two = new Number(2);
    Expression expr = (x*x) + (y*y) + (z*z) - new Number(1);
    expr = ((x*x)/two) - ((y*y)/two) + ((z*z)/two);
    //expr = ((x*x)/two) + (y*y) + ((z*z)/two) - new Number(1);

    MathFunction f = new CustomFunction('f', [x, y ,z], expr);

    primitives.add(new ImplicitFunction(f, phongGreenShader));
    scene = new Scene(primitives);
  }

  // add coordinate system
  scene.displayCCS(true);

  // load sampler
  if (sampler == null) {
    //TODO apply quality settings?
    sampler = new DefaultSampler();
  }

  // load camera
  if (camera == null) {
    Point3 cameraOrigin = new Point3(-5.0,2.0,-5.0);
    Vector2 res = new Vector2(width.toDouble(),height.toDouble());

    camera = new PerspectiveCamera.lookAt(
        cameraOrigin,
        new Point3(0.0,0.0,0.0),
        new Vector3(0.0,1.0,0.0),
        60,
        res);
  }

  // create renderer
  renderer = new Renderer(scene, sampler, camera);
}

// renders a scene and writes the output to a file
main() async {
  // create scene and camera
  width = 320;
  height = 240;
  createRenderer();

  // render the image
  OutputMatrix om = renderer.render();

  // write image and scale up
  Image image = new Image.fromBytes(width, height, om.getSerializedRGBA());
  Image scaledImage = copyResize(image, width * 2);

  File file = await new File('image.png').writeAsBytes(encodePng(scaledImage));
  print('Output image written to ${file}!');
}
