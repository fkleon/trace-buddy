library rt_sampler;

import 'package:vector_math/vector_math_console.dart';

/**
 * A [Sample] has a position within a pixel and a weigth.
 */
class Sample {

  /// The sample's position within a pixel: [0..1]
  vec2 position;
  num weight;

  /**
   * Creates a new [Sample] with the given position and weigth.
   *
   * The position is defined within a pixel and must be in the interval [0..1].
   * The weigth also spans from 0 to 1.
   *
   * Usage:
   *     Sample s = new Sample(0.5, 1.0);
   */
  Sample(this.position, this.weight);
}

/**
 * A [Sampler] generates samples for a given pixel.
 */
abstract class Sampler {

  /**
   * Returns a collection of samples for the given pixel.
   */
  Collection<Sample> getSamples(int x, int y);
}

/**
 * The [DefaultSampler] generates one sample per pixel,
 * which is positioned in the middel of the pixel.
 */
class DefaultSampler extends Sampler {

  Collection<Sample> getSamples(int x, int y) {
    var sample = new Sample(new vec2.raw(0.5,0.5), 1);
    return [sample];
  }
}

/**
 * The [RegularSampler] generates multiple samples per pixel,
 * distributed regularly.
 */
class RegularSampler extends Sampler {

  int xSamples, ySamples;

  /**
   * Creates a new [RegularSampler], which generates xSamples*ySamples samples
   * per pixel.
   */
  RegularSampler(this.xSamples, this.ySamples): super();

  Collection<Sample> getSamples(int x, int y) {
    List<Sample> samples = new List<Sample>.fixedLength(xSamples*ySamples);

    for (int cx = 0; cx < xSamples; cx++) {
      for (int cy = 0; cy < ySamples; cy++) {
        vec2 pos = new vec2.raw(x,y);
        pos = (pos + new vec2.raw(0.5, 0.5)) / (new vec2.raw(xSamples, ySamples));

        samples.add(new Sample(pos, (1/(xSamples*ySamples))));
      }
    }

    return samples;
  }
}
