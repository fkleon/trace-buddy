part of math_expressions;

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

  /**
   * Evaluates this expression according to given type and context.
   */
  evaluate(EvaluationType type, ContextModel context);

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

  evaluate(EvaluationType type, ContextModel context) {
    return -(exp.evaluate(type, context)); //TODO check if unary minus is supported with interval & vector
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


  evaluate(EvaluationType type, ContextModel context) {
    return first.evaluate(type, context) +  second.evaluate(type, context);
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


  evaluate(EvaluationType type, ContextModel context) {
    return first.evaluate(type, context) - second.evaluate(type, context);
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

  evaluate(EvaluationType type, ContextModel context) {
    // TODO check for case number *  vector -> scalar product with vector.scale()
    return first.evaluate(type, context) * second.evaluate(type, context);
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


  evaluate(EvaluationType type, ContextModel context) {
    var firstEval = first.evaluate(type, context);
    var secondEval = second.evaluate(type, context);

    if (secondEval == 0) throw new IntegerDivisionByZeroException(); //TODO: 0-vector, 0-interval

    return firstEval / secondEval;
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

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.REAL) {
      return Math.pow(first.evaluate(type, context), second.evaluate(type, context));
    }

    throw new UnimplementedError('Evaluate Power with type ${type} not supported yet.');
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

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.REAL) {
      return value;
    }

    if (type == EvaluationType.INTERVAL) {
      // interpret number as interval
      Interval intLit = new Interval.fromSingle(this);
      return intLit.evaluate(type, context);
    }

    throw new UnsupportedError('Number can not be interpreted as: ${type}');
  }

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

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.VECTOR) {
      EvaluationType elementType = EvaluationType.REAL;

      if (length == 1) {
        // Does not seem to be a vector, try to return REAL.
        return elements[0].evaluate(elementType, context);
      }

      // Interpret vector elements as REAL.
      if (length == 2) {
        return new vec2.raw(elements[0].evaluate(elementType, context),
                              elements[1].evaluate(elementType, context));
      }

      if (length == 3) {
        return new vec3.raw(elements[0].evaluate(elementType, context),
                              elements[1].evaluate(elementType, context),
                              elements[2].evaluate(elementType, context));
      }

      if (length == 4) {
        return new vec4.raw(elements[0].evaluate(elementType, context),
                              elements[1].evaluate(elementType, context),
                              elements[2].evaluate(elementType, context),
                              elements[3].evaluate(elementType, context));
      }

      if (length > 4) {
        throw new UnimplementedError("Vector of arbitrary length (> 4) are not supported yet.");
      }
    }

    if (type == EvaluationType.REAL && length == 1) {
      // Interpret vector as real number.
      return elements[0].evaluate(type, context);
    }

    throw new UnsupportedError('Vector with length ${length} can not be interpreted as: ${type}');
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

  evaluate(type, context) => context.getExpression(name).evaluate(type, context);
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

  //TODO getConstantValue on every expression -> recursion?
  num getConstantValue() => value.value;

  // Anonymous, bound variable, derive content and unbox.
  Expression derive(String toVar) => value.derive(toVar); //TODO Needs boxing?

  Expression simplify() => value.simplify(); //TODO Might need boxing in another variable? How to reassign anonymous variables to functions?

  evaluate(EvaluationType type, ContextModel context) => value.evaluate(type, context);

  String toString() => '{$value}';
}

/**
 * An interval literal.
 */
class Interval extends Literal {
  Expression min, max;

  /**
   * Creates a new interval with given borders.
   */
  Interval(Expression this.min, Expression this.max);

  /**
   * Creates a new interval with identical borders.
   */
  Interval.fromSingle(Expression exp): this.min = exp, this.max = exp;

  Expression derive(String toVar) {
    // Can not derive this yet..
    throw new UnimplementedError('Interval differentiation not supported yet.');
  }

  Expression simplify() {
    return new Interval(min.simplify(), max.simplify());
  }

  evaluate(EvaluationType type, ContextModel context) {
    if (type == EvaluationType.INTERVAL) {
      // Interval borders should evaluate to real numbers..
      num minEval = min.evaluate(EvaluationType.REAL, context);
      num maxEval = max.evaluate(EvaluationType.REAL, context);

      return new Algebra.Interval(minEval, maxEval);
    }

    throw new UnsupportedError('Interval can not be interpreted as: ${type}');
  }

  String toString() => 'I[$min, $max]';
  //TODO constant / getConstant
}