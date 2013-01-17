//import 'algebra.dart' as Alg show Interval;
import 'dart:math' as Math;

/**
 * Any Expression supports basic mathematical operations like
 * addition, subtraction, multiplication, division and power.
 * 
 * Furthermore, any expression can be differentiated with respect to
 * a given variable.
 * 
 * There are different classes of expressions:
 * 
 * * Literals (see [Literal])
 * 
 *     * Number Literals (see [Number])
 *     * Variable Literals (see [Variable])
 *     * Interval Literals (see [Interval])
 * * Operators (support auto-wrapping of parameters into Literals)
 * 
 *     * Unary Operators (see [UnaryOperator])
 *     * Binary Operators (see [BinaryOperator])
 * * Functions (see [MathFunction])
 * 
 * Default functions are [Exponential], [Log], [Ln], nth-[Root] and [Sqrt].
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
  
  /**
   * Returns a simplified version of this expression.
   * Subclasses should overwrite this method, if applicable.
   */
  Expression simplify() => this;
  
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
  
  /**
   * Returns true, if the given expression is a number literal and its value
   * matches the given value.
   */
  bool _isNumber(Expression exp, [num value = 0]) => exp is Number && (exp as Number).value == value;
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
   * 
   *  * A (positive) number will be encapsulated in a [Number] Literal,
   *  * A string will be encapsulated in a [Variable] Literal.
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
   * 
   * * A (positive) number will be encapsulated in a [Number] Literal,
   * * A string will be encapsulated in a [Variable] Literal.
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
  
  /**
   * Possible simplifications:
   * 1. -(-a) = a
   * 2. -0 = 0
   */
  Expression simplify() {
    Expression simplifiedOp = exp.simplify();
    
    // double minus
    if (simplifiedOp is UnaryMinus) {
      return simplifiedOp.exp;
    }
    
    // operand == 0
    if (_isNumber(simplifiedOp, 0)) {
        return simplifiedOp;
    }
    
    // nothing to do..
    return new UnaryMinus(simplifiedOp);
  }
  
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
  
  Expression derive(String toVar) => new Plus(first.derive(toVar),
                                              second.derive(toVar));
  
  /**
   * Possible simplifications:
   * 
   * 1. a + 0 = a
   * 2. 0 + a = a
   */
  Expression simplify() {
    Expression firstOp = first.simplify();
    Expression secondOp = second.simplify();
    
    if (_isNumber(firstOp, 0)) {
      return secondOp;
    }
    
    if (_isNumber(secondOp, 0)) {
      return firstOp;
    }
    
    return new Plus(firstOp, secondOp);
    
    //TODO -a + b = b - a 
    //TODO -a - b = - (a+b)
  }
  
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
  
  Expression derive(String toVar) => new Minus(first.derive(toVar),
                                               second.derive(toVar));
  
  /**
   * Possible simplifications:
   * 
   * 1. a - 0 = a
   * 2. 0 - a = a
   */
  Expression simplify() {
    Expression firstOp = first.simplify();
    Expression secondOp = second.simplify();
    
    if (_isNumber(firstOp, 0)) {
      return secondOp;
    }
    
    if (_isNumber(secondOp, 0)) {
      return firstOp;
    }
    
    return new Minus(firstOp, secondOp);
    
    //TODO -a + b = b - a
    //TODO -a - b = - (a + b)
  }
  
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

  Expression derive(String toVar) => new Plus(new Times(first, second.derive(toVar)),
                                              new Times(first.derive(toVar), second));
  
  /**
   * Possible simplifications:
   * 
   * 1. -a * b = - (a * b)
   * 2. a * -b = - (a * b)
   * 3. -a * -b = a * b
   * 4. a * 0 = 0
   * 5. 0 * a = 0
   * 6. a * 1 = a
   * 7. 1 * a = a
   */
  Expression simplify() {
    Expression firstOp = first.simplify();
    Expression secondOp = second.simplify();
    Expression tempResult;
    
    bool negative = false;
    if (firstOp is UnaryMinus) {
      firstOp = firstOp.exp;
      negative = !negative;
    }
    
    if (secondOp is UnaryMinus) {
      secondOp = secondOp.exp;
      negative = !negative;
    }
    
    if (_isNumber(firstOp, 0)) {
      return firstOp; // = 0
    }
    
    if (_isNumber(firstOp, 1)) {
      tempResult = secondOp;
    }
    
    if (_isNumber(secondOp, 0)) {
      return secondOp; // = 0
    }
    
    if (_isNumber(secondOp, 1)) {
      tempResult = firstOp;
    }
    
    // if temp result is not set, we return a multiplication
    if (tempResult == null) {
      return new Times(firstOp, secondOp);
    }
    
    // else we return the only constant and just check for sign before
    return negative ? new UnaryMinus(tempResult) : tempResult;
  }
  
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
  
  Expression derive(String toVar) => ((first.derive(toVar) * second)
                                    - (first * second.derive(toVar)))
                                    / (second * second);
  
  /**
   * Possible simplifications:
   * 
   * 1. -a / b = - (a / b)
   * 2. a * -b = - (a / b)
   * 3. -a / -b = a / b
   * 5. 0 / a = 0
   * 6. a / 1 = a
   * 
   * This method throws an error, if a divide by zero is encountered.
   */
  Expression simplify() {
    Expression firstOp = first.simplify();
    Expression secondOp = second.simplify();
    Expression tempResult;
    
    bool negative = false;
    
    if (firstOp is UnaryMinus) {
      firstOp = firstOp.exp;
      negative = !negative;
    }
    
    if (secondOp is UnaryMinus) {
      secondOp = secondOp.exp;
      negative = !negative;
    }
    
    if (_isNumber(firstOp, 0)) {
      return firstOp; // = 0
    }
    
    if (_isNumber(secondOp, 0)) {
      throw new ArgumentError('Divide by zero.');
    }
    
    if (_isNumber(secondOp, 1)) {
      tempResult = firstOp;
    } else {
      tempResult = new Divide(firstOp, secondOp);
    }
    
    return negative ? new UnaryMinus(tempResult) : tempResult;
    
    // TODO cancel down/out? - needs equals on literals!
  }
  
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
  
  /**
   * Possible simplifications:
   * 
   * 1. 0^x = 0
   * 2. 1^x = 1
   * 3. x^0 = 1
   * 4. x^1 = x
   */
  Expression simplify() {
    Expression baseOp = first.simplify();
    Expression exponentOp = second.simplify();
   
    //TODO unboxing
    /*
    bool baseNegative = false, expNegative = false;
    
    
    // unbox unary minuses
    if (baseOp is UnaryMinus) {
      baseOp = baseOp.exp;
      baseNegative = !baseNegative;
    }
    if (exponentOp is UnaryMinus) {
      exponentOp = exponentOp.exp;
      expNegative = !expNegative;
    }
    */
    
    if (_isNumber(baseOp, 0)) {
      return baseOp; // 0^x = 0
    }
    
    if (_isNumber(baseOp, 1)) {
      return baseOp; // 1^x = 1
    }
    
    if (_isNumber(exponentOp, 0)) {
      return new Number(1); // x^0 = 1
    }
    
    if (_isNumber(exponentOp, 1)) {
      return baseOp; // x^1 = x
    }
    
    return new Power(baseOp, exponentOp);
  }
  
  String toString() => '(${first.toString()}^${second.toString()})';
  
  /**
   * Returns the exponential form of this operation.
   * E.g. x^4 = e^(4x)
   * 
   * This method is used to determine the derivation of a power expression.
   */
  Expression asE() => new Exponential(second * new Ln(first));
}

/**
 * A function with an arbitrary number of arguments.
 * 
 * **Note:** Functions do not offer auto-wrapping of arguments into [Literal]s.
 */
abstract class MathFunction extends Expression {
  /// Name of this function.
  String name;
  
  /// List of arguments of this function.
  List<Expression> args;
  
  /**
   * Creates a new function with the given name and arguments.
   */
  MathFunction(this.name, this.args);
  
  /**
   * Creates a new unary function with one argument.
   */
  MathFunction.unary(this.name, Expression arg): this.args = [arg];
  
  /**
   * Creates a new binary function with two arguments.
   */
  MathFunction.binary(this.name, Expression arg1, Expression arg2): this.args = [arg1, arg2];
  
  /**
   * Returns the i-th parameter of this function.
   */
  Expression getParam(int i) => args[i];
}

/**
 * The exponential function.
 */
class Exponential extends MathFunction {

  /**
   * Creates a exponential operation on the given expressions.
   * 
   * For example, to create e^4:
   *     exp = new Exponential(new Number(4));
   */
  Exponential(exp): super.unary("exp", exp);
  
  /// The exponent of this exponential function.
  Expression get exp => getParam(0);
  
  Expression derive(String toVar) => new Times(this, exp.derive(toVar));
    
  String toString() => 'e^(${exp.toString()})';
}

/**
 * The logarithm function.
 */
class Log extends MathFunction {
  
  /**
   * Creates a logarithm function with given base and argument.
   * 
   * For example, to create log_10(2):
   *     base = new Number(10);
   *     arg = new Number(2);
   *     log = new Log(base, arg);
   *     
   * To create a naturally based logarithm, see [Ln].
   */
  Log(Expression base, Expression arg): super.binary("log", base, arg);
  
  /**
   * Creates a natural logarithm.
   * Must only be used internally by the Ln class.
   */
  Log._ln(arg): super.binary("ln", new Number(Math.E), arg);
  
  /// The base of this logarithm.
  Expression get base => getParam(0);
  
  /// The argument of this logarithm.
  Expression get arg => getParam(1);
  
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
   *     num10 = new Number(10);
   *     ln = new Ln(num10);
   *     
   * To create a logarithm with arbitrary base, see [Log].
   */
  Ln(Expression arg): super._ln(arg);
  
  Expression derive(String toVar) => arg.derive(toVar) / arg;
  
  String toString() => 'ln(${arg.toString()})';
}

/**
 * The n-th root function.
 */
class Root extends MathFunction {
  
  /// N-th root.
  int n;
  
  /**
   * Creates the n-th root of arg.
   * 
   * For example, to create the 5th root of x:
   *     root = new Root(5, new Variable('x'));
   */
  Root(int this.n, arg): super.unary('root', arg);
  
  /**
   * Creates the square root of arg.
   * 
   * For example, to create the square root of x:
   *     sqrt = new Root.sqrt(new Variable('x'));
   *     
   * Note: For better simplification and display, use the [Sqrt] class.
   */
  Root.sqrt(arg): super.unary('sqrt', arg), n = 2;
  
  Expression get arg => getParam(0);
  
  Expression derive(String toVar) => this.asPower().derive(toVar);
  
  String toString() => 'nrt_$n(${arg.toString()})';
  
  /**
   * Returns the power form of this root.
   * E.g. root_5(x) = x^(1/5)
   *    
   * This method is used to determine the derivation of a root
   * expression.
   */
  Expression asPower() => new Power(arg, new Divide(1,n));
}

/**
 * The square root function.
 */
class Sqrt extends Root {
  
  /**
   * Creates the square root of arg.
   * 
   * For example, to create the square root of x:
   *     sqrt = new Sqrt(new Variable('x'));
   */
  Sqrt(arg): super.sqrt(arg);

  String toString() => 'sqrt(${arg.toString()})';
  
  /**
   * Possible simplifications:
   * 
   * 1. sqrt(x^2) = x
   * 
   * Note: This simplification works _only_ for real numbers and 
   * _not_ for complex numbers.
   */
  Expression simplify() {
    Expression argSimpl = arg.simplify();
    
    if (argSimpl is Power) {
      Expression exponent = argSimpl.second;
      if (exponent is Number) {
        if (exponent.value == 2) {
          return argSimpl.first; // sqrt(x^2)
        }
      }
    }
    
    return new Sqrt(argSimpl);
  }
}

/**
 * A literal can be a number, a constant or a variable.
 */
abstract class Literal extends Expression {
  var value;
  
  /**
   * Creates a literal. The optional paramter `value` can be used to specify
   * its value.
   */
  Literal([var this.value]);
  
  String toString() => value.toString();
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
  //num evaluate() => value == null ? throw new ArgumentError('Variable ${value} is not bound.') : value.evaluate();
  
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