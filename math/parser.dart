part of math_expressions;

class Parser {
  Lexer lex;
  List<Token> inputStream;
  List<Expression> expressionStack;
  Parser(){
    lex = new Lexer();
  }
}

class Lexer{
  var keywords = new Map<String, TokenType>();
  List<Token> tokenStream;
  String intBuffer ="";
  String varBuffer ="";
  Lexer(){
    keywords["+"]= TokenType.PLUS;
    keywords["-"]= TokenType.MINUS;
    keywords["*"]= TokenType.TIMES;
    keywords["/"]= TokenType.DIV;
    keywords["^"]= TokenType.POW;
    keywords["sqrt"]= TokenType.SQRT;
    keywords["log"]= TokenType.LOG;
    keywords["ln"]= TokenType.LN;
    keywords["e"]= TokenType.EFUNC;
    keywords["("]= TokenType.LBRACE;
    keywords[")"]= TokenType.RBRACE;
    tokenStream = new List<Token>();
  }

  /**
   * creates a list of tokens from the given string
   */
    void createTokenStream(String inputString){

    String clearedString = inputString.replaceAll(" ", "");
    List<String> stringlist = clearedString.splitChars();
    int siInt;
    for (var i=0; i< stringlist.length;i++){
      String si = stringlist[i];
      print("Run: $i , si: $si");
      /* check if the current Character is a keyword. If it is a keyword, check if the intBuffer is not empty and add
       * a Value Token for the intBuffer and the corresponding Token for the keyword.
     */
      if(keywords.containsKey(si)){
        // check and or do intBuffer and varBuffer
        if(intBuffer.length >0)doIntBuffer();
        if(varBuffer.length >0)doVarBuffer();
        tokenStream.add(new Token(si,keywords[si]));
      }else{
      // check if the current string is a Number. If it's the case add the string to the intBuffer
     try {
       siInt = int.parse(si);
       // the current string is a number and it is added to the intBuffer
       intBuffer = intBuffer.concat(si);
       if(varBuffer.length >0)doVarBuffer();
       print("was in int case");
     } on FormatException {
       // the current string is not a number and not a simple keyword, so it has to be a variable or log or ln
      if(intBuffer.length >0) {
        /* the intBuffer contains a string and the current string is a variable or part of a complex keyword, so the value is added to the tokenstream
         * and the current string is added to the var buffer
         */
        doIntBuffer();
        varBuffer = varBuffer.concat(si);
        //reset the intBuffer
        intBuffer ="";
        print("was in text and do int case");
      } else {
        // the intBuffer contains no string and the current string is a variable, so both Tokens are added to the tokenStream
        print("was in text case");
        varBuffer = varBuffer.concat(si);
         }
       }
     }
   }
    if(intBuffer.length >0) {
      // the intBuffer contains a string and the current string is a variable, so both Tokens are added to the tokenStream
      doIntBuffer();
      intBuffer ="";
    }
  }

    void doIntBuffer(){
      tokenStream.add(new Token(intBuffer,TokenType.VAL));
      intBuffer = "";
    }

    void doVarBuffer(){
      if(keywords.containsKey(varBuffer)){
        tokenStream.add(new Token(varBuffer,keywords[varBuffer]));
      }else{
        tokenStream.add(new Token(varBuffer,TokenType.VAR));
      }
      varBuffer = "";
    }

  List<Token> shuntingYard(){
    if(tokenStream.isEmpty) throw new Exception("tokenStream was empty you frickin moron");
    List<Token> outputStream = new List<Token>();
    List<Token> operatorBuffer = new List<Token>();

    for(int i=0;i<tokenStream.length;i++){
      Token tempToken = tokenStream[i];

      //if the current Token is a value or a variable, put them into the outputstream
      if(tempToken.type == TokenType.VAL || tempToken.type == TokenType.VAR){
        outputStream.add(tempToken);
        continue;
      }

      //if the current Token is a left brace, put it on the operator buffer
      if(tempToken.type == TokenType.LBRACE){
        operatorBuffer.add(tempToken);
        continue;
      }

      //if the current Token is a right brace, empty the operator buffer until you find a left brace
      if(tempToken.type == TokenType.RBRACE ){
        while(operatorBuffer.last.type != TokenType.LBRACE){
          outputStream.add(operatorBuffer.last);
          operatorBuffer.removeLast();
        }
        operatorBuffer.removeLast();
        continue;
      }

      if(operatorBuffer.isEmpty){
        operatorBuffer.add(tempToken);
        continue;
      }

      /* if the current Tokens type is MINUS and the last Token in the operator buffer is of type LBRACE
       * the current Token is an unary minus, so the tokentype has to be changed
       */
      if(tempToken.type == TokenType.MINUS && operatorBuffer.last.type == TokenType.LBRACE){
        Token newToken = new Token(tempToken.text, TokenType.UNMINUS);
        operatorBuffer.add(newToken);
        continue;
      }
      /* if the current token is an operator and it's priority is lower than the priority of the last
       * operator in the operator buffer, than put the operators from the operator buffer into the output
       * stream until you find an operator with a priority lower or equal as the current tokens.
       * Then add the current Token to the operator buffer
       */
      if(tempToken.type.priority < operatorBuffer.last.type.priority){
        while(operatorBuffer.length>0 && operatorBuffer.last.type.priority > tempToken.type.priority){
          outputStream.add(operatorBuffer.last);
          operatorBuffer.removeLast();
        }
        operatorBuffer.add(tempToken);
        continue;
      }else{
        operatorBuffer.add(tempToken);
        continue;
      }
    }

    while(!operatorBuffer.isEmpty){
      outputStream.add(operatorBuffer.last);
      operatorBuffer.removeLast();
    }

    return outputStream;
  }
}

class Token{
  //TODO
  final String text;
  final TokenType type;

  Token(String this.text, TokenType this.type){
  }

  String toString(){
    return "( $type , $text )";
  }

}

class TokenType{
  static final TokenType VAR = const TokenType("VAR",10);
  static final TokenType VAL = const TokenType("VAL",10);
  //Braces
  static final TokenType LBRACE = const TokenType("LBRACE",-1);
  static final TokenType RBRACE = const TokenType("RBRACE",-1);
  //Simple Operators
  static final TokenType PLUS = const TokenType("PLUS",1);
  static final TokenType MINUS = const TokenType("MINUS",1);
  static final TokenType UNMINUS = const TokenType("UNMINUS",1);
  static final TokenType TIMES = const TokenType("TIMES",2);
  static final TokenType DIV = const TokenType("DIV",2);
  //Complex Operators
  static final TokenType POW = const TokenType("POW",3);
  static final TokenType SQRT = const TokenType("SQRT",3);
  static final TokenType LOG = const TokenType("LOG",3);
  static final TokenType LN = const TokenType("LN",3);
  static final TokenType EFUNC = const TokenType("EFUNC",3);


  final String value;
  final int priority;
  const TokenType(String this.value, int this.priority);

  String toString(){
    return value;
  }
}

