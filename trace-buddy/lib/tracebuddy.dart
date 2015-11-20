/**
 * TraceBuddy is a raytracer to render implicit functions.
 */
library tracebuddy;

import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' show Vector2, Vector3, Vector4;
import 'package:math_expressions/math_expressions.dart';

part 'src/basics.dart';
part 'src/renderer.dart';
part 'src/samplers.dart';
part 'src/scene.dart';
part 'src/shaders.dart';