import 'dart:html';
import 'dart:isolate';

import 'package:vector_math/vector_math.dart' show Vector2, Vector3, Vector4;
import 'package:math_expressions/math_expressions.dart';

import '../rt/renderer.dart';
import '../rt/samplers.dart';
import '../rt/basics.dart';
import '../rt/shaders.dart';
import '../rt/scene.dart';

/// Global reference to the view.
var view;

/// Global reference to the controller.
var rc;

// main entry point for application
void main() {
  rc = new RenderController();
  view = new TraceBuddyView(rc);
  rc.view = view;

  window.onLoad.listen((e) => query('#glassplate').style.display='none');
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

  /**
   * Renders the scene.
   *
   * With the optional argument scale can be determined that a lower resolution
   * preview should be rendered. A scale of 0.5 will render the image in half
   * the size.
   *
   * The result of the rendering process is stored in the [OutputMatric] member
   * `om` of this renderer.
   */
  void renderScene([double scale = 1.0]) {
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

    this.view.renderInfo = 'Done. Rendered in ${timeForRender/1000.0} s.';
  }

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

      List<Primitive> primitives = [new InfinitePlane(new Point3D(0.0,-2.0,0.0),new Vector3(0.0, 1.0, 0.0), phongTurquisShader),
                                    new Sphere(new Point3D(10.0,0.0,0.0),2,phongGreenShader),
                                    new Sphere(new Point3D(-4.0,-1.0,1.0),0.2,phongRedShader)];

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
    scene.displayCCS(view == null ? true : view.renderCoords);

    // load sampler
    if (sampler == null) {
      //TODO apply quality settings?
      sampler = new DefaultSampler();
    }

    // load camera
    if (camera == null) {
      Point3D cameraOrigin = view == null ? new Point3D(-5.0,2.0,-5.0) : this.view.cameraOrigin;
      Vector2 res = view == null ? new Vector2(300.0,200.0) : this.view.res.scale(scale);

      camera = new PerspectiveCamera.lookAt(
          cameraOrigin,
          new Point3D(0.0,0.0,0.0),
          new Vector3(0.0,1.0,0.0),
          60,
          res);
    }

    // create renderer
    renderer = new Renderer(scene, sampler, camera);
  }

  /**
   * Rotates the camera around the origin and rerenders the image.
   */
  void rotate(num horAngle, num verAngle) {
    this.camera.rotate(horAngle, verAngle);
    view.xOriginStr = camera.center.x.toString();
    view.yOriginStr = camera.center.y.toString();
    view.zOriginStr = camera.center.z.toString();
    view.render();
  }

  /**
   * Zooms the camera with given distance and rerenders the image.
   */
  void zoom(num distance) {
    this.camera.zoom(distance);
    view.xOriginStr = camera.center.x.toString();
    view.yOriginStr = camera.center.y.toString();
    view.zOriginStr = camera.center.z.toString();
    view.render();
  }

  /**
   * creates a new custom function from the string that is in the function_field text input.
   * The shader is a phongshader with the current color of the colorpicker.
   * The name of the function is queried from the function_name field.
   */
  void add_function(){
    view.functionAddError = '';
    Parser pars = new Parser();
    Vector4 color = createColorVec();
    Shader dynamicShader = new PhongShader(color , color , 50.0, color);

    InputElement functionElement = query('#function_field');
    InputElement nameElement = query('#function_name');

    Expression customExpr;

    try {
      customExpr = pars.parse(functionElement.value);
    } catch (e) {
      view.functionAddError = e.toString();
      return;
    }

    functionElement.value = "";

    Variable x = new Variable('x'), y = new Variable('y'), z = new Variable('z');

    MathFunction func = new CustomFunction(nameElement.value,[x,y,z], customExpr);
    nameElement.value="";
    primitives.add(new ImplicitFunction(func, dynamicShader));
    scene = new Scene(primitives);
  }
  /**
   * converts an hex interger to a dezimal integer
   */
  int hexToSum(String inputHex) {
    String hex = inputHex;
    int val = 0;

    int len = hex.length;
    for (int i = 0; i < len; i++) {
      int hexDigit = hex.codeUnitAt(i);
      if (hexDigit >= 48 && hexDigit <= 57) {
        val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 65 && hexDigit <= 70) {
        // A..F
        val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
      } else if (hexDigit >= 97 && hexDigit <= 102) {
        // a..f
        val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
      } else {
        throw new ArgumentError("Bad hexidecimal value");
      }
    }

    return val;
  }
  /**
   * creates a Vector4 with the rgb values of the color pickers current color
   */
  Vector4 createColorVec(){
    String colorString = view.inputColor.replaceAll("#", "");
    String rString = colorString.substring(0  , 2);
    String gString = colorString.substring(2  , 4);
    String bString = colorString.substring(4  , 6);
    int rInt = hexToSum(rString);
    int gInt = hexToSum(gString);
    int bInt = hexToSum(bString);

    return new Vector4(rInt/255, gInt/255, bInt/255,1.0);

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
      for (Vector3 rgb in om.getRow(row)) {
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

  static bool isBlack(Vector3 rgb) => rgb.x == 0 && rgb.y == 0 && rgb.z == 0;
  static bool isWhite(Vector3 rgb) => rgb.x == 1 && rgb.y == 1 && rgb.z == 1;
  static bool isRed(Vector3 rgb) => rgb.x == 1 && rgb.y == 0 && rgb.z == 0;
  static bool isGreen(Vector3 rgb) => rgb.x == 0 && rgb.y == 1 && rgb.z == 0;
  static bool isBlue(Vector3 rgb) => rgb.x == 0 && rgb.y == 0 && rgb.z == 1;
}

/**
 * A View on the HTML template, their data is kept synchronized.
 * Delegates calls to the RenderController.
 */
class TraceBuddyView {
  //TODO hardcoded x resolution of preview
  final int lowX = 20;

  // The controller
  RenderController rc;
  //get rc => _rc == null ? new RenderController(this) : _rc;

  // Render information
  String renderInfo;
  String functionAddError;

  // Scene information
  String get sceneInformation => '${primitives.length} primitives in scene.';
  List<Primitive> get primitives => rc.primitives;

  // Camera properties
  String _xResStr, _yResStr;
  String xOriginStr, yOriginStr, zOriginStr;

  // color of color picker
  String inputColor;

  // Rendering properties
  bool renderCoords;
  bool renderPreview;

  //scale factor
  num currentScale;

  get imageCanvas => query('#imageCanvas');
  get _hiddenCanvas => query('#hiddenCanvas');

  /**
   * Creates a new trace buddy view.
   *
   * Initializes image canvas, resolution, other stuff and scale factor.
   */
  TraceBuddyView(RenderController this.rc) {
    renderInfo = functionAddError = '';
    initializeImageCanvas(400, 300);
    _xResStr = '400';
    _yResStr = '300';
    xOriginStr = zOriginStr = '-5.0';
    yOriginStr = '5.0';
    renderCoords = true;
    renderPreview = false;
    currentScale = calculateScaleFactor(xRes, yRes);
    inputColor = "#0000ff";
  }

  bool controlHidden = false;

  void hideControl(){
    DivElement controls = query('#controlsDiv');
    ButtonElement butt = query('#hideButton');
    if(controlHidden){
      controls.style.display='block';
      controlHidden = false;
      butt.text = "Hide Control";
    }else{
      controls.style.display='none';
      controlHidden = true;
      butt.text = "Show Control";

    }
  }

  String get xResStr => _xResStr;
  String get yResStr => _yResStr;

  // Wrapped to recalculate scale factor on change.
  void set xResStr(String str) {
    _xResStr = str;
    currentScale = calculateScaleFactor(xRes, yRes);
    initializeImageCanvas(xRes, yRes);
  }

  // Wrapped to recalculate scale factor on change.
  void set yResStr(String str) {
    _yResStr = str;
    currentScale = calculateScaleFactor(xRes, yRes);
    initializeImageCanvas(xRes, yRes);
  }

  int get xRes => _parseInt(_xResStr);
  int get yRes => _parseInt(_yResStr);
  Vector2 get res => new Vector2(xRes.toDouble(), yRes.toDouble());

  Point3D get cameraOrigin =>
      new Point3D(_parseDouble(xOriginStr),
                  _parseDouble(yOriginStr),
                  _parseDouble(zOriginStr));

  void removePrimitive(Event e, num elementId) {
    rc.scene.remove(elementId);
    // prevent default event behaviour (html link)
    e.preventDefault();
  }


  /**
   * Calculates the scale factor of given resolution in respect to default
   * preview resolution defined by `lowX`.
   */
  num calculateScaleFactor(num xRes, num yRes) {
    double ratio = xRes / yRes;
    num lowY = lowX / ratio;
    num scaleFactor = lowX / xRes;
    return scaleFactor;
  }

  /**
   * Initializes visible image canvas with given size.
   */
  void initializeImageCanvas(int xRes, int yRes){
    imageCanvas.width = xRes;
    imageCanvas.height = yRes;
  }

  /*
   * Triggers rendering process of the scene and draws the result afterwards.
   */
  void render() {
    // TODO use isolate
    if(renderPreview) {
      print('render preview scale $currentScale');
      rc.camera = null; //TODO find nifty solution
      rc.renderScene(currentScale);
      drawImage(rc.om, currentScale);
    } else {
      rc.camera = null; //TODO find nifty solution
  //  SendPort renderer = spawnFunction(rc.renderSceneIsolate);
  //  renderer.send('test');

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
    _writeToCanvas2d(om, imageCanvas, _hiddenCanvas, scale);
    this.renderInfo = '${renderInfo} Drawn in ${timer.elapsedMilliseconds/1000} s.';
  }

  /*
   * Writes a given [OutputMatrix] to the 2d context of a given [CanvasElement].
   */
  void _writeToCanvas2d(OutputMatrix om, CanvasElement imageCanvas, CanvasElement hiddenCanvas, num scale) {
    // make sure canvas is big enough
    hiddenCanvas.width = om.columns;
    hiddenCanvas.height = om.rows;

    // convert OM information to canvas information
    ImageData id = hiddenCanvas.context2D.createImageData(om.columns, om.rows);

    CanvasRenderingContext2D destCon = imageCanvas.context2D;
    int i = 0;
    for (Vector3 color in om.getSerialized()) {
      // set RGBA
      id.data[i++] = asRgbInt(color[0]);
      id.data[i++] = asRgbInt(color[1]);
      id.data[i++] = asRgbInt(color[2]);
      id.data[i++] = 255;
    }

    hiddenCanvas.context2D.putImageData(id,0,0);
    destCon.setTransform(1, 0, 0, 1, 0, 0);
    destCon.scale(1/scale, 1/scale);
    destCon.drawImage(hiddenCanvas,0,0);
  }

  /*
   * Converts a double [0..1] to a RGB int [0..255].
   */
  int asRgbInt(double value) {
    assert(value >= 0 || value <= 1);
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