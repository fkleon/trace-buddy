library rt_renderer;

import 'dart:math' as Math;
import 'ray.dart';
import 'algebra.dart' show Point3D;
import 'samplers.dart' show Sample, Sampler;
import 'shaders.dart' show Shader;
import 'package:vector_math/vector_math_console.dart' show tan, vec2, vec3, vec4;

// contains the output colors set at every pixel
// color is a RGB vec3, each component in the interval [0..1]
class OutputMatrix {
  
  final int rows, columns;
  List<vec3> _content; // [(row1_col1, row1_col2, .. row1_colN), .. , (rowN_col1, ..)]
  
  // initializes matrix of size rows*columns,
  // sets all colors to black.
  OutputMatrix(int this.rows, int this.columns) {
    // init the array (serialized matrix)
    _content = new List<vec3>(rows*columns);
    
    // set all pixel to black
    clear();
  }
  
  // clears image to black
  clear() {
    vec3 black = new vec3.zero();
    for (int i = 0; i<rows*columns; i++) {
      _content[i] = black;
    }
  }
  
  // sets given pixel to given color
  // x=width=row, y=height=column
  setPixel(int row,int column,vec3 color) {
    if (!isValidRow(row) || !isValidColumn(column)) throw new ArgumentError('No such row or column: $row,$column.');
    
    _content[((row-1)*columns)+(column-1)] = color.clone();
  }
  
  // sets given row to given color row
  setRow(int row, List<vec3> colors) {
    if (!isValidRow(row)) throw new ArgumentError('No such row: $row.');
    
    int startIndex = (row-1)*columns;
    for (int i = 0; i<columns; i++) {
      _content[((row-1)*columns)+i] = colors[i].clone();
    }
  }
  
  // returns the color of given pixel
  vec3 getPixel(int row, int column) {
    if (!isValidColumn(column)) throw new ArgumentError('No such column: $column.');
    return _content[((row-1)*columns)+(column-1)];
  }
  
  // returns a list of colors for given row
  List<vec3> getRow(int row) => _content.getRange((row-1)*columns, columns);
  
  // returns an array containing all colors
  // structured by row after row
  List<vec3> getSerialized() => new List.from(_content);
  
  bool isValidColumn(int column) => (column>0 && column<=columns);
  bool isValidRow(int row) => (row>0 && row<=rows);
}

class Renderer {
  
  Sampler sampler;
  Camera camera;
  Scene scene;
  int xRes, yRes;
  
  final vec4 ambientLight = new vec4.raw(0.3,0.3,0.3,0.3);
  
  Renderer(this.scene, this.sampler, this.camera) {
    xRes = camera.res.x.toInt();
    yRes = camera.res.y.toInt(); 
  }
   
  OutputMatrix render() {
    
    Collection<Sample> samples;
    Collection<Ray> primaryRays;
        
    OutputMatrix om = new OutputMatrix(yRes, xRes);
    
    // for each pixel..
    for (int x = 0; x<xRes; x++) {
      if (x%10 == 0) {
        print('Rendering line ${x+1}..');
      }
      for (int y = 0; y<yRes; y++) {
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
              tempColor += s.getReflectance(-r.direction, new Point3D(0, 20, 0) - ret.hitPoint); //TODO dummy light source
              
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
  Collection<Ray> getPrimaryRays(int x, int y);
  vec2 get res;
}

/**
 * The [PerspectiveCamera] generates rays for a perspective projection.
 * It is defined by its center, viweing direction, up vector,
 * vertical opening angle of the image and resolution.
 */
class PerspectiveCamera extends Camera {
  
  Point3D center;
  vec3 forward, up, right;
  vec3 topLeft, stepX, stepY;
  vec2 _res;
  
  PerspectiveCamera(Point3D this.center, vec3 this.forward, vec3 up, num vertOpeningAngle, vec2 this._res) {
    init(up, vertOpeningAngle);
    
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
  
  PerspectiveCamera.lookAt(Point3D this.center, Point3D lookAt, vec3 up, num vertOpeningAngle, vec2 this._res) {
    this.forward = lookAt-center;
    init(up, vertOpeningAngle);
    
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
  
  void init(vec3 up, num vertOpeningAngle) {
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

  Collection<Ray> getPrimaryRays(int x, int y) {
    Ray ret = new Ray(center, stepX*x + stepY*y + topLeft);
    return [ret];
  }
  
  vec2 get res => new vec2.copy(_res);
}