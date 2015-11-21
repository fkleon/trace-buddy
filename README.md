trace-buddy
===========

A browser-based ray tracer aimed at rendering implicit mathematical functions,
written in the [Dart programming language][dartlang].
It runs natively in [Dartium][], a browser including the Dart VM, but the source
code can be compiled to JavaScript for general compatibility with all modern
browsers.

The algorithm used by trace-buddy to find ray intersections with implicit
function is based on interval arithmetic<sup>1</sup>.
The approach narrows down the possible intersection candidates until more
efficient root finding algorithms can be applied.
It has been described by several authors, including Hart<sup>2</sup> and Knoll
et al.<sup>3</sup>.

Distributed under the MIT License, see [LICENSE][] file.

### Usage
Have a look at the [Wiki pages][tracewiki] for example screenshots and usage
information.
For now you can also find a [live demo of trace-buddy here][tracedemo] (best
viewed in Chrome, which includes a native HTML5 color picker).

### Developers
Have a look at the [DartDoc of trace-buddy][tracedoc] for a general overview of
its internal architecture.

The project is structured in two parts:
* The [TraceBuddy](trace-buddy) library containing the ray tracing logic.
* The [TraceBuddy Webapp](trace-buddy-app) containing the web logic.

You can find more details about each part in their README files.

- - -
<sub>[1] Bohlender, Gerd, and Ulrich Kulisch. 2010. ["Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard."][bohlender2010] Reliable Computing 15 (1): 36–42.</sub>  
<sub>[2] Hart, John C. 1993. ["Ray Tracing Implicit Surfaces."][hart1993] SIGGRAPH ’93 Course Notes: Design, Visualization and Animation of Implicit Surfaces.</sub>  
<sub>[3] Knoll, Aaron, Younis Hijazi, Andrew Kensler, Mathias Schott, Charles Hansen, and Hans Hagen. 2009. ["Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic."][knoll2009] Computer Graphics Forum 28 (1): 26–40.</sub>

[dartlang]: https://www.dartlang.org "Dart Language"
[dartium]: https://www.dartlang.org/dartium "Dartium"
[license]: https://github.com/fkleon/trace-buddy/edit/master/LICENSE "trace-buddy License"
[tracedoc]: https://fkleon.github.io/trace-buddy "trace-buddy DartDoc"
[tracedemo]: https://dev.leonhardt.co.nz/trace-buddy/out/web/TraceBuddy.html "trace-buddy live demo"
[tracewiki]: https://github.com/fkleon/trace-buddy/wiki "trace-buddy wiki"
[hart1993]: http://mathinfo.univ-reims.fr/IMG/pdf/ray-tracing-implicit-surfaces.pdf "Ray Tracing Implicit Surfaces, PDF"
[knoll2009]: https://www.cs.utah.edu/~knolla/cgrtia.pdf "Fast Ray Tracing of Arbitrary Implicit Surfaces with Interval and Affine Arithmetic, PDF"
[bohlender2010]: http://interval.louisiana.edu/reliable-computing-journal/volume-15/no-1/reliable-computing-15-pp-36-42.pdf "Deﬁnition of the Arithmetic Operations and Comparison Relations for an Interval Arithmetic Standard, PDF"
