trace-buddy
===========

A browser-based raytracer aimed at rendering implicit mathematical functions, written in the [Dart programming language][dartlang].  
It runs natively in [Dartium][], a browser including the Dart VM, but the
source code can be compiled to JavaScript for general compatibility with all modern browsers.

The algorithm used by trace-buddy to find ray intersections with implicit function is based on interval arithmetic<sup>1</sup>.
The approach narrows down the possible intersection candidates until more efficient root finding algorithms can be applied.
It has been described by several authors, including Hart<sup>2</sup> and Knoll et al.<sup>3</sup>.

Distributed under the MIT License, see [LICENSE][] file.

### Usage Information
tbd

### Developer Information
Have a look at the [DartDoc of trace-buddy][tracedoc] to gain a general overview over its internal architecture.

#### Dependencies
Add the following dependencies to your pubspec.yaml:

```dart
dependencies:
  browser: any
  vector_math: 0.9.2
  unittest: any
  benchmark_harness: ">=1.0.0 <2.0.0"
  web_ui: any
```

vector_math needs to be adjusted..

#### Compiling
see build.dart

- - -
<sub>[1] Bohlender, Gerd, and Ulrich Kulisch. 2010. ["Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard."][bohlender2010] Reliable Computing 15 (1): 36–42.</sub>  
<sub>[2] Hart, John C. 1993. ["Ray Tracing Implicit Surfaces."][hart1993] SIGGRAPH ’93 Course Notes: Design, Visualization and Animation of Implicit Surfaces.</sub>  
<sub>[3] Knoll, Aaron, Younis Hijazi, Andrew Kensler, Mathias Schott, Charles Hansen, and Hans Hagen. 2009. ["Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic."][knoll2009] Computer Graphics Forum 28 (1): 26–40.</sub>

[dartlang]: http://www.dartlang.org "Dart Language"
[dartium]: http://www.dartlang.org/dartium "Dartium"
[license]: https://github.com/fkleon/trace-buddy/edit/master/LICENSE "trace-buddy License"
[tracedoc]: https://130.185.104.44/trace-buddy/docs "trace-buddy DartDoc"
[hart1993]: http://mathinfo.univ-reims.fr/IMG/pdf/ray-tracing-implicit-surfaces.pdf "Ray Tracing Implicit Surfaces, PDF"
[knoll2009]: http://www.cs.utah.edu/~knolla/cgrtia.pdf "Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic, PDF"
[bohlender2010]: http://interval.louisiana.edu/reliable-computing-journal/volume-15/no-1/reliable-computing-15-pp-36-42.pdf "Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard, PDF"