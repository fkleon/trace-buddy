library rt_sampler;

import 'package:vector_math/vector_math_console.dart';

// a sample definition consists of a position within a pixel
// and a weigth of the sample.
class Sample {
  
  vec2 position;
  num weight;
  
  Sample(this.position, this.weight);
}

// abstract class for all samplers to extend
abstract class Sampler {
  
  // generates samples for the given pixel
  Collection<Sample> getSamples(int x, int y);
}

// the default sampler generates one sample per pixel
class DefaultSampler extends Sampler {
  
  Collection<Sample> getSamples(int x, int y) {
    var sample = new Sample(new vec2.raw(0.5,0.5), 1);
    return [sample];
  }
}

// the regular sampler generates xSamples*ySamples samples per pixel,
// distributed regularly.
class RegularSampler extends Sampler {
  
  int xSamples,ySamples;
  
  RegularSampler(this.xSamples, this.ySamples): super();
  
  Collection<Sample> getSamples(int x, int y) {
    List<Sample> samples = new List<Sample>(xSamples*ySamples);
    
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
