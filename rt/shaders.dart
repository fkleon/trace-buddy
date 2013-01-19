library rt_shader;

import 'dart:math' as Math;
import 'package:vector_math/vector_math_console.dart' show vec3, vec4;
import '../math/algebra.dart' show Point3D;

/**
 * A [Shader] determines the appearance of a [Primitive] at
 * a certain hit point.
 * 
 * It can calculate the reflectance, ambient coefficient and
 * indirect radiance.
 */
abstract class Shader {
  
  /**
   * Returns the reflectance for the associated [Primitive] at the associated
   * hitpoint and and for the given direction vectors.
   * 
   * The parameter outDir is the vector from the hit point in direction of its
   * origin. The parameter inDir is vector from the hit point in direction of
   * the light source.
   * 
   * Returns the zero vector, if the shader does not support reflectance.
   */
  vec4 getReflectance(vec3 outDir, vec3 inDir) {
    return new vec4.zero();
  }
  
  /**
   * Returns the ambient coefficient of the primitive at the hit point.
   * Returns the zero vector, if shader does not support ambient lighting.
   */
  vec4 getAmbientCoeff() {
    return new vec4.zero();
  }
  
  /**
   * Returns the radiance which comes from indirect illumination.
   * This is the case for a reflected ray on a mirror.
   * Returns the zero vector, if shader does not support indirect radiance.
   */
  vec4 getIndirectRadiance() {
    return new vec4.zero();
  }
  
  /**
   * Returns a hard copy (clone) of the current shader.
   */
  Shader clone();
}

/**
 * A [PluggableShader] can be used together with a primitive.
 * It is aware of its location and its surface normal to return
 * the proper radiance.
 */
abstract class PluggableShader extends Shader {
  
  /// The position of the hit point.
  Point3D position;
  
  vec3 _normal; // normalized
  
  set normal(vec3 normal) => _normal = normal.normalize();
  
  /// The normal vector at the hit point. Must be stored in normalized form.
  get normal => _normal;
  
  //TODO vertex and texture support would go in here..
}

/**
 * A [AmbientShader] returns radiance based on its ambient coefficient.
 */
class AmbientShader extends PluggableShader {
  
  /// The ambient coefficient of this shader.
  final vec4 ambCoeff;
  
  /**
   * Createa a new AmbientShader.
   */
  AmbientShader(this.ambCoeff);
  
  vec4 getAmbientCoeff() => ambCoeff;
  
  Shader clone() => new AmbientShader(new vec4.copy(ambCoeff));
}

/**
 * A [PhongShader] uses the phong reflection model to determine the surface
 * radiance.
 * 
 * For a more detailed description of the mechanism see the article on the
 * [Phong Reflection Model](https://en.wikipedia.org/wiki/Phong_reflection_model).
 */
class PhongShader extends AmbientShader {
  
  /// The diffuse and specular coefficient of this phong shader.
  final vec4 difCoeff, specCoeff;
  
  /// The specular exponent of this phong shader.
  final double specExp;
  
  /**
   * Creates a new Phong Shader with the given diffuse, specular and ambient
   * coefficients as well as the given specular exponent.
   */
  PhongShader(this.difCoeff, this.specCoeff, this.specExp, vec4 ambCoeff) : super(ambCoeff);
  
  vec4 getReflectance(vec3 outDir, vec3 inDir) {
    vec4 Cs = this.specCoeff;
    vec4 Cd = this.difCoeff;
    double Ce = this.specExp;
        
    vec3 halfVect = (inDir.normalize() + outDir.normalize()).normalize();
    double specCoeff = Math.max(halfVect.dot(normal), 0.0);
    specCoeff = Math.exp(Math.log(specCoeff) * Ce);
    double diffCoeff = Math.max(normal.dot(inDir.normalize()), 0.0);
    
    return
        new vec4.raw(diffCoeff, diffCoeff, diffCoeff, diffCoeff) * Cd
        + new vec4.raw(specCoeff, specCoeff, specCoeff, specCoeff) * Cs;
  }
  
  Shader clone() =>
      new PhongShader(new vec4.copy(difCoeff),
                      new vec4.copy(specCoeff),
                      specExp, ambCoeff);
}