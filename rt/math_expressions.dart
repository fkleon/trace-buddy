//import 'algebra.dart' as Alg show Interval;
import 'dart:math' as Math;

abstract class Expression {
  
  Expression operator+(Expression exp) => new Plus(this, exp);
  Expression operator-(Expression exp) => null;
  Expression operator*(Expression exp) => new Times(this, exp);
  Expression operator/(Expression exp) => null;
  
  num evaluate();
  
  Expression derive(String toVar);
  
  String toString();
}

abstract class BinaryExpression extends Expression {
  Expression left, right;
  
  BinaryExpression(this.left, this.right);
}

abstract class UnaryExpression extends Expression {
  Expression exp;
  
  UnaryExpression(this.exp);
}

class Plus extends BinaryExpression {
  
  Plus(left, right): super(left, right);

  num evaluate() => left.evaluate() + right.evaluate();
  
  Expression derive(String toVar) => new Plus(left.derive(toVar), right.derive(toVar));
  
  String toString() => '(${left.toString()} + ${right.toString()})';
}

/*
class Minus extends Expression {
  Expression expLeft, expRight;
  
  Minus(Expression this.expLeft, Expression this.expRight);
  
  num evaluate() => expLeft.evaluate() - expRight.evaluate();
}*/

class Times extends BinaryExpression {
  Times(left, right): super(left, right);
  num evaluate() => left.evaluate() * right.evaluate();
  Expression derive(String toVar) => new Plus(new Times(left, right.derive(toVar)), new Times(left.derive(toVar), right));
  String toString() => '(${left.toString()} * ${right.toString()})';
}

class Power extends BinaryExpression { //TODO implement as general exponential function?
  Power(x, exponent): super(x, exponent);
  num evaluate() => Math.pow(left.evaluate(), right.evaluate());
  Expression derive(String toVar) => new Times(new Power(left, right.derive(toVar)), left.derive(toVar)); //TODO this is wrong
  String toString() => '(${left.toString()}^${right.toString()})';
}

abstract class Literal extends Expression {
  var value;
  
  Literal([var this.value]);
  
  String toString() => value.toString();
  
  Expression simplify() => this;
}

class Number extends Literal {
    
  Number(num value): super(value);
  
  num evaluate() => value;
  
  Expression derive(String toVar) => new Number(0);
}

class Variable extends Literal {
  String name;
  
  Variable(String this.name);
  
  void bindTo(Expression binding) {
    this.value = binding;
  }
  
  //TODO how to evaluate?
  num evaluate() => value == null ? throw new ArgumentError('Variable ${value} is not bound.') : value.evaluate();
  
  Expression derive(String toVar) => name == toVar ? new Number(1) : new Number(0);
  
  String toString() => name;
}

class Interval extends Literal {
  Interval(num min, num max) : super(new Alg.Interval(min, max));
  
  num evaluate() => value; //TODO whis will break
  
  Expression derive(String toVar) => new Number(0); //TODO this is wrong
}

void main() {
  Expression x = new Variable('x'), a = new Variable('a'), b = new Variable('b'), c = new Variable('c');
  //Expression pow = new Power(x, new Number(2));
  //Expression e = a+b;
  //Expression e = a*pow+b*x+c;
  Expression e = a*x*x+b*x+c;
  print(e);
  print(e.derive('x'));
}

class Tokenizer {
  //TODO
}

class Parser {
  //TODO
}

class Evaluator {
  // TODO
}