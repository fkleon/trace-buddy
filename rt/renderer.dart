library rt_renderer;

import 'dart:math' as Math;

import 'package:vector_math/vector_math_console.dart' show tan, vec2, vec3, vec4;
import '../math/algebra.dart' show Point3D;

import 'basics.dart' show EPS, Ray, Intersection;
import 'samplers.dart' show Sample, Sampler;
import 'scene.dart' show Scene;
import 'shaders.dart' show Shader;

/**
 * Matrix containing the output colors at every pixel of the final image
 * set by the renderer. The color information are stored as RGB vectors,
 * with each component in the interval [0..1].
 */
class OutputMatrix {

  final int rows, columns;

  /// Color information of every pixel. Stored in a serialized form:
  /// `[(row1_col1, row1_col2, .. row1_colN), .. , (rowN_col1, ..)]`
  List<vec3> _content;

  /**
   * Initializes a output matrix of size rows*columns and initially set all
   * color information to black.
   */
  OutputMatrix(int this.rows, int this.columns) {
    // init the array (serialized matrix)
    _content = new List<vec3>.fixedLength(rows*columns);

    // set all pixel to black
    clear();
  }

  /**
   * Clears the matrix to black.
   */
  void clear() {
    vec3 black = new vec3.zero();
    for (int i = 0; i<rows*columns; i++) {
      _content[i] = black;
    }
  }

  /**
   * Sets the given pixel to given color.
   *
   * Note:
   * width = row,
   * heigth = column. //TODO: really? this sounds wrong..
   *
   * Throws an argument error, if either row or column does not exist.
   *
   */
  setPixel(int row, int column, vec3 color) {
    if (!_isValidRow(row) || !_isValidColumn(column)) throw new ArgumentError('No such row or column: $row,$column.');

    _content[((row - 1) * columns) + (column - 1)] = color.clone();
  }

  /**
   * Sets the colors of the given row.
   *
   * Throws an argument error, if row is invalid.
   */
  setRow(int row, List<vec3> colors) {
    if (!_isValidRow(row)) throw new ArgumentError('No such row: $row.');

    int startIndex = (row-1)*columns;
    for (int i = 0; i<columns; i++) {
      _content[((row - 1) * columns) + i] = colors[i].clone();
    }
  }

  /**
   * Returns the color of a pixel.
   *
   * Throws an argument error, if column is invalid.
   */
  vec3 getPixel(int row, int column) {
    if (!_isValidColumn(column)) throw new ArgumentError('No such column: $column.');

    return _content[((row - 1) * columns) + (column - 1)];
  }

  /**
   * Returns a list of colors for given row.
   */
  List<vec3> getRow(int row) => _content.getRange((row - 1) * columns, columns);

  /**
   * Returns an array containing all colors in serialized form,
   * structured by row after row.
   */
  List<vec3> getSerialized() => new List.from(_content);

  bool _isValidColumn(int column) => (column > 0 && column <= columns);
  bool _isValidRow(int row) => (row > 0 && row <= rows);
}

/**
 * The [Renderer] takes a [Sampler], [Camera] and [Scene] and can render
 * an image based on this information.
 *
 * It iterates over each pixel of the image, generates samples and primary rays
 * and performs intersection tests with the scene.
 * It also acts as integrator to collect the radiance information.
 */
class Renderer {

  /// Sampler used to generate samples.
  Sampler sampler;

  /// Camera used to generate primary rays.
  Camera camera;

  /// Scene to be rendered.
  Scene scene;

  /// Resolution of the camera and final image.
  int xRes, yRes;

  /// The ambient light available in the scene.
  final vec4 ambientLight = new vec4.raw(0.3, 0.3, 0.3, 0.3);

  /**
   * Creates a new [Renderer] with the given scene, sampler and camera.
   */
  Renderer(this.scene, this.sampler, this.camera) {
    xRes = camera.res.x.toInt();
    yRes = camera.res.y.toInt();
  }

  /**
   * Renders the Scene and returns an [OutputMatrix] containing the pixels
   * of the final image.
   */
  OutputMatrix render() {

    Collection<Sample> samples;
    Collection<Ray> primaryRays;

    OutputMatrix om = new OutputMatrix(yRes, xRes);

    // for each pixel..
    for (int x = 0; x < xRes; x++) {

      if ((x+1) % 10 == 0) {print('Rendering column ${x+1}..');} //TODO

      for (int y = 0; y < yRes; y++) {
        // color information for this pixel
        vec4 color = new vec4.zero();

        // generate samples
        samples = sampler.getSamples(x, y);

        // for each sample
        for (Sample s in samples) {
          // temporary color vector for this sample
          vec4 tempColor = new vec4.zero();

          primaryRays = camera.getPrimaryRays(x, y);

          // integrate rays..
          for (Ray r in primaryRays) {

            // integrate radiance
            //TODO count bounces for indirect radiance

            Intersection ret = scene.intersect(r, 99999); //TODO fix hardcoded distance
            if (ret.distance >= EPS && ret.distance < 99999) {

              //print ('hit at ${ret.distance} with ${ret.prim} on ${ret.hitPoint}');

              // get shader
              Shader s = scene.getShader(ret);

              // get ambience, reflectance and indirect radiance
              tempColor += s.getAmbientCoeff() * ambientLight;
              //TODO for all light sources, integrate indirect radiance.
              tempColor += s.getReflectance(-r.direction, r.origin - ret.hitPoint); //TODO dummy light source at camera

              tempColor += s.getIndirectRadiance();
            }
          }

          // weight ray
          double rayWeight = 1.0 / primaryRays.length;
          tempColor.scale(rayWeight);

          // weight sample
          tempColor.scale(s.weight);

          // add to overall pixel color
          color += tempColor;

          // set pixel in output matrix
          om.setPixel(y+1, x+1, color.rgb);
        }
      }
    }

    return om;
  }
}

/**
 * A [Camera] is defined by its resolution.
 * The camera generates [Ray]s for every pixel of the image.
 */
abstract class Camera {
  Point3D center;

  /**
   * Returns a collection of primary rays generated for the given pixel
   * by this camera.
   */
  Collection<Ray> getPrimaryRays(int x, int y);

  /**
   * Rotates this camera around the given horizontal and vertical angles.
   */
  void rotate(num horAngle, num verAngle);

  /**
   * Zooms in or out depending if the distance is positive or negativ.
   */
  void zoom(num distance);

  /// The resolution of this camera.
  vec2 get res;
}

/**
 * The [PerspectiveCamera] generates rays for a perspective projection.
 * It is defined by its center, viewing direction, up vector,
 * vertical opening angle of the image and resolution.
 */
class PerspectiveCamera extends Camera {

  vec3 forward, up, right;
  vec3 topLeft, stepX, stepY;
  vec2 _res;

  /**
   * Creates a new [PerspectiveCamera].
   * Uses a forward vector.
   */
  PerspectiveCamera(Point3D center, vec3 this.forward, vec3 up, num vertOpeningAngle, vec2 this._res) {
    _init(center, up, vertOpeningAngle);

    print("Created new PerspectiveCamera:");
    print(" - resolution: $res");
    print(" - center: $center");
    print(" - forward: $forward");
    print(" - up: $up");
    print(" - right: $right");
    print(" - topLeft: $topLeft");
    print(" - stepX: $stepX");
    print(" - stepY: $stepY");
  }

  /**
   * Creates a new [PerspectiveCamera].
   * Calculates forward vector based on given look-at point.
   */
  PerspectiveCamera.lookAt(Point3D center, Point3D lookAt, vec3 up, num vertOpeningAngle, vec2 this._res) {
    this.forward = lookAt-center;
    _init(center, up, vertOpeningAngle);

    print("Created new PerspectiveCamera:");
    print(" - resolution: $res");
    print(" - center: $center");
    print(" - lookAt: $lookAt");
    print(" - up: $up");
    print(" - right: $right");
    print(" - topLeft: $topLeft");
    print(" - stepX: $stepX");
    print(" - stepY: $stepY");
  }


  void _init(Point3D center, vec3 up, num vertOpeningAngle) {
    this.center = center;

    num resX = _res.x.toDouble();
    num resY = _res.y.toDouble();
    num aspectRatio = resX/resY;

    // calculate axis vectors
    var forwardAxis = forward.normalize();
    var rightAxis = forward.cross(up).normalize();
    var upAxis = -(rightAxis.cross(forwardAxis).normalize());

    this.up = upAxis;
    this.right = rightAxis;

    // angle from degree to radians
    num angleInRad = vertOpeningAngle * Math.PI / 180;
    vec3 rowVector = rightAxis * (2 * tan(angleInRad*0.5) * aspectRatio);
    vec3 columnVector = upAxis * (2 * tan(angleInRad*0.5));

    this.stepX = rowVector / resX;
    this.stepY = columnVector / resY;
    this.topLeft = forwardAxis - (rowVector / 2) - (columnVector / 2);
  }

  void rotate(num horAngle, num verAngle) {
    num horRadiance = horAngle * (Math.PI / 180);
    num verRadiance = verAngle * (Math.PI / 180);

    // First rotate around the y axis
    num x = center.x * Math.cos(horRadiance) + center.z * Math.sin(horRadiance);
    num y = center.y;
    num z = center.x * -(Math.sin(horRadiance)) + center.z * Math.cos(horRadiance);

    center = new Point3D(x, y, z);

    // Then rotate up and down around origin
    num myAxisX = right.x;
    num myAxisY = right.y;
    num myAxisZ = right.z;

    num rotX = (myAxisX * myAxisX * (1 - Math.cos(verRadiance)) + Math.cos(verRadiance))* center.x + (myAxisX * myAxisY *(1 - Math.cos(verRadiance)) - myAxisZ * Math.sin(verRadiance))*center.y + (myAxisX * myAxisZ *(1 - Math.cos(verRadiance)) + myAxisY * Math.sin(verRadiance))*center.z;
    num rotY = (myAxisY * myAxisX * (1 - Math.cos(verRadiance)) + myAxisZ * Math.sin(verRadiance))*center.x + (myAxisY * myAxisY * (1 - Math.cos(verRadiance)) + Math.cos(verRadiance))*center.y + (myAxisY * myAxisZ * (1 - Math.cos(verRadiance)) - myAxisX * Math.sin(verRadiance))*center.z;
    num rotZ = (myAxisZ * myAxisX * (1 - Math.cos(verRadiance)) - myAxisY * Math.sin(verRadiance))*center.x + (myAxisZ * myAxisY * (1 - Math.cos(verRadiance)) + myAxisX * Math.sin(verRadiance))*center.y + (myAxisZ * myAxisZ * (1 - Math.cos(verRadiance)) + Math.cos(verRadiance))*center.z;

    center = new Point3D(rotX, rotY, rotZ);
  }

  void zoom(num distance) {
    // Move the camera origin along the forward direction
    num newCenterX = center.x + distance * forward.x;
    num newCenterY = center.y + distance * forward.y;
    num newCenterZ = center.z + distance * forward.z;

    center = new Point3D(newCenterX, newCenterY, newCenterZ);
  }

  Collection<Ray> getPrimaryRays(int x, int y) {
    Ray ret = new Ray(center, stepX*x + stepY*y + topLeft);
    return [ret];
  }

  vec2 get res => new vec2.copy(_res);
}