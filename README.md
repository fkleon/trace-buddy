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
Have a look at the [Wiki pages][tracewiki] for example screenshots and usage information.  
For now you can find a [live demo of trace-buddy here][tracedemo] (best viewed in Chrome, which includes a native HTML5 color picker).

### Developer Information
Have a look at the [DartDoc of trace-buddy][tracedoc] to gain a general overview over its internal architecture.

#### Dependencies
For a list of dependencies, see [pubspec.yaml](pubspec.yaml).

After importing the project in Dart Editor, run the unit test suites to make sure that everything is set up correctly.

#### Compiling
When used with the DartEditor, the build.dart script automatically compiles the web_ui components to `web/out/`.

- - -
<sub>[1] Bohlender, Gerd, and Ulrich Kulisch. 2010. ["Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard."][bohlender2010] Reliable Computing 15 (1): 36–42.</sub>  
<sub>[2] Hart, John C. 1993. ["Ray Tracing Implicit Surfaces."][hart1993] SIGGRAPH ’93 Course Notes: Design, Visualization and Animation of Implicit Surfaces.</sub>  
<sub>[3] Knoll, Aaron, Younis Hijazi, Andrew Kensler, Mathias Schott, Charles Hansen, and Hans Hagen. 2009. ["Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic."][knoll2009] Computer Graphics Forum 28 (1): 26–40.</sub>

[dartlang]: http://www.dartlang.org "Dart Language"
[dartium]: http://www.dartlang.org/dartium "Dartium"
[license]: https://github.com/fkleon/trace-buddy/edit/master/LICENSE "trace-buddy License"
[tracedoc]: https://130.185.104.44/trace-buddy/docs "trace-buddy DartDoc"
[tracedemo]: https://130.185.104.44/trace-buddy/demo/out/TraceBuddy.html "trace-buddy live demo"
[tracewiki]: https://github.com/fkleon/trace-buddy/wiki "trace-buddy wiki"
[hart1993]: http://mathinfo.univ-reims.fr/IMG/pdf/ray-tracing-implicit-surfaces.pdf "Ray Tracing Implicit Surfaces, PDF"
[knoll2009]: http://www.cs.utah.edu/~knolla/cgrtia.pdf "Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic, PDF"
[bohlender2010]: http://interval.louisiana.edu/reliable-computing-journal/volume-15/no-1/reliable-computing-15-pp-36-42.pdf "Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard, PDF"
