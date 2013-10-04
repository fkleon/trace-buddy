library rt_sampler;

import 'package:vector_math/vector_math.dart';

/**
 * A [Sample] has a position within a pixel and a weigth.
 */
class Sample {

  /// The sample's position within a pixel: [0..1]
  Vector2 position;
  double weight;

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
  List<Sample> getSamples(int x, int y);
}

/**
 * The [DefaultSampler] generates one sample per pixel,
 * which is positioned in the middel of the pixel.
 */
class DefaultSampler extends Sampler {

  List<Sample> getSamples(int x, int y) {
    var sample = new Sample(new Vector2(0.5,0.5), 1.0);
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

  List<Sample> getSamples(int x, int y) {
    List<Sample> samples = new List<Sample>(xSamples*ySamples);

    for (int cx = 0; cx < xSamples; cx++) {
      for (int cy = 0; cy < ySamples; cy++) {
        Vector2 pos = new Vector2(x.toDouble(),y.toDouble());
        pos = (pos + new Vector2(0.5, 0.5)).divide((new Vector2(xSamples.toDouble(), ySamples.toDouble())));

        samples.add(new Sample(pos, (1/(xSamples*ySamples))));
      }
    }

    return samples;
  }
}
