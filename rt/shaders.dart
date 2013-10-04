library rt_shader;

import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' show Vector3, Vector4;
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
  Vector4 getReflectance(Vector3 outDir, Vector3 inDir) {
    return new Vector4.zero();
  }

  /**
   * Returns the ambient coefficient of the primitive at the hit point.
   * Returns the zero vector, if shader does not support ambient lighting.
   */
  Vector4 getAmbientCoeff() {
    return new Vector4.zero();
  }

  /**
   * Returns the radiance which comes from indirect illumination.
   * This is the case for a reflected ray on a mirror.
   * Returns the zero vector, if shader does not support indirect radiance.
   */
  Vector4 getIndirectRadiance() {
    return new Vector4.zero();
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

  Vector3 _normal; // normalized

  set normal(Vector3 normal) => _normal = normal.normalize();

  /// The normal vector at the hit point. Must be stored in normalized form.
  get normal => _normal;

  //TODO vertex and texture support would go in here..
}

/**
 * A [AmbientShader] returns radiance based on its ambient coefficient.
 */
class AmbientShader extends PluggableShader {

  /// The ambient coefficient of this shader.
  final Vector4 ambCoeff;

  /**
   * Createa a new AmbientShader.
   */
  AmbientShader(this.ambCoeff);

  Vector4 getAmbientCoeff() => new Vector4.copy(ambCoeff);

  Shader clone() => new AmbientShader(new Vector4.copy(ambCoeff));
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
  final Vector4 difCoeff, specCoeff;

  /// The specular exponent of this phong shader.
  final double specExp;

  /**
   * Creates a new Phong Shader with the given diffuse, specular and ambient
   * coefficients as well as the given specular exponent.
   */
  PhongShader(this.difCoeff, this.specCoeff, this.specExp, Vector4 ambCoeff) : super(ambCoeff);

  Vector4 getReflectance(Vector3 outDir, Vector3 inDir) {
    Vector4 Cs = this.specCoeff;
    Vector4 Cd = this.difCoeff;
    double Ce = this.specExp;

    Vector3 halfVect = (inDir.normalize() + outDir.normalize()).normalize();
    double specCoeff = Math.max(halfVect.dot(normal), 0.0);
    specCoeff = Math.exp(Math.log(specCoeff) * Ce);
    double diffCoeff = Math.max(normal.dot(inDir.normalize()), 0.0);

    return
        new Vector4(diffCoeff, diffCoeff, diffCoeff, diffCoeff).multiply(Cd)
        + new Vector4(specCoeff, specCoeff, specCoeff, specCoeff).multiply(Cs);
  }

  Shader clone() =>
      new PhongShader(new Vector4.copy(difCoeff),
                      new Vector4.copy(specCoeff),
                      specExp, ambCoeff);
}