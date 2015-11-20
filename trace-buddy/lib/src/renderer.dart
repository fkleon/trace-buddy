part of tracebuddy;

/**
 * Matrix containing the output colors at every pixel of the final image
 * set by the renderer. The color information are stored as RGB vectors,
 * with each component in the interval [0..1].
 */
class OutputMatrix {

  final int rows, columns;

  /// Color information of every pixel. Stored in a serialized form:
  /// `[(row1_col1, row1_col2, .. row1_colN), .. , (rowN_col1, ..)]`
  List<Vector3> _content;

  /**
   * Initializes a output matrix of size rows*columns and initially set all
   * color information to black.
   */
  OutputMatrix(int this.rows, int this.columns) {
    // init the array (serialized matrix)
    _content = new List<Vector3>(rows*columns);

    // set all pixel to black
    clear();
  }

  /**
   * Clears the matrix to black.
   */
  void clear() {
    Vector3 black = new Vector3.zero();
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
  setPixel(int row, int column, Vector3 color) {
    if (!_isValidRow(row) || !_isValidColumn(column)) throw new ArgumentError('No such row or column: $row,$column.');

    _content[((row - 1) * columns) + (column - 1)] = color.clone();
  }

  /**
   * Sets the colors of the given row.
   *
   * Throws an argument error, if row is invalid.
   */
  setRow(int row, List<Vector3> colors) {
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
  Vector3 getPixel(int row, int column) {
    if (!_isValidColumn(column)) throw new ArgumentError('No such column: $column.');

    return _content[((row - 1) * columns) + (column - 1)];
  }

  /**
   * Returns a list of colors for given row.
   */
  Iterable<Vector3> getRow(int row) => _content.getRange((row - 1) * columns, row*columns);

  /**
   * Returns an array containing all colors in serialized form,
   * structured by row after row.
   */
  List<Vector3> getSerialized() => new List.from(_content);

  /**
   * Returns an array containing all colors in serialized RGBA byte form,
   * structured by row after row.
   */
  List<int> getSerializedRGBA() {
    // RGBA
    List<int> bytes = new List(4 * _content.length);

    int i = 0;
    for (Vector3 color in _content) {
      bytes[i++] = _asRgbInt(color[0]);
      bytes[i++] = _asRgbInt(color[1]);
      bytes[i++] = _asRgbInt(color[2]);
      bytes[i++] = 255;
    }

    return bytes;
  }

  /*
   * Converts a double [0..1] to a RGB int [0..255].
   */
  int _asRgbInt(double value) {
    assert(value >= 0 || value <= 1);
    return (value*255).toInt();
  }

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
  final Vector4 ambientLight = new Vector4(0.3, 0.3, 0.3, 0.3);

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

    List<Sample> samples;
    List<Ray> primaryRays;

    OutputMatrix om = new OutputMatrix(yRes, xRes);

    // for each pixel..
    for (int x = 0; x < xRes; x++) {

      if ((x+1) % 10 == 0) {print('Rendering column ${x+1}..');} //TODO

      for (int y = 0; y < yRes; y++) {
        // color information for this pixel
        Vector4 color = new Vector4.zero();

        // generate samples
        samples = sampler.getSamples(x, y);

        // for each sample
        for (Sample s in samples) {
          // temporary color vector for this sample
          Vector4 tempColor = new Vector4.zero();

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
              tempColor += s.getAmbientCoeff().multiply(ambientLight);
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
  List<Ray> getPrimaryRays(int x, int y);

  /**
   * Rotates this camera around the given horizontal and vertical angles.
   */
  void rotate(num horAngle, num verAngle);

  /**
   * Zooms in or out depending if the distance is positive or negativ.
   */
  void zoom(num distance);

  /// The resolution of this camera.
  Vector2 get res;
}

/**
 * The [PerspectiveCamera] generates rays for a perspective projection.
 * It is defined by its center, viewing direction, up vector,
 * vertical opening angle of the image and resolution.
 */
class PerspectiveCamera extends Camera {

  Vector3 forward, up, right;
  Vector3 topLeft, stepX, stepY;
  Vector2 _res;

  /**
   * Creates a new [PerspectiveCamera].
   * Uses a forward vector.
   */
  PerspectiveCamera(Point3D center, Vector3 this.forward, Vector3 up, num vertOpeningAngle, Vector2 this._res) {
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
  PerspectiveCamera.lookAt(Point3D center, Point3D lookAt, Vector3 up, num vertOpeningAngle, Vector2 this._res) {
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


  void _init(Point3D center, Vector3 up, num vertOpeningAngle) {
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
    Vector3 rowVector = rightAxis * (2 * Math.tan(angleInRad*0.5) * aspectRatio);
    Vector3 columnVector = upAxis * (2 * Math.tan(angleInRad*0.5));

    this.stepX = rowVector / resX;
    this.stepY = columnVector / resY;
    this.topLeft = forwardAxis - (rowVector / 2.0) - (columnVector / 2.0);
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

  List<Ray> getPrimaryRays(int x, int y) {
    Ray ret = new Ray(center, stepX*x.toDouble() + stepY*y.toDouble() + topLeft);
    return [ret];
  }

  Vector2 get res => new Vector2.copy(_res);
}
