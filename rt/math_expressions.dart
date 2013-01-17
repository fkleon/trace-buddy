//import 'algebra.dart' as Alg show Interval;
import 'dart:math' as Math;

/**
 * Any Expression supports basic mathematical operations like
 * addition, subtraction, multiplication, division and power.
 * 
 * Furthermore, any expression can be differentiated with respect to
 * a given variable.
 */
abstract class Expression {
  
  Expression operator+(Expression exp) => new Plus(this, exp);
  Expression operator-(Expression exp) => new Minus(this, exp);
  Expression operator*(Expression exp) => new Times(this, exp);
  Expression operator/(Expression exp) => new Divide(this, exp);
  Expression operator^(Expression exp) => new Power(this, exp);
  
  /**
   * Derives this expression with respect to the given variable.
   */
  Expression derive(String toVar);
  
  String toString();
  
  /**
   * Converts the given argument to a valid expression.
   * 
   * Returns the argument, if it is already an expression.
   * Else wraps the argument in a [Number] or [Variable] Literal.
   * 
   * Note: Does not handle negative numbers, will treat them as positives!
   */
  Expression _toExpression(var arg) {
    if (arg is Expression) {
      return arg;
    }
    
    if (arg is num) {
      // can not handle negative numbers - use parser for this case!
      return new Number(arg);
    }
    
    if (arg is String) {
      return new Variable(arg);
    }
    
    throw new ArgumentError('${arg} is not a valid expression!');
  }
}

/**
 * A binary operator takes two expressions and performs an operation on them.
 */
abstract class BinaryOperator extends Expression {
  Expression first, second;
  
  /**
   * Creates a [BinaryOperation] from two given arguments.
   * 
   * If an argument is not an expression, it will be wrapped in an appropriate
   * literal.
   *  - A (positive) number will be encapsulated in a [Number] Literal,
   *  - A string will be encapsulated in a [Variable] Literal.
   */
  BinaryOperator(first, second) {
    this.first = _toExpression(first);
    this.second = _toExpression(second);
  }
  
  /**
   * Creates a new [BinaryOperation] from two given expressions.
   */
  BinaryOperator.raw(this.first, this.second);
}

/**
 * A unary operator takes one argument and performs an operation on it.
 */
abstract class UnaryOperator extends Expression {
  Expression exp;
  
  /**
   * Creates a [UnaryOperation] from the given argument.
   * 
   * If the argument is not an expression, it will be wrapped in an appropriate
   * literal.
   *  - A (positive) number will be encapsulated in a [Number] Literal,
   *  - A string will be encapsulated in a [Variable] Literal.
   */
  UnaryOperator(exp) {
    this.exp = _toExpression(exp);
  }
  
  /**
   * Creates a [UnaryOperation] from the given expression.
   */
  UnaryOperator.raw(this.exp);
}

/**
 * The unary minus negates its argument.
 */
class UnaryMinus extends UnaryOperator {
  
  /**
   * Creates a new unary minus operation on the given expression.
   * 
   * For example, to create -1:
   *     one = new Number(1);
   *     minus_one = new UnaryMinus(one);
   *     
   * or just:
   *     minus_one = new UnaryMinus(-1);
   */
  UnaryMinus(exp): super(exp);
  
  Expression derive(String toVar) => new UnaryMinus(exp.derive(toVar));
  String toString() => '-(${exp.toString()})';
}

/**
 * The plus operator performs an addition.
 */
class Plus extends BinaryOperator {
  
  /**
   * Creates an addition operation on the given expressions.
   * 
   * For example, to create x + 4:
   *     addition = new Plus('x', 4);
   * 
   * or:
   *     addition = new Variable('x') + new Number(4);
   */
  Plus(first, second): super(first, second);
  
  Expression derive(String toVar) => new Plus(first.derive(toVar), second.derive(toVar));
  String toString() => '(${first.toString()} + ${second.toString()})';
}

/**
 * The minus operator performs a subtraction.
 */
class Minus extends BinaryOperator {
  
  /**
   * Creates a subtaction operation on the given expressions.
   * 
   * For example, to create 5 - x:
   *     subtraction = new Minus(5, 'x');
   * 
   * or:
   *     subtraction = new Number(5) - new Variable('x');
   */
  Minus(first, second): super(first, second);
  
  Expression derive(String toVar) => new Minus(first.derive(toVar), second.derive(toVar));
  String toString() => '(${first.toString()} - ${second.toString()})';
}

/**
 * The times operator performs a multiplication.
 */
class Times extends BinaryOperator {
  
  /**
   * Creates a product operation on the given expressions.
   * 
   * For example, to create 7 * x:
   *     product = new Times(7, 'x');
   * 
   * or:
   *     product = new Number(7) * new Variable('x');
   */
  Times(first, second): super(first, second);

  Expression derive(String toVar) => new Plus(new Times(first, second.derive(toVar)), new Times(first.derive(toVar), second));
  String toString() => '(${first.toString()} * ${second.toString()})';
}

/**
 * The divide operator performs a division.
 */
class Divide extends BinaryOperator {
  
  /**
   * Creates a division operation on the given expressions.
   * 
   * For example, to create x/(y+2):
   *     div = new Divide('x', new Plus('y', 2));
   * 
   * or:
   *     div = new Variable('x') / (new Variable('y') + new Number(2));
   */
  Divide(dividend, divisor): super(dividend, divisor);
  
  Expression derive(String toVar) => ((first.derive(toVar) * second) - (first * second.derive(toVar))) / (second * second);
  String toString() => '(${first.toString()} / ${second.toString()})';
}

/**
 * The power operator.
 */
class Power extends BinaryOperator {
  
  /**
   * Creates a power operation on the given expressions.
   * 
   * For example, to create x^3:
   *     pow = new Power('x', 3);
   * 
   * or:
   *     pow = new Variable('x') ^ new Number(3);
   */
  Power(x, exp): super(x, exp);
  
  Expression derive(String toVar) => this.asE().derive(toVar);
  String toString() => '(${first.toString()}^${second.toString()})';
  
  /**
   * Returns the exponential form of this operation.
   * E.g. x^4 = e^(4x)
   * 
   * This method is used to determine the derivation of a power expression.
   */
  Expression asE() => new Exponential(second * new Ln(first));
}

//abstract class MathFunction extends Expression {
//  MathFunction(this.)
//}

/**
 * The exponential function.
 */
class Exponential extends UnaryOperator {

  /**
   * Creates a exponential operation on the given expressions.
   * 
   * For example, to create e^4:
   *     exp = new Exponential(4);
   * 
   * or:
   *     exp = new Exponential(new Number(4));
   */
  Exponential(exp): super(exp);
  Expression derive(String toVar) => new Times(this, exp.derive(toVar));
  String toString() => 'e^(${exp.toString()})';
}

/**
 * The logarithm function.
 */
class Log extends BinaryOperator {
  
  /**
   * Creates a logarithm function with given base and argument.
   * 
   * For example, to create log_10(2):
   *     log = new Log(10, 2);
   *     
   * To create a naturally based logarithm, see [Ln].
   */
  Log(base, arg): super(base, arg);
  
  Expression get base => first;
  Expression get arg => second;
  
  Expression derive(String toVar) => this.asNaturalLogarithm().derive(toVar);
  String toString() => 'log_${base.toString()}(${arg.toString()})';
  
  /**
   * Returns the natural from of this logarithm.
   * E.g. log_10(2) = ln(2) / ln(10)
   * 
   * This method is used to determine the derivation of a logarithmic
   * expression.
   */
  Expression asNaturalLogarithm() => new Ln(arg) / new Ln(base);
}

/**
 * The natural logarithm (log based e).
 */
class Ln extends Log {
  
  /**
   * Creates a natural logarithm function with given argument.
   * 
   * For example, to create ln(10):
   *     ln = new Ln(10);
   *     
   * To create a logarithm with arbitrary base, see [Log].
   */
  Ln(arg): super(Math.E, arg);
  
  Expression derive(String toVar) => arg.derive(toVar) / arg;
  String toString() => 'ln(${arg.toString()})';
}

/**
 * A literal can be a number, a constant or a variable.
 */
abstract class Literal extends Expression {
  var value;
  
  /**
   * Creates a literal with given value.
   */
  Literal([var this.value]);
  
  String toString() => value.toString();
  
  Expression simplify() => this; //TODO
}

/**
 * A Number is a number literal.
 */
class Number extends Literal {
    
  /**
   * Creates a number literal with given value.
   */
  Number(num value): super(value);
  
  num evaluate() => value; //TODO rename
  
  Expression derive(String toVar) => new Number(0);
}

/**
 * A Variable is a named literal.
 */
class Variable extends Literal {
  String name;
  
  /**
   * Creates a variable literal with given name.
   */
  Variable(String this.name);
  
  void bindTo(Expression binding) {
    this.value = binding;
  }
  
  //TODO how to evaluate?
  num evaluate() => value == null ? throw new ArgumentError('Variable ${value} is not bound.') : value.evaluate();
  
  Expression derive(String toVar) => name == toVar ? new Number(1) : new Number(0);
  
  String toString() => name;
}

/**
 * //TODO
 */
class Interval extends Literal {
  Interval(num min, num max) : super(new Alg.Interval(min, max)); //TODO this does not work
  
  num evaluate() => value; //TODO whis will break
  
  Expression derive(String toVar) => new Number(0); //TODO this is wrong
}

void main() {
  Expression x = new Variable('x'), a = new Variable('a'), b = new Variable('b'), c = new Variable('c');
  //Expression pow = new Power(x, new Number(2));
  //Expression e = a+b;
  //Expression e = a*pow+b*x+c;
  //Expression e = a*x*x+b*x+c;
  //print(e);
  //print(e.derive('x'));
  
  Expression exp = new Power('x', 2);
  Expression mul = new Times('x', 'x');
  Expression expD = exp.derive('x');
  
  print('exp: ${exp.toString()}');
  print('expD: ${expD.toString()}');
  print('mul: ${mul.toString()}');
  print('mulD: ${mul.derive('x').toString()}');
  
  Expression div = new Divide(exp, 'x');
  print('div: ${div.toString()}');
  print('divD: ${div.derive('x').toString()}');
  
  Expression log = new Log(10, exp);
  print('log: ${log.toString()}');
  print('logD: ${log.derive('x').toString()}');
  
  Expression expXY = x^a;
  print('expXY: ${expXY.toString()}');
  print('expXYD: ${expXY.derive('x').toString()}');
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