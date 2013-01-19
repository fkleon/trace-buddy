import 'dart:html';
import 'dart:isolate';

import 'package:vector_math/vector_math_console.dart';

import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../math/algebra.dart';
import '../rt/ray.dart';
import '../rt/shaders.dart';

import '../math/math_expressions.dart';

var view;
var rc;

// main entry point for application
void main() {
  rc = new RenderController();
  view = new TraceBuddyView(rc);
  rc.view = view;

  window.on.load.add((e) => query('#glassplate').style.display='none');
}

/**
 * The [RenderController] is responsible for communicating
 * with the render engine. It keeps references to the [Renderer],
 * [Camera], [Sampler] and [OutputMatrix].
 */
class RenderController {
  // view
  TraceBuddyView view;

  // rendering stuff
  Scene scene;
  Camera camera;
  Sampler sampler;
  Renderer renderer;
  OutputMatrix om;

  RenderController() {
    // initialize renderer
    createRenderer(1);
  }

  get primitives => scene.nonIdxPrimitives;

  void renderSceneIsolate() {
    port.receive((_,__) {
      renderScene();
      print('done');
    });
  }

  void renderScene([num scale = 1]) {
    if (view == null) {
      throw new ArgumentError('Did not define a view.'); //TODO remove this non-sense
    }
    createRenderer(scale);

    this.view.renderInfo = 'rendering..';

    // time the process
    var timer = new Stopwatch();
    timer.start();

    // render the scene
    om = renderer.render();
    //AsciiDumper.dumpAsciiRGB(om);

    num timeForRender = timer.elapsedMilliseconds;

    // write the image to canvas element
    //TODO use view
//    writeToCanvas2d(om, imageCanvasElement);

    this.view.renderInfo = 'Done. Rendered in ${timeForRender/1000.0} s.';
  }


  void createRenderer(num scale) {
    // load scene
    if (scene == null) {
      vec4 red = new vec4.raw(1,0,0,0);
      vec4 green = new vec4.raw(0,1,0,0);
      vec4 turquis = new vec4.raw(0,1,1,0);

      Shader redShader = new AmbientShader(red);
      Shader greenShader = new AmbientShader(green);
      Shader turquisShader = new AmbientShader(turquis);

      Shader phongGreenShader = new PhongShader(green, green, 50.0, green);
      Shader phongRedShader = new PhongShader(red, red, 50.0, red);
      Shader phongTurquisShader = new PhongShader(turquis, turquis, 50.0, turquis);

      Collection<Primitive> primitives = [new InfinitePlane(new Point3D(0,-2,0),new vec3.raw(0, 1, 0), phongTurquisShader),
                                          new Sphere(new Point3D(10,0,0),2,phongGreenShader),
                                          new Sphere(new Point3D(-4,-1,1),0.2,phongRedShader)];

      Variable x = new Variable('x'), y = new Variable('y'), z = new Variable('z');
      Number two = new Number(2);
      Expression expr = (x*x) + (y*y) + (z*z) - new Number(1);
      expr = ((x*x)/two) - ((y*y)/two) + ((z*z)/two);
      //expr = ((x*x)/two) + (y*y) + ((z*z)/two) - new Number(1);

      MathFunction f = new CustomFunction('f', [x, y ,z], expr);

      primitives = [new ImplicitFunction(f, phongGreenShader)];
      scene = new Scene(primitives);
    }

    // add coordinate system
    scene.displayCCS(view == null ? true : view.renderCoords);

    // load sampler
    if (sampler == null) {
      //TODO apply quality settings?
      sampler = new DefaultSampler();
    }

    //reset imageCanvas


    // load camera
    if (camera == null) {
      Point3D cameraOrigin = view == null ? new Point3D(-5,2,-5) : this.view.cameraOrigin;
      vec2 res = view == null ? new vec2.raw(300,200) : this.view.res.scale(1/scale);

      camera = new PerspectiveCamera.lookAt(
          cameraOrigin,
          new Point3D(0,0,0),
          new vec3.raw(0,1,0),
          60,
          res);
  //    camera = new PerspectiveCamera(
  //        new Point3D(-10,2,-1),
  //        new vec3.raw(1,-0.5,0),
  //        new vec3.raw(0,1,0),
  //        60,
  //        new vec2.raw(xRes, yRes));

//      camera = new PerspectiveCamera.lookAt(
//          new Point3D(-5,2,-5),
//          new Point3D(0,0,0),
//          new vec3.raw(0,1,0),
//          60,
//          new vec2.raw(xRes, yRes));
    }

    // create renderer
    renderer = new Renderer(scene, sampler, camera);
  }

  /**
   * rotates the camera around the origin and rerenders the image.
   */
  void rotate(num horAngle, num verAngle){
    this.camera.rotate(horAngle, verAngle);
    view.xOriginStr = camera.center.x.toString();
    view.yOriginStr = camera.center.y.toString();
    view.zOriginStr = camera.center.z.toString();
    view.render();
  }

  void zoom(num distance){
    this.camera.zoom(distance);
    view.xOriginStr = camera.center.x.toString();
    view.yOriginStr = camera.center.y.toString();
    view.zOriginStr = camera.center.z.toString();
    view.render();
  }

}

/**
 * The [AsciiDumper] writes a given [OutputMatrix] to console as ASCII.
 * It only supports white, black, red, green and blue.
 */
class AsciiDumper {
  static void dumpAsciiRGB(OutputMatrix om) {
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

/**
 * A View on the HTML template, their data is kept synchronized.
 * Delegates calls to the RenderController.
 */
class TraceBuddyView {
  RenderController rc;
  //get rc => _rc == null ? new RenderController(this) : _rc;

  // Render information
  String renderInfo;

  // Scene information
  String get sceneInformation => '${primitives.length} primitives in scene.';
  List<Primitive> get primitives => rc.primitives;

  // Camera properties
  String _xResStr, _yResStr;
  String xOriginStr, yOriginStr, zOriginStr;

  // Rendering properties
  bool renderCoords;
  bool renderPreview;

  //scale factor
  num currentScale;

  get imageCanvas => query('#imageCanvas');
  get hiddenCanvas => query('#hiddenCanvas');
  TraceBuddyView(RenderController this.rc) {
    renderInfo = '';
    initializeImageCanvas(400, 300);
    _xResStr = '400';
    _yResStr = '300';
    xOriginStr = zOriginStr = '-5.0';
    yOriginStr = '5.0';
    renderCoords = true;
    renderPreview = false;
    currentScale = calculateScaleFactor(xRes, yRes);
  }

 void set xResStr(String str){
   _xResStr = str;
   currentScale = calculateScaleFactor(xRes, yRes);
   initializeImageCanvas(xRes, yRes);
 }

 String get xResStr => _xResStr;

 void set yResStr(String str){
   _yResStr = str;
   currentScale = calculateScaleFactor(xRes, yRes);
   initializeImageCanvas(xRes, yRes);
 }

 String get yResStr => _yResStr;
 int get xRes => _parseInt(_xResStr);
 int get yRes => _parseInt(_yResStr);
 vec2 get res => new vec2.raw(xRes, yRes);

 Point3D get cameraOrigin =>
      new Point3D(_parseDouble(xOriginStr),
                  _parseDouble(yOriginStr),
                  _parseDouble(zOriginStr));

 void removePrimitive(Event e) {
   Element target = (e.target as Element);
   int elementId = int.parse(target.attributes['data-item-id']);
   rc.scene.remove(elementId);
   e.preventDefault();
 }
 //TODO delete later
  final int lowX = 120;
 num calculateScaleFactor(num resX, num resY){
   double ratio = resX / resY;
   num lowY = lowX/ratio;
   num scaleFactor = resX / lowX;
   return scaleFactor;
 }

 void initializeImageCanvas(num xRes, num yRes){
   imageCanvas.width = xRes;
   imageCanvas.height = yRes;
 }

 /*
  * Triggers rendering process of the scene and draws the result afterwards.
  */
 void render() {

 if(renderPreview){
   rc.camera = null; //TODO find nifty solution
   print(currentScale);
   rc.renderScene(currentScale);
   drawImage(rc.om,currentScale);
   // TODO use isolate
   // TODO write method
 } else {
   rc.camera = null; //TODO find nifty solution

//   SendPort renderer = spawnFunction(rc.renderSceneIsolate);
//   renderer.send('test');

   rc.renderScene();
   //AsciiDumper.dumpAsciiRGB(rc.om);

   drawImage(rc.om);
   }
 }

 /*
  * Draws the given [OutputMatrix] into the Canvas.
  */
 void drawImage(OutputMatrix om, [num scale = 1]) {
   var timer = new Stopwatch();
   timer.start();
   _writeToCanvas2d(om, imageCanvas, hiddenCanvas, scale);
   this.renderInfo = '${renderInfo} Drawn in ${timer.elapsedMilliseconds/1000} s.';
 }

 /*
  * Writes a given [OutputMatrix] to the 2d context of a given [CanvasElement].
  */
 void _writeToCanvas2d(OutputMatrix om, CanvasElement imageCanvas, CanvasElement hiddenCanvas, num scale) {
   // make sure canvas is big enough
   hiddenCanvas.width = om.columns;
   hiddenCanvas.height = om.rows;

   // convert OM infomration to canvas information
   ImageData id = hiddenCanvas.context2d.createImageData(om.columns, om.rows);


   CanvasRenderingContext2D destCon = imageCanvas.context2d;
   int i = 0;
   for (vec3 color in om.getSerialized()) {
     // set RGBA
     id.data[i++] = asRgbInt(color[0]);
     id.data[i++] = asRgbInt(color[1]);
     id.data[i++] = asRgbInt(color[2]);
     id.data[i++] = 255;
   }

   hiddenCanvas.context2d.putImageData(id,0,0);
   destCon.setTransform(1, 0, 0, 1, 0, 0);
   destCon.scale(scale, scale);
   destCon.drawImage(hiddenCanvas,0,0);
 }

 /*
  * Converts a double [0..1] to a RGB int [0..255].
  */
 int asRgbInt(num value) {
   return (value*255).toInt();
 }

 /*
  * Parses a string to int.
  *
  * Returns 0 if input is illegal.
  */
 int _parseInt(String value) {
   try {
     return int.parse(value);
   } on FormatException catch (e) {
     print('Illegal integer: $value ($e)');
     return 0;
   }
 }

 /*
  * Parses a string to double.
  *
  * Returns 0.0 if input is illegal.
  */
 double _parseDouble(String value) {
   try {
     return double.parse(value);
   } on FormatException catch (e) {
     print('Illegal double: $value ($e)');
     return 0.0;
   }
 }
}