//import 'algebra.dart' as Alg show Interval;
import 'dart:math' as Math;

/**
 * Any Expression supports basic mathematical operations like
 * addition, subtraction, multiplication, division, power and negate.
 * 
 * Furthermore, any expression can be differentiated with respect to
 * a given variable. Also expressions know how to simplify themselves.
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
 *     * Pre-defined Functions (see [DefaultFunction])
 *     * Custom Functions (see [CustomFunction])
 * 
 * Pre-defined functions are [Exponential], [Log], [Ln], nth-[Root], [Sqrt],
 * [Sin] and [Cos].
 */
abstract class Expression {
  
  // Basic operations.
  Expression operator+(Expression exp) => new Plus(this, exp);
  Expression operator-(Expression exp) => new Minus(this, exp);
  Expression operator*(Expression exp) => new Times(this, exp);
  Expression operator/(Expression exp) => new Divide(this, exp);
  Expression operator^(Expression exp) => new Power(this, exp);
  Expression operator-() => new UnaryMinus(this);
  
  /**
   * Derives this expression with respect to the given variable.
   */
  Expression derive(String toVar);
  //TODO return simplified version on of derivation in each expression
  
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
   * Throws ArgumentError, if given arg is not an Expression, num oder String.
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
   * Returns true, if the given expression is a constant literal and its value
   * matches the given value.
   */
  bool _isNumber(Expression exp, [num value = 0]) {
    // Check for literal.
    if (exp is Literal && (exp as Literal).isConstant()) {
      return exp.getConstantValue() == value;
    }
    
    //TODO Remove this rubbish if we stick to BoundVariable
    /*
    // Check for number literal
    if (exp is Number) {
      return (exp as Number).value == value;
    }
    
    // Check for BoundVariable
    if (exp is BoundVariable) {
      return _isNumber(exp.value, value);
    }
    */
    
    return false;
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
   * 
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
   * This method throws an IntegerDivisionByZeroException,
   * if a divide by zero is encountered.
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
      throw new IntegerDivisionByZeroException();
    }
    
    if (_isNumber(secondOp, 1)) {
      tempResult = firstOp;
    } else {
      tempResult = new Divide(firstOp, secondOp);
    }
    
    return negative ? new UnaryMinus(tempResult) : tempResult;
    // TODO cancel down/out? - needs equals on literals (and expressions?)!
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
  /// Must be a variable.
  List<Variable> args;
  
  //TODO
  // isComplete() => all bound?
  
  /**
   * Creates a new function with the given name and arguments.
   */
  MathFunction(this.name, this.args);
  
  /**
   * Creates a new function with the given name.
   * 
   * __Note__:
   * Must only be used internally by subclasses, as it does not define any
   * arguments.
   */
  MathFunction._empty(this.name);
  
  /**
   * Creates a new composite function.
   * 
   * __Note__:
   * Must only be used internally for pre-defined functions, as it does not
   * contain any arguments or expression. The Evaluator needs to know how to
   * handle this.
   */
  MathFunction._composite(this.name, Expression arg1, Expression arg2): this.args = [arg1, arg2];
    
  /**
   * Returns the i-th parameter of this function.
   */
  Expression getParam(int i) => args[i];
  
  /// The dimension of the domain of definition of this function.
  int get domainDimension => args.length;
  
  String toString() => '$name($args)';
}

/**
 * A composition of two given [MathFunctions].
 */
class CompositeFunction extends MathFunction {
  /// Members `f` and `g` of the composite function.
  MathFunction f, g;
  
  /**
   * Creates a function composition.
   * 
   * For example, given `f(x): R -> R^3` and `g(x,y,z): R^3 -> R`
   * the composition yields `(g ° f)(x): R -> R^3 -> R`. First
   * `f` is applied, then `g` is applied.
   * 
   * Given some requirements
   *     x = new Variable('x');
   *     xPlus = new Plus(x, 1);
   *     xMinus = new Minus(x, 1);
   *     
   *     fExpr = new Vector([x, xPlus, xMinus]);        // Transforms x to 3-dimensional vector
   *     f = new CustomFunction('f', [x], fExpr);       // Creates a function R -> R^3 from fExpr
   *     
   *     y = new Variable('z');
   *     z = new Variable('y');
   *     
   *     gExpr = x + y + z;                             // Transforms 3-dimensional input to real value
   *     g = new CustomFunction('g', [x, y, z], gExpr)  // Creates a function R^3 -> R from gExpr
   *     
   * a composition can be created as follows:
   *     composite = new CompositeFunction(f, g); // R -> R
   *                                              // composite(2) = 6
   */
  CompositeFunction(MathFunction f, MathFunction g):
    super('comp(${f.name},${g.name})', f.args) {
    this.f = f;
    this.g = g;
  }
    
  /// The domain of the 'second' function, which should match the range
  /// of the 'first function.
  int get gDomainDimension => g.domainDimension;
  
  /// The domain of the 'first' function.
  int get domainDimension => f.domainDimension;
  
  Expression derive(String toVar) {
    MathFunction gDF;
    Expression gD = g.derive(toVar);
    
    if (!(gD is MathFunction)) {
    // Build function again..
      gDF = new CustomFunction('d${g.name}', g.args, gD);
    } else {
      gDF = (gD as MathFunction);
    }
    
    // Chain rule.
    return new CompositeFunction(f, gDF) * f.derive(toVar);
  }
  
  /**
   * Simplifies both component functions.
   */
  Expression simplify() {
    MathFunction fSimpl = f.simplify();
    MathFunction gSimpl = g.simplify();
    
    return new CompositeFunction(fSimpl, gSimpl);
  }
}

/**
 * Any user-created function is a CustomFunction.
 */
class CustomFunction extends MathFunction {
  /// Function expression of this function.
  /// Used for non-default or user-defined functions.
  Expression expression;
  
  /**
   * Create a custom function with the given name, argument variables,
   * and expression.
   */
  CustomFunction(String name, List<Variable> args, Expression this.expression): super(name, args);
  
  Expression derive(String toVar) => new CustomFunction(name, args, expression.derive(toVar));
  
  Expression simplify() => new CustomFunction(name, args, expression.simplify());
  
  //TODO einsetzen?
  //TODO ersetzen?
  
  String toFullString() => '$name($args) = ${expression.toString()}';
}

/**
 * A default function is predefined in this library.
 * It contains no expression, because the appropriate [Evaluator] knows
 * how to handle them.
 * 
 * __Note__:
 * User-defined custom functions should derive from [CustomFunction], which
 * supports arbitrary expressions.
 */
abstract class DefaultFunction extends MathFunction {

  /**
   * Creates a new unary function with given name and argument.
   * If the argument is not a variable, it will be wrapped into an anonymous
   * variable, which binds the given expression.
   * 
   * __Note__:
   * Must only be used internally for pre-defined functions, as it does not
   * contain any expression. The Evaluator needs to know how to handle this.
   */
  DefaultFunction._unary(String name, Expression arg) : super._empty(name) {
    Variable bindingVariable = _wrapIntoVariable(arg);
    this.args = [bindingVariable];
  }
  
  /**
   * Creates a new binary function with given name and two arguments.
   * If the arguments are not variables, they will be wrapped into anonymous
   * variables, which bind the given expressions.
   * 
   * __Note__:
   * Must only be used internally for pre-defined functions, as it does not
   * contain any expression. The Evaluator needs to know how to handle this.
   */
  DefaultFunction._binary(String name, Expression arg1, Expression arg2): super._empty(name) {
    Variable bindingVariable1 = _wrapIntoVariable(arg1);
    Variable bindingVariable2 = _wrapIntoVariable(arg2);
    this.args = [bindingVariable1, bindingVariable2];
  }
  
  /**
   * Returns a variable, bound to the given [Expression].
   * Returns the parameter itself, if it is already a variable.
   */
  Variable _wrapIntoVariable(Expression e) {
    if (e is Variable) {
      // Good to go..
      return e as Variable;
    } else {
      // Need to wrap..
     return new BoundVariable(e);
    }
  }
}

/**
 * The exponential function.
 */
class Exponential extends DefaultFunction {

  /**
   * Creates a exponential operation on the given expressions.
   * 
   * For example, to create e^4:
   *     four = new Number(4);
   *     exp = new Exponential(four);
   *     
   * You also can use variables or arbitrary expressions:
   *     x = new Variable('x');
   *     exp = new Exponential(x);
   *     exp = new Exponential(x + 4);
   */
  Exponential(exp): super._unary("exp", exp);
  
  /// The exponent of this exponential function.
  Expression get exp => getParam(0);
  
  Expression derive(String toVar) => new Times(this, exp.derive(toVar));
  
  /**
   * Possible simplifications:
   * 
   * 1. e^0 = 1
   * 2. e^1 = e
   * 3. e^(x*ln(y)) = y^x (usually easier to read for humans)
   */
  Expression simplify() {
    Expression expSimpl = exp.simplify();
    
    if (_isNumber(expSimpl,0)) {
      return new Number(1); // e^0 = 1
    }
    
    if (_isNumber(expSimpl,1)) {
      return new Number(Math.E); // e^1 = e
    }
    
    if (expSimpl is Times && (expSimpl as Times).second is Ln) {
     Ln ln = expSimpl.second;
     return new Power(ln.arg, expSimpl.first); // e^(x*ln(y)) = y^x
    }
    
    return new Exponential(expSimpl);
  }
  
  String toString() => 'e^(${exp.toString()})';
}

/**
 * The logarithm function.
 */
class Log extends DefaultFunction {
  
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
  Log(Expression base, Expression arg): super._binary("log", base, arg);
  
  /**
   * Creates a natural logarithm.
   * Must only be used internally by the Ln class.
   */
  Log._ln(arg): super._binary("ln", new Number(Math.E), arg);
  
  /// The base of this logarithm.
  Expression get base => getParam(0);
  
  /// The argument of this logarithm.
  Expression get arg => getParam(1);
  
  Expression derive(String toVar) => this.asNaturalLogarithm().derive(toVar);
    
  /**
   * Simplifies base and argument.
   */
  Expression simplify() {
    return new Log(base.simplify(), arg.simplify());
  }
  
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
  
  /**
   * Possible simplifications:
   * 
   * 1. ln(1) = 0
   */
  Expression simplify() {
    Expression argSimpl = arg.simplify();
    
    if (_isNumber(argSimpl, 1)) {
      return new Number(0); // ln(1) = 0
    }
    
    return new Ln(argSimpl);
  }
  
  String toString() => 'ln(${arg.toString()})';
}

/**
 * The n-th root function. n needs to be a natural number.
 */
class Root extends DefaultFunction {
  
  /// N-th root.
  int n;
  
  /**
   * Creates the n-th root of arg.
   * 
   * For example, to create the 5th root of x:
   *     root = new Root(5, new Variable('x'));
   */
  Root(int this.n, arg): super._unary('root', arg);
  
  /**
   * Creates the square root of arg.
   * 
   * For example, to create the square root of x:
   *     sqrt = new Root.sqrt(new Variable('x'));
   *     
   * Note: For better simplification and display, use the [Sqrt] class.
   */
  Root.sqrt(arg): super._unary('sqrt', arg), n = 2;
  
  Expression get arg => getParam(0);
  
  Expression derive(String toVar) => this.asPower().derive(toVar);
  
  /**
   * Simplify argument.
   */
  Expression simplify() {
    new Root(n, arg.simplify());
  }
  
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

  /**
   * Possible simplifications:
   * 
   * 1. sqrt(x^2) = x
   * 2. sqrt(0) = 0
   * 3. sqrt(1) = 1
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
          return argSimpl.first; // sqrt(x^2) = x
        }
      }
    }
    
    if (_isNumber(argSimpl, 0)) {
      return new Number(0); // sqrt(0) = 0
    }
    
    if (_isNumber(argSimpl, 1)) {
      return new Number(1); // sqrt(1) = 1
    }
    
    return new Sqrt(argSimpl);
  }
  
  String toString() => 'sqrt(${arg.toString()})';
}

//TODO sin, cos, etc.

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
  
  /**
   * Returns true, if this literal is a constant.
   */
  bool isConstant() => false;
  
  /**
   * Returns the constant value of this literal.
   * Throws StateError if literal is not constant, check before usage with
   * isConstant().
   */
  num getConstantValue() {
    throw new StateError('Literal ${this} is not constant.');
  }
  
  String toString() => value.toString();
}

/**
 * A number is a constant number literal.
 */
class Number extends Literal {
    
  /**
   * Creates a number literal with given value.
   */
  Number(num value): super(value);
  
  bool isConstant() => true;
  
  num getConstantValue() => value;
  
  Expression derive(String toVar) => new Number(0);
}

/**
 * A vector of arbitrary size.
 */
class Vector extends Literal {
  
  /**
   * Creates a vector with the given element expressions.
   * 
   * For example, to create a 3-dimensional vector:
   *     x = y = z = new Number(1);
   *     vec3 = new Vector([x, y, z]);
   */
  Vector(List<Expression> elements): super(elements);
  
  /// The elements of this vector.
  List<Expression> get elements => value;
  
  /// The length of this vector.
  int get length => elements.length;
  
  Expression derive(String toVar) {
    List<Expression> elementDerivatives = new List<Expression>(length);
    
    // Derive each element.
    for (int i = 0; i < length; i++) {
      elementDerivatives[i] = elements[i].derive(toVar);
    }
    
    return new Vector(elementDerivatives);
  }
  
  /**
   * Simplifies all elements of this vector.
   */
  Expression simplify() {
    List<Expression> simplifiedElements = new List<Expression>(length);
    
    // Simplify each element.
    for (int i = 0; i < length; i++) {
      simplifiedElements[i] = elements[i].simplify();
    }
    
    return new Vector(simplifiedElements);
  }
  
  //TODO isConstant / getConstantValue
}

/**
 * A variable is a named literal.
 */
class Variable extends Literal {
  String name;
    
  /**
   * Creates a variable literal with given name.
   */
  Variable(String this.name);
  
  Expression derive(String toVar) => name == toVar ? new Number(1) : new Number(0);
    
  String toString() => '$name';
}

/**
 * A bound variable is an anonymous variable, e.g. a variable without name,
 * which is bound to an expression.
 */
//TODO This is only used for DefaultFunctions, might as well use an expression
//      directly then and remove some complexity.. leaving this in use right now,
//      since it might be useful some time - maybe for composite functions? (FL)
class BoundVariable extends Variable {
  /**
   * Creates an anonymous variable which is bound to the given expression.
   */
  BoundVariable(Expression expr): super('anon') {
    this.value = expr;
  }
  
  //TODO check again
  //TODO isConstant on every expression -> recursion?
  bool isConstant() => value is Number ? true : false;
  
  //TODO getConstantValie on every expression -> recursion?
  num getConstantValue() => value.value;
  
  // Anonymous, bound variable, derive content and unbox.
  Expression derive(String toVar) => value.derive(toVar); //TODO Needs boxing?
  
  Expression simplify() => value.simplify(); //TODO Might need boxing in another variable? How to reassign anonymous variables to functions?
  
  String toString() => '{$value}';
}

/**
 * //TODO needs interval evaluator..
 */
class Interval extends Literal {
  Interval(num min, num max) : super(new Alg.Interval(min, max)); //TODO this does not work
  
  num evaluate() => value; //TODO whis will break
  
  Expression derive(String toVar) => new Number(0); //TODO this is wrong
  
  //TODO constant / getConstant
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

class Tokenizer {
  //TODO
}

class Parser {
  //TODO
}

class Evaluator {
  // TODO
}