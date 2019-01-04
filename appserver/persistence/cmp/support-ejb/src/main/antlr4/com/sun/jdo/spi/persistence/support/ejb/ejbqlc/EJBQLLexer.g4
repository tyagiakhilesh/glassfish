/*
 * Copyright (c) 1997, 2019 Oracle and/or its affiliates. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0, which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the
 * Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
 * version 2 with the GNU Classpath Exception, which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 */

lexer grammar EJBQL;

@lexer::header
{
    import java.util.ResourceBundle;
    import org.glassfish.persistence.common.I18NHelper;
}

tokens {
    // literals
    LONG_LITERAL,
    FLOAT_LITERAL,
    DOUBLE_LITERAL,

    // lexer internal token types
    FLOAT_SUFFIX,
    UNICODE_DIGIT,
    UNICODE_STR
}

@lexer::members {
    /**
     * The width of a tab stop.
     * This value is used to calculate the correct column in a line
     * conatining a tab character.
     */
    protected static final int TABSIZE = 4;

    /** */
    protected static final int EOF_CHAR = 65535; // = (char) -1 = EOF

    /** I18N support. */
    protected final static ResourceBundle msgs =
        I18NHelper.loadBundle(EJBQLLexer.class);

    /**
     *
     */
    public void tab()
    {
        int column = getColumn();
        int newColumn = (((column-1)/TABSIZE)+1)*TABSIZE+1;
        setColumn(newColumn);
    }

    /** */
    public void reportError(int line, int column, String s)
    {
        ErrorMsg.error(line, column, s);
    }

    /** Report lexer exception errors caught in nextToken(). */
    public void reportError(RecognitionException e)
    {
        handleANTLRException(e);
    }

    /** Lexer error-reporting function. */
    public void reportError(String s)
    {
        ErrorMsg.error(0, 0, s);
    }

    /** Lexer warning-reporting function. */
    public void reportWarning(String s)
    {
        throw new EJBQLException(s);
    }

    /**
     *
     */
    public static void handleANTLRException(ANTLRException ex)
    {
        if (ex instanceof MismatchedCharException) {
            MismatchedCharException mismatched = (MismatchedCharException)ex;
            if (mismatched.mismatchType == MismatchedCharException.CHAR) {
                if (mismatched.foundChar == EOF_CHAR) {
                    ErrorMsg.error(mismatched.getLine(), mismatched.getColumn(),
                        //TBD: bundle key
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedEOF")); //NOI18N
                }
                else {
                    ErrorMsg.error(mismatched.getLine(), mismatched.getColumn(),
                        I18NHelper.getMessage(msgs, "EXC_ExpectedCharFound", //NOI18N
                            String.valueOf((char)mismatched.expecting),
                            String.valueOf((char)mismatched.foundChar)));
                }
                return;
            }
        }
        else if (ex instanceof MismatchedTokenException) {
            MismatchedTokenException mismatched = (MismatchedTokenException)ex;
            Token token = mismatched.token;
            if ((mismatched.mismatchType == MismatchedTokenException.TOKEN) &&
                (token != null)) {
                if (token.getType() == Token.EOF_TYPE) {
                    ErrorMsg.error(token.getLine(), token.getColumn(),
                        //TBD: bundle key
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedEOF")); //NOI18N
                }
                else {
                    ErrorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(msgs, "EXC_SyntaxErrorAt", token.getText())); //NOI18N
                }
                return;
            }
        }
        else if (ex instanceof NoViableAltException) {
            Token token = ((NoViableAltException)ex).token;
            if (token != null) {
                if (token.getType() == Token.EOF_TYPE) {
                    ErrorMsg.error(token.getLine(), token.getColumn(),
                        //TBD: bundle key
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedEOF")); //NOI18N
                }
                else {
                    ErrorMsg.error(token.getLine(), token.getColumn(),
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedToken", token.getText())); //NOI18N
                }
                return;
            }
        }
        else if (ex instanceof NoViableAltForCharException) {
            NoViableAltForCharException noViableAlt = (NoViableAltForCharException)ex;
            ErrorMsg.error(noViableAlt.getLine(), noViableAlt.getColumn(),
                I18NHelper.getMessage(msgs, "EXC_UnexpectedChar", new Character(noViableAlt.foundChar)));//NOI18N
        }
        else if (ex instanceof TokenStreamRecognitionException) {
            handleANTLRException(((TokenStreamRecognitionException)ex).recog);
        }

        // no special handling from aboves matches the exception if this line is reached =>
        // make it a syntax error
        int line = 0;
        int column = 0;
        if (ex instanceof RecognitionException) {
            line = ((RecognitionException)ex).getLine();
            column = ((RecognitionException)ex).getColumn();
        }
        ErrorMsg.error(line, column, I18NHelper.getMessage(msgs, "EXC_SyntaxError")); //NOI18N
    }
}

// keywords
SELECT : 'select'; //NOI18N
FROM : 'from'; //NOI18N
WHERE : 'where'; //NOI18N
DISTINCT : 'distinct'; //NOI18N
OBJECT : 'object'; //NOI18N
NULL : 'null'; //NOI18N
TRUE : 'true'; //NOI18N
FALSE : 'false'; //NOI18N
NOT : 'not'; //NOI18N
AND : 'and'; //NOI18N
OR : 'or'; //NOI18N
BETWEEN : 'between'; //NOI18N
LIKE : 'like'; //NOI18N
IN : 'in'; //NOI18N
AS : 'as'; //NOI18N
UNKNOWN : 'unknown'; //NOI18N
EMPTY : 'empty'; //NOI18N
MEMBER : 'member'; //NOI18N
OF : 'of'; //NOI18N
IS : 'is'; //NOI18N

// function/operator names treated as keywords
ESCAPE : 'escape'; //NOI18N
CONCAT : 'concat'; //NOI18N
SUBSTRING : 'substring'; //NOI18N
LOCATE : 'locate'; //NOI18N
LENGTH : 'length'; //NOI18N
ABS : 'abs'; //NOI18N
SQRT : 'sqrt'; //NOI18N
MOD : 'mod'; //NOI18N

// aggregate functions
AVG : 'avg'; //NOI18N
MAX : 'max'; //NOI18N
MIN : 'min'; //NOI18N
SUM : 'sum'; //NOI18N
COUNT : 'count'; //NOI18N

// order by
ORDER : 'order'; //NOI18N
BY : 'by'; //NOI18N
ASC : 'asc'; //NOI18N
DESC : 'desc'; //NOI18N

// OPERATORS

LPAREN          :   '('     ;
RPAREN          :   ')'     ;
COMMA           :   ','     ;
//DOT           :   '.'     ;
EQUAL           :   '='     ;
NOT_EQUAL       :   '<>'    ; //NOI18N
GE              :   '>='    ; //NOI18N
GT              :   '>'     ; //NOI18N
LE              :   '<='    ; //NOI18N
LT              :   '<'     ;
PLUS            :   '+'     ;
DIV             :   '/'     ;
MINUS           :   '-'     ;
STAR            :   '*'     ;

NEWLINE
    :   (   '\r\n'  //NOI18N
        |   '\r'
        |   '\n'
        )
        -> channel(HIDDEN)
    ;

// input parameter
INPUT_PARAMETER
    :  '?' ('1'..'9') ('0'..'9')*
    ;

// --------------
// Literal string
//
// ANTLR makes no distinction between a single character literal and a
// multi-character string. All literals are single quote delimited and
// may contain unicode escape sequences of the form \uxxxx, where x
// is a valid hexadecimal number (as per Java basically).
STRING_LITERAL
	:  '\'' (ESC_SEQ | ~['\\])* '\''
	;

// A valid hex digit specification
//
fragment
HEX_DIGIT
	:	[0-9a-fA-F]
	;

// Any kind of escaped character that we can embed within ANTLR
// literal strings.
//
fragment
ESC_SEQ
	:	'\\'
		(	// The standard escaped character set such as tab, newline, etc.
			[btnfr"'\\]

		|	// A Java style Unicode escape sequence
			UNICODE_ESC
		)
	;

fragment
UNICODE_ESC
    :   'u' (HEX_DIGIT (HEX_DIGIT (HEX_DIGIT HEX_DIGIT?)?)?)?
    ;

// ----------
// Whitespace
//
// Characters and character constructs that are of no import
// to the parser and are used to make the grammar easier to read
// for humans.
//
WS
	:	[ \t\r\n\f]+
		-> channel(HIDDEN)
	;

// a numeric literal
INT_LITERAL
    {
        boolean isDecimal=false;
        int tokenType = DOUBLE_LITERAL;
    }
    :   '.' {_ttype = DOT;}
            (('0'..'9')+ {tokenType = DOUBLE_LITERAL;}
             (EXPONENT)?
             (tokenType = FLOATINGPOINT_SUFFIX)?
            {_ttype = tokenType;} )?
    |   (   '0' {isDecimal = true;} // special case for just '0'
            (   ('x'|'X')
                (                                           // hex
                    // the 'e'|'E' and float suffix stuff look
                    // like hex digits, hence the (...)+ doesn't
                    // know when to stop: ambig.  ANTLR resolves
                    // it correctly by matching immediately.  It
                    // is therefor ok to hush warning.
                    options {
                        warnWhenFollowAmbig=false;
                    }
                :   HEX_DIGIT
                )+
            |   ('0'..'7')+                                 // octal
            )?
        |   ('1'..'9') ('0'..'9')*  {isDecimal=true;}       // non-zero decimal
        )
        (   ('l'|'L') { _ttype = LONG_LITERAL; }

        // only check to see if it's a float if looks like decimal so far
        |   {isDecimal}?
            {tokenType = DOUBLE_LITERAL;}
            (   '.' ('0'..'9')* (EXPONENT)?
                ( tokenType = FLOATINGPOINT_SUFFIX)?
            |   EXPONENT ( tokenType = FLOATINGPOINT_SUFFIX)?
            |   tokenType = FLOATINGPOINT_SUFFIX
            )
            { _ttype = tokenType; }
        )?
    ;

// a couple fragment methods to assist in matching floating point numbers
fragment
EXPONENT
    :   ('e'|'E') ('+'|'-')? ('0'..'9')+
    ;

fragment
FLOATINGPOINT_SUFFIX returns [int tokenType]
    : 'f' { tokenType = FLOAT_LITERAL; }
    | 'F' { tokenType = FLOAT_LITERAL; }
    | 'd' { tokenType = DOUBLE_LITERAL; }
    | 'D' { tokenType = DOUBLE_LITERAL; }
    ;

// an identifier.  Note that testLiterals is set to true!  This means
// that after we match the rule, we look in the literals table to see
// if it's a literal or really an identifer

IDENT
    options {paraphrase = "an identifier"; testLiterals=true;} //NOI18N
    :   (   'a'..'z'
        |   'A'..'Z'
        |   '_'
        |   '$'
        |   UNICODE_ESC
        |   c1:'\u0080'..'\uFFFE'
            {
                if (!Character.isJavaIdentifierStart(c1)) {
                    ErrorMsg.error(getLine(), getColumn(),
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedChar", String.valueOf(c1)));//NOI18N
                }
            }
        )
        (   'a'..'z'
        |   'A'..'Z'
        |   '_'
        |   '$'
        |   '0'..'9'
        |   UNICODE_ESC
        |   c2:'\u0080'..'\uFFFE'
            {
                if (!Character.isJavaIdentifierPart(c2)) {
                    ErrorMsg.error(getLine(), getColumn(),
                        I18NHelper.getMessage(msgs, "EXC_UnexpectedChar", String.valueOf(c2)));//NOI18N
                }
            }
        )*
    ;