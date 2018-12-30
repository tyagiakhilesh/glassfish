/*
 * Copyright (c) 1997, 2018 Oracle and/or its affiliates. All rights reserved.
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

/**
 * This class defines the lexical analysis for the JQL compiler.
 *
 * @author  Michael Bouschen
 * @author  Shing Wai Chan
 * @author  Akhilesh Tyagi
 * @version 1.0
 */

lexer grammar JQLLexer;

@lexer::header
{
    package com.sun.jdo.spi.persistence.support.sqlstore.query.jqlc;

    import antlr.MismatchedTokenException;
    import antlr.MismatchedCharException;
    import antlr.NoViableAltException;
    import antlr.NoViableAltForCharException;
    import antlr.TokenStreamRecognitionException;

    import java.util.Locale;
    import java.util.ResourceBundle;
    import com.sun.jdo.api.persistence.support.JDOQueryException;
    import com.sun.jdo.api.persistence.support.JDOFatalInternalException;
    import org.glassfish.persistence.common.I18NHelper;

}

@lexer::members {
    /**
     * I18N support
     */
    private final static ResourceBundle messages = I18NHelper.loadBundle(
            JQLLexer.class);

    /**
     *
     */
    protected ErrorMsg errorMsg;

    /**
     * The width of a tab stop.
     * This value is used to calculate the correct column in a line
     * conatining a tab character.
     */
    protected static final int TABSIZE = 4;

    /**
     *
     */
    public void init(ErrorMsg errorMsg)
    {
        this.errorMsg = errorMsg;
    }

    /**
     *
     */
    public void tab()
    {
        int column = getColumn();
        int newColumn = (((column-1)/TABSIZE)+1)*TABSIZE+1;
        setColumn(newColumn);
    }

    /**
     *
     */
    public void reportError(int line, int column, String s)
    {
        errorMsg.error(line, column, s);
    }

    /**
     * Report lexer exception errors caught in nextToken()
     */
    public void reportError(RecognitionException e)
    {
        JQLParser.handleANTLRException(e, errorMsg);
    }

    /**
     * Lexer error-reporting function
     */
    public void reportError(String s)
    {
        errorMsg.error(0, 0, s);
    }

    /**
     * Lexer warning-reporting function
     */
    public void reportWarning(String s)
    {
        throw new JDOQueryException(s);
    }
}

IMPORT          :   'import'; //NOI18N
THIS            :   'this'; //NOI18N
ASCENDING       :   'ascending'; //NOI18N
DESCENDING      :   'descending'; //NOI18N
// non-standard extensions
DISTINCT        :   'distinct'; //NOI18N
// types
BOOLEAN         :   'boolean'; //NOI18N
BYTE            :   'byte'; //NOI18N
CHAR            :   'char'; //NOI18N
SHORT           :   'short'; //NOI18N
INT             :   'int'; //NOI18N
FLOAT           :   'float'; //NOI18N
LONG            :   'long'; //NOI18N
DOUBLE          :   'double'; //NOI18N
// literals
NULL            :   'null'; //NOI18N
TRUE            :   'true'; //NOI18N
FALSE           :   'false'; //NOI18N
// aggregate functions
AVG             :   'avg'; //NOI18N
MAX             :   'max'; //NOI18N
MIN             :   'min'; //NOI18N
SUM             :   'sum'; //NOI18N
COUNT           :   'count'; //NOI18N
// OPERATORS
LPAREN          :   '('     ;
RPAREN          :   ')'     ;
COMMA           :   ','     ;
//DOT           :   '.'     ;
EQUAL           :   '=='    ; //NOI18N
LNOT            :   '!'     ;
BNOT            :   '~'     ;
NOT_EQUAL       :   '!='    ; //NOI18N
DIV             :   '/'     ;
PLUS            :   '+'     ;
MINUS           :   '-'     ;
STAR            :   '*'     ;
MOD             :   '%'     ;
GE              :   '>='    ; //NOI18N
GT              :   '>'     ; //NOI18N
LE              :   '<='    ; //NOI18N
LT              :   '<'     ;
BXOR            :   '^'     ;
BOR             :   '|'     ;
OR              :   '||'    ; //NOI18N
BAND            :   '&'     ;
AND             :   '&&'    ; //NOI18N
SEMI            :   ';'     ;

// Whitespace -- ignored
WS
    :   (   ' '
        |   '\t'
        |   '\f'
        )
        { _ttype = Token.SKIP; }
    ;

NEWLINE
    :   (   '\r\n'  //NOI18N
        |   '\r'
        |   '\n'
        )
        {
            newline();
            _ttype = Token.SKIP;
        }
    ;

// character literals
CHAR_LITERAL
    :   '\'' ( ESC | ~'\'' ) '\''
    ;

// string literals
STRING_LITERAL
    :  '"' ( ESC | ~'"')* '"' //NOI18N
    ;

// escape sequence -- note that this is fragment; it can only be called
//   from another lexer rule -- it will not ever directly return a token to
//   the parser
// There are various ambiguities hushed in this rule.  The optional
// '0'...'9' digit matches should be matched here rather than letting
// them go back to STRING_LITERAL to be matched.  ANTLR does the
// right thing by matching immediately; hence, it's ok to shut off
// the FOLLOW ambig warnings.
fragment
ESC
    :   '\\'
        (   'n'
        |   'r'
        |   't'
        |   'b'
        |   'f'
        |   '"' //NOI18N
        |   '\''
        |   '\\'
        |   ('u')+ HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
        |   ('0'..'3')(('0'..'7')('0'..'7')?)?
        |   ('4'..'7')
            (('0'..'9'))?
        )?
    ;

// hexadecimal digit (again, note it's fragment!)
fragment
HEX_DIGIT
    :   ('0'..'9'|'A'..'F'|'a'..'f')
    ;


// a numeric literal
INT_LITERAL
    :
    {
        boolean isDecimal=false;
        int tokenType = DOUBLE_LITERAL;
    }
    '.' {_ttype = DOT;}
            (('0'..'9')+ {tokenType = DOUBLE_LITERAL;}
             (EXPONENT)?
             (tokenType = FLOATINGPOINT_SUFFIX)?
            { _ttype = tokenType; })?
    |   (   '0' {isDecimal = true;} // special case for just '0'
            (   ('x'|'X')
                (HEX_DIGIT)+
            |   ('0'..'7')+                                 // octal
            )?
        |   ('1'..'9') ('0'..'9')*  {isDecimal=true;}       // non-zero decimal
        )
        (   ('l'|'L') { _ttype = LONG_LITERAL; }

        // only check to see if it's a float if looks like decimal so far
        |   {isDecimal}?
            {tokenType = DOUBLE_LITERAL;}
            (   '.' ('0'..'9')* (EXPONENT)?
                (tokenType = FLOATINGPOINT_SUFFIX)?
            |   EXPONENT (tokenType = FLOATINGPOINT_SUFFIX)?
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
FLOATINGPOINT_SUFFIX
    : 'f'
    | 'F'
    | 'd'
    | 'D'
    ;

// an identifier.  Note that testLiterals is set to true!  This means
// that after we match the rule, we look in the literals table to see
// if it's a literal or really an identifer

IDENT
    //options {paraphrase = 'an identifier'; testLiterals=true;} //NOI18N
    :   (   'a'..'z'
        |   'A'..'Z'
        |   '_'
        |   '$'
        |   UNICODE_ESCAPE
        |   c1='\u0080'..'\uFFFE'
            {
                if (!Character.isJavaIdentifierStart(c1)) {
                    errorMsg.error(getLine(), getColumn(),
                        I18NHelper.getMessage(messages, 'jqlc.parser.unexpectedchar', //NOI18N
                            String.valueOf(c1)));
                }
            }
        )
        (   'a'..'z'
        |   'A'..'Z'
        |   '_'
        |   '$'
        |   '0'..'9'
        |   UNICODE_ESCAPE
        |   c2='\u0080'..'\uFFFE'
            {
                if (!Character.isJavaIdentifierPart(c2)) {
                    errorMsg.error(getLine(), getColumn(),
                        I18NHelper.getMessage(messages, 'jqlc.parser.unexpectedchar', //NOI18N
                        String.valueOf(c2)));
                }
            }
        )*
    ;

fragment
UNICODE_ESCAPE
    : '\\' ('u')+ HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
        {
            try {
                String tmp = text.toString();
                char c  = (char)Integer.parseInt(tmp.substring(tmp.length() - 4, tmp.length()), 16);
                text.setLength(_begin);
                text.append(new Character(c).toString());
            }
            catch (NumberFormatException ex) {
                throw new JDOFatalInternalException(I18NHelper.getMessage(messages, 'jqlc.parser.invalidunicodestr'), ex); //NOI18N
            }
        }
    ;
