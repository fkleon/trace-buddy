/*
 * math_expressions
 * 
 * Copyright (c) 2013 Frederik Leonhardt <frederik.leonhardt@gmail.com>,
 *                    Michael Frey
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished
 * to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library math_expressions;
import 'dart:math' as Math;

part 'expression.dart';
part 'parser.dart';
part 'evaluator.dart';

void main() {
  _expressionTest();  
}

void _expressionTest() {
  Expression x = new Variable('x'), a = new Variable('a'), b = new Variable('b'), c = new Variable('c');
  //Expression pow = new Power(x, new Number(2));
  //Expression e = a+b;
  //Expression e = a*pow+b*x+c;
  //Expression e = a*x*x+b*x+c;
  //print(e);
  //print(e.derive('x'));
  
  Expression exp = new Power('x', 2);
  Expression mul = new Times('x', 'x');
  
  
  print('exp: ${exp.toString()}');
  print('expD: ${exp.derive('x').toString()}');
  print('expDSimp: ${exp.derive('x').simplify().toString()}');
  print('expDSimpDSimp: ${exp.derive('x').simplify().derive('x').simplify().toString()}');
  print('expDD: ${exp.derive('x').derive('x').toString()}');
  print('expDDSimp: ${exp.derive('x').derive('x').simplify().toString()}');

  print('mul: ${mul.toString()}');
  print('mulD: ${mul.derive('x').toString()}');
  print('mulDSimp: ${mul.derive('x').simplify().toString()}');

  Expression div = new Divide(exp, 'x');
  print('div: ${div.toString()}');
  print('divD: ${div.derive('x').toString()}');
  print('divDSimp: ${div.derive('x').simplify().toString()}');
  
  
  Expression log = new Log(new Number(10), exp);
  print('log: ${log.toString()}');
  print('logD: ${log.derive('x').toString()}');
  print('logDSimp: ${log.derive('x').simplify().toString()}');
  
  
  Expression expXY = x^a;
  print('expXY: ${expXY.toString()}');
  print('expXYD: ${expXY.derive('x').toString()}');
  print('expXYDsimp: ${expXY.derive('x').simplify().toString()}');

  Expression sqrt = new Sqrt(exp);
  print('sqrt: ${sqrt.toString()}');
  print('sqrtD: ${sqrt.derive('x').toString()}');
  print('sqrtDsimpl: ${sqrt.derive('x').simplify().toString()}');
  
  Expression root = new Root(5, exp);
  print('root: ${root.toString()}');
  print('rootD: ${root.derive('x').toString()}');
  print('rootDsimpl: ${root.derive('x').simplify().toString()}');
  
  Expression negate = -exp;
  print(negate);
  
  Expression vector = new Vector([x*new Number(1), div, exp]);
  print('vector: ${vector}');
  print('vectorS: ${vector.simplify()}');
  print('vectorSD: ${vector.simplify().derive('x')}');
  
  Expression logVar = new Log(new Number(11), new Variable('x'));
  print('logVar: ${logVar.toString()}');
  print('logVarD: ${logVar.derive('x').toString()}');
  
  Expression composite = new CompositeFunction(logVar, sqrt);
  print('composite: ${composite.toString()}');
  print('compositeD: ${composite.derive('x').toString()}');
  print('compositeDS: ${composite.derive('x').simplify().toString()}');

  Expression fExpr = new Vector([x, new Plus(x,1), new Minus(x,1)]); // Transforms x to 3-dimensional vector
  MathFunction f = new CustomFunction('f', [x], fExpr);     // R -> R^3
  Expression gExpr = x + a + b;
  MathFunction g = new CustomFunction('g', [x, a, b], gExpr);      // R^3 -> R
  composite = new CompositeFunction(f, g); // R -> R
  
  print('composite2: ${composite.toString()}');
}