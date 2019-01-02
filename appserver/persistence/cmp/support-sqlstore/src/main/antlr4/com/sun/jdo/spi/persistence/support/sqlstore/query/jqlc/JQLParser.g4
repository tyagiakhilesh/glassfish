/**
 * This class defines the syntax analysis (parser) of the JQL compiler.
 *
 * @author  Michael Bouschen
 * @author  Akhilesh Tyagi
 * @version 1.0
 */
parser grammar JQLParser;


tokens
{
    // "imaginary" tokens, that have no corresponding real input

    QUERY,
    CLASS_DEF,
    IMPORT_DEF,
    PARAMETER_DEF,
    VARIABLE_DEF,
    ORDERING_DEF,
    FILTER_DEF,
    ARG_LIST,

    // operators
    UNARY_MINUS,
    UNARY_PLUS,
    TYPECAST,
    OBJECT_EQUAL,
    OBJECT_NOT_EQUAL,
    COLLECTION_EQUAL,
    COLLECTION_NOT_EQUAL,
    CONCAT,

    // special dot expressions
    FIELD_ACCESS,
    STATIC_FIELD_ACCESS,
    CONTAINS,
    NOT_CONTAINS,
    NAVIGATION,
    STARTS_WITH,
    ENDS_WITH,
    IS_EMPTY,

    // identifier types
    VARIABLE,
    PARAMETER,
    TYPENAME,

    // constant value
    VALUE,

    // result definition
    RESULT_DEF,

    // non-standard extensions (operators)
    LIKE,
    SUBSTRING,
    INDEXOF,
    LENGTH,
    ABS,
    SQRT,

    //
    NOT_IN
}

@parser::members {
    /**
     * I18N support
     */
    private final static ResourceBundle messages = I18NHelper.loadBundle(
            JQLParser.class);

    /** */
    protected static final int EOF_CHAR = 65535; // = (char) -1 = EOF

    /**
     *
     */
    protected ErrorMsg errorMsg;

    /**
     *
     */
    public void init(ErrorMsg errorMsg)
    {
        this.errorMsg = errorMsg;
    }

    /**
     * ANTLR method called when an error was detected.
     */
    public void reportError(RecognitionException ex)
    {
        JQLParser.handleANTLRException(ex, errorMsg);
    }

    /**
     * ANTLR method called when an error was detected.
     */
    public void reportError(String s)
    {
        errorMsg.error(0, 0, s);
    }

    /**
     *
     */
    public void reportError(int line, int column, String s)
    {
        errorMsg.error(line, column, s);
    }

    /**
     * ANTLR method called when a warning was detected.
     */
    public void reportWarning(String s)
    {
        throw new JDOQueryException(s);
    }

    /**
     *
     */
    public static void handleANTLRException(ANTLRException ex, ErrorMsg errorMsg)
    {
        if (ex instanceof MismatchedCharException)
        {
            MismatchedCharException mismatched = (MismatchedCharException)ex;
            if (mismatched.mismatchType == MismatchedCharException.CHAR)
            {
                if (mismatched.foundChar == EOF_CHAR)
                {
                    errorMsg.error(mismatched.getLine(), mismatched.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.unexpectedEOF")); //NOI18N
                }
                else
                {
                    errorMsg.error(mismatched.getLine(), mismatched.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.expectedfoundchar", //NOI18N
                            String.valueOf((char)mismatched.expecting),
                            String.valueOf((char)mismatched.foundChar)));
                }
                return;
            }
        }
        else if (ex instanceof MismatchedTokenException)
        {
            MismatchedTokenException mismatched = (MismatchedTokenException)ex;
            Token token = mismatched.token;
            if ((mismatched.mismatchType == MismatchedTokenException.TOKEN) &&
                (token != null))
            {
                if (token.getType() == Token.EOF_TYPE) {
                    errorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.unexpectedEOF")); //NOI18N
                }
                else {
                    errorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.syntaxerrorattoken", token.getText())); //NOI18N
                }
                return;
            }
        }
        else if (ex instanceof NoViableAltException)
        {
            Token token = ((NoViableAltException)ex).token;
            if (token != null)
            {
                if (token.getType() == Token.EOF_TYPE)
                {
                    errorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.unexpectedEOF")); //NOI18N
                }
                else
                {
                    errorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(messages, "jqlc.parser.unexpectedtoken", token.getText())); //NOI18N
                }
                return;
            }
        }
        else if (ex instanceof NoViableAltForCharException)
        {
            NoViableAltForCharException noViableAlt = (NoViableAltForCharException)ex;
            errorMsg.error(noViableAlt.getLine(), noViableAlt.getColumn(),
                I18NHelper.getMessage(messages, "jqlc.parser.unexpectedchar", //NOI18N
                    String.valueOf(noViableAlt.foundChar)));
        }
        else if (ex instanceof TokenStreamRecognitionException)
        {
            handleANTLRException(((TokenStreamRecognitionException)ex).recog, errorMsg);
        }

        // no special handling from aboves matches the exception if this line is reached =>
        // make it a syntax error
        int line = 0;
        int column = 0;
        if (ex instanceof RecognitionException)
        {
            line = ((RecognitionException)ex).getLine();
            column = ((RecognitionException)ex).getColumn();
        }
        errorMsg.error(line, column, I18NHelper.getMessage(messages, "jqlc.parser.syntaxerror")); //NOI18N
    }
}

// ----------------------------------
// rules: import declaration
// ----------------------------------

parseImports
{
    errorMsg.setContext("declareImports");  //NOI18N
}
    :   ( declareImport ( SEMI! declareImport )* )? ( SEMI! )? EOF!
    ;

declareImport
    :   i:IMPORT^ qualifiedName //NOI18N
        {
            #i.setType(IMPORT_DEF);
        }
    ;

// ----------------------------------
// rules: parameter declaration
// ----------------------------------

parseParameters
{
    errorMsg.setContext("declareParameters"); //NOI18N
}
    :   ( declareParameter ( COMMA! declareParameter )* )? ( COMMA! )? EOF!
    ;

declareParameter
    :   type IDENT
        { #declareParameter = #(#[PARAMETER_DEF,"parameterDef"], #declareParameter); } //NOI18N
    ;

// ----------------------------------
// rules: variables declaration
// ----------------------------------

parseVariables
{
    errorMsg.setContext("declareVariables");  //NOI18N
}
    :   ( declareVariable ( SEMI! declareVariable )* )? ( SEMI! )? EOF!
    ;

declareVariable
    :   type IDENT
        {  #declareVariable = #(#[VARIABLE_DEF,"variableDef"], #declareVariable); } //NOI18N
    ;

// ----------------------------------
// rules ordering specification
// ----------------------------------

parseOrdering
{
    errorMsg.setContext("setOrdering");  //NOI18N
}
    :   ( orderSpec ( COMMA! orderSpec )* )? ( COMMA! )? EOF!
    ;

orderSpec!
    :   e:expression d:direction
        { #orderSpec = #(#[ORDERING_DEF,"orderingDef"], #d, #e); } //NOI18N
    ;

direction
    :    ASCENDING
    |    DESCENDING
    ;

// ----------------------------------
// rules result expression
// ----------------------------------

parseResult
{
    errorMsg.setContext("setResult");  //NOI18N
}
    :   ( ( DISTINCT^ )? ( a:aggregateExpr | e:expression ) )? EOF!
        {
            // create RESULT_DEF node if there was a projection
            if (#a != null) {
                // skip a possible first distinct in case of an aggregate expr
                #parseResult = #(#[RESULT_DEF, "resultDef"], #a);
            }
            else if (#e != null) {
                #parseResult = #(#[RESULT_DEF,"resultDef"], #parseResult); //NOI18N
            }
        }
    ;

aggregateExpr
    :   ( AVG^ | MAX^ | MIN^ | SUM^ | COUNT^) LPAREN! distinctExpr RPAREN!
    ;

distinctExpr
    :   DISTINCT^ e:expression
    |   expression
    ;

// ----------------------------------
// rules filer expression
// ----------------------------------

parseFilter!
{
    errorMsg.setContext("setFilter");  //NOI18N
}
    :   e:expression EOF!
        {  #parseFilter = #(#[FILTER_DEF,"filterDef"], #e); } //NOI18N
    ;

// This is a list of expressions.
expressionList
    :   expression (COMMA! expression)*
    ;

expression
    :   conditionalOrExpression
    ;

// conditional or ||
conditionalOrExpression
    :   conditionalAndExpression (OR^ conditionalAndExpression)*
    ;

// conditional and &&
conditionalAndExpression
    :   inclusiveOrExpression (AND^ inclusiveOrExpression)*
    ;

// bitwise or logical or |
inclusiveOrExpression
    :   exclusiveOrExpression (BOR^ exclusiveOrExpression)*
    ;

// exclusive or ^
exclusiveOrExpression
    :   andExpression (BXOR^ andExpression)*
    ;

// bitwise or logical and &
andExpression
    :   equalityExpression (BAND^ equalityExpression)*
    ;

// equality/inequality ==/!=
equalityExpression
    :   relationalExpression ((NOT_EQUAL^ | EQUAL^) relationalExpression)*
    ;
// boolean relational expressions
relationalExpression
    :   additiveExpression
        (   (   LT^
            |   GT^
            |   LE^
            |   GE^
            )
            additiveExpression
        )*
    ;

// binary addition/subtraction
additiveExpression
    :   multiplicativeExpression ((PLUS^ | MINUS^) multiplicativeExpression)*
    ;
// multiplication/division/modulo
multiplicativeExpression
    :   unaryExpression ((STAR^ | DIV^ | MOD^ ) unaryExpression)*
    ;

unaryExpression
    :   MINUS^ {#MINUS.setType(UNARY_MINUS);} unaryExpression
    |   PLUS^  {#PLUS.setType(UNARY_PLUS);} unaryExpression
    |   unaryExpressionNotPlusMinus
    ;

unaryExpressionNotPlusMinus
    :   BNOT^ unaryExpression
    |   LNOT^ unaryExpression
    |   ( LPAREN type RPAREN unaryExpression )=>
          lp:LPAREN^ {#lp.setType(TYPECAST);} type RPAREN! unaryExpression
    |   postfixExpression
    ;

// qualified names, field access, method invocation
postfixExpression
    :   primary
        (   DOT^ IDENT ( argList )? )*
    ;

argList
    :   LPAREN!
        (   expressionList
            {#argList = #(#[ARG_LIST,"ARG_LIST"], #argList); } //NOI18N

        |   /* empty list */
            {#argList = #[ARG_LIST,"ARG_LIST"];} //NOI18N
        )
        RPAREN!
    ;

// the basic element of an expression
primary
    :   IDENT
    |   literal
    |   THIS
    |   LPAREN! expression RPAREN!
    ;

literal
    :   TRUE
    |   FALSE
    |   INT_LITERAL
    |   LONG_LITERAL
    |   FLOAT_LITERAL
    |   DOUBLE_LITERAL
    |   c:CHAR_LITERAL
        {
            // strip quotes from the token text
            String text = #c.getText();
            #c.setText(text.substring(1,text.length()-1));
        }
    |   s:STRING_LITERAL
        {
            // strip quotes from the token text
            String text = #s.getText();
            #s.setText(text.substring(1,text.length()-1));
        }
    |   NULL
    ;

qualifiedName
    :   IDENT ( DOT^ IDENT )*
    ;

type
    :   qualifiedName
    |   primitiveType
    ;

// The primitive types.
primitiveType
    :   BOOLEAN
    |   BYTE
    |   CHAR
    |   SHORT
    |   INT
    |   FLOAT
    |   LONG
    |   DOUBLE
    ;

