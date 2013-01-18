trace-buddy
===========

A browser-based raytracer aimed at rendering implicit mathematical functions, written in the [Dart programming language][dartlang].  
It runs natively in [Dartium][], a browser including the Dart VM, but the
source code can be compiled to JavaScript for general compatibility with all modern browsers.

The algorithm used by trace-buddy to find ray intersections with implicit function is based on interval arithmetic and has been described by Hart<sup>1</sup> and Knoll et al.<sup>2</sup>.

Distributed under the MIT License, see [LICENSE][] file.

### Usage Information
tbd

### Developer Information
Have a look at the [DartDoc of trace-buddy][tracedoc] to gain a general overview over its internal architecture.

#### Dependencies
Add the following dependencies to your pubspec.yaml:

```dart
dependencies:
  vector_math: 0.9.2
  unittest: any
  benchmark_harness: ">=1.0.0 <2.0.0"
  web_ui: any
```

vector_math needs to be adjusted..

#### Compiling
see build.dart

- - -
<sub>[1] Hart, John C. 1993. ["Ray Tracing Implicit Surfaces."][hart1993] SIGGRAPH ’93 Course Notes: Design, Visualization and Animation of Implicit Surfaces.</sub>  
<sub>[2] Knoll, Aaron, Younis Hijazi, Andrew Kensler, Mathias Schott, Charles Hansen, and Hans Hagen. 2009. ["Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic."][knoll2009] Computer Graphics Forum 28 (1): 26–40.</sub>

[dartlang]: http://www.dartlang.org "Dart Language"
[dartium]: http://www.dartlang.org/dartium "Dartium"
[license]: https://github.com/fkleon/trace-buddy/edit/master/LICENSE "trace-buddy License"
[tracedoc]: https://130.185.104.44/trace-buddy/docs "trace-buddy DartDoc"
[hart1993]: http://mathinfo.univ-reims.fr/IMG/pdf/ray-tracing-implicit-surfaces.pdf "Ray Tracing Implicit Surfaces, PDF"
[knoll2009]: http://www.cs.utah.edu/~knolla/cgrtia.pdf "Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic, PDF"
