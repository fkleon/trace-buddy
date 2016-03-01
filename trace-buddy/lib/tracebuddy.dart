/**
 * TraceBuddy is a general purpose ray tracer.
 *
 * However, it's primary goal is to support rendering implicit functions using
 * interval arithmetics.
 */
library tracebuddy;

import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' show Vector2, Vector3, Vector4;
import 'package:vector_math/vector_math.dart' as VectorMath show Ray;
import 'package:math_expressions/math_expressions.dart';

part 'src/basics.dart';
part 'src/renderer.dart';
part 'src/samplers.dart';
part 'src/scene.dart';
part 'src/shaders.dart';
