import 'dart:html';
import 'dart:isolate';

import 'package:vector_math/vector_math_console.dart';

import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/algebra.dart';
import '../rt/ray.dart';
import '../rt/shaders.dart';

var view;
var rc;

// main entry point for application
void main() {
  rc = new RenderController();
  view = new TraceBuddyView(rc);
  rc.view = view;
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
    createRenderer();
  }
  
  get primitives => scene.nonIdxPrimitives;
  
  void renderSceneIsolate() {
    port.receive((_,__) {
      renderScene();
      print('done');
    });
  }
  
  void renderScene() {
    if (view == null) {
      throw new ArgumentError('Did not define a view.'); //TODO remove this non-sense
    }
    createRenderer();
    
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
  
  void createRenderer() {
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
                                          new CartesianCoordinateSystem(),
                                          new Sphere(new Point3D(10,0,0),2,phongGreenShader),
                                          new Sphere(new Point3D(-4,-1,1),0.2,phongRedShader)];
      scene = new Scene(primitives);
    }
    
    // add coordinate system
    
    //TODO this is a ugly hack
    scene.removeCartesianCoordSystems();
    if (view == null ? true : view.renderCoords) {
      scene.add(new CartesianCoordinateSystem());
    }
    
    // load sampler
    if (sampler == null) {
      //TODO apply quality settings?
      sampler = new DefaultSampler();
    }
    
    // load camera
    if (camera == null) {
      Point3D cameraOrigin = view == null ? new Point3D(-5,2,-5) : this.view.cameraOrigin;
      vec2 res = view == null ? new vec2.raw(300,200) : this.view.res;
      
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
  String xResStr, yResStr;
  String xOriginStr, yOriginStr, zOriginStr;
  
  // Rendering properties
  bool renderCoords;
  
  get imageCanvas => query('#imageCanvas');
  
  TraceBuddyView(RenderController this.rc) {
    renderInfo = '';
    xResStr = '400';
    yResStr = '300';
    xOriginStr = zOriginStr = '-5.0';
    yOriginStr = '5.0';
    renderCoords = true;
    imageCanvas.width = xRes;
    imageCanvas.height = yRes;
  }
 
 int get xRes => _parseInt(xResStr);
 int get yRes => _parseInt(yResStr);
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
 
 /*
  * Triggers rendering process of the scene and draws the result afterwards.
  */
 void render() {
   // TODO use isolate
   // TODO write method
   rc.camera = null; //TODO find nifty solution
   
//   SendPort renderer = spawnFunction(rc.renderSceneIsolate);
//   renderer.send('test');
   
   rc.renderScene();
   //AsciiDumper.dumpAsciiRGB(rc.om);
   
   drawImage(rc.om);
 }
 
 /*
  * Draws the given [OutputMatrix] into the Canvas.
  */
 void drawImage(OutputMatrix om) {
   var timer = new Stopwatch();
   timer.start();
   _writeToCanvas2d(om, imageCanvas);
   this.renderInfo = '${renderInfo} Drawn in ${timer.elapsedMilliseconds/1000} s.';
 }
 
 /*
  * Writes a given [OutputMatrix] to the 2d context of a given [CanvasElement].
  */
 void _writeToCanvas2d(OutputMatrix om, CanvasElement canvas) {
   // make sure canvas is big enough
   canvas.width = om.columns;
   canvas.height = om.rows;
   
   // convert OM infomration to canvas information
   ImageData id = canvas.context2d.createImageData(om.columns, om.rows);
   
   int i = 0;
   for (vec3 color in om.getSerialized()) {
     // set RGBA
     id.data[i++] = asRgbInt(color[0]);
     id.data[i++] = asRgbInt(color[1]);
     id.data[i++] = asRgbInt(color[2]);
     id.data[i++] = 255;
   }
   
   canvas.context2d.putImageData(id, 0, 0);
 }
 
 /*
  * Updates the colors of the primitives in the GUI list.
  */

 
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