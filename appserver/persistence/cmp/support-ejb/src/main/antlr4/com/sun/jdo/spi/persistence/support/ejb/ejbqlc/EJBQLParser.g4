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

/**
 * This class defines the syntax analysis (parser) of the EJBQL compiler.
 *
 * @author  Michael Bouschen
 */
parser grammar EJBQLParser;

options {
    k = 2;                   // two token lookahead
    exportVocab = EJBQL;
    buildAST = true;
    ASTLabelType = "EJBQLAST"; // NOI18N
}

tokens
{
    // root
    QUERY;

    // special from clause tokenes
    RANGE;

    // special dot expresssion
    CMP_FIELD_ACCESS;
    SINGLE_CMR_FIELD_ACCESS;
    COLLECTION_CMR_FIELD_ACCESS;

    // identifier 
    IDENTIFICATION_VAR;
    IDENTIFICATION_VAR_DECL;
    ABSTRACT_SCHEMA_NAME;
    CMP_FIELD;
    SINGLE_CMR_FIELD;
    COLLECTION_CMR_FIELD;

    // operators
    UNARY_MINUS;
    UNARY_PLUS;
    NOT_BETWEEN;
    NOT_LIKE;
    NOT_IN;
    NOT_NULL;
    NOT_EMPTY;
    NOT_MEMBER;
}

{
    /** I18N support. */
    protected final static ResourceBundle msgs = 
        I18NHelper.loadBundle(EJBQLParser.class);
    
    /** ANTLR method called when an error was detected. */
    public void reportError(RecognitionException ex)
    {
        EJBQLLexer.handleANTLRException(ex);
    }

    /** ANTLR method called when an error was detected. */
    public void reportError(String s)
    {
        ErrorMsg.error(0, 0, s);
    }

    /** */
    public void reportError(int line, int column, String s)
    {
        ErrorMsg.error(line, column, s);
    }

    /** ANTLR method called when a warning was detected. */
    public void reportWarning(String s)
    {
        throw new EJBQLException(s);
    }

    /** 
     * This method wraps the root rule in order to handle 
     * ANTLRExceptions thrown during parsing.
     */
    public void query ()
    {
        try {
            root();
        }
        catch (ANTLRException ex) {
            EJBQLLexer.handleANTLRException(ex);
        }
    }
}

// ----------------------------------
// rules
// ----------------------------------

root!
    :   s:selectClause f:fromClause w:whereClause o:orderbyClause EOF!
        {
            // switch the order of subnodes: the fromClause should come first, 
            // because it declares the identification variables used in the 
            // selectClause and the whereClause
            #root = #(#[QUERY,"QUERY"], #f, #s, #w); //NOI18N
            if (#o != null) {
                #root.addChild(#o);
            }
        }
    ;

selectClause
    :   SELECT^ ( DISTINCT )? projection
    ;

projection
    :   p:pathExpr
        {
            if (#p.getType() != DOT) {
                ErrorMsg.error(#p.getLine(), #p.getColumn(), 
                    I18NHelper.getMessage(msgs, "EXC_SyntaxErrorAt", //NOI18N
                        #p.getText())); 
            }
        }
    |   OBJECT^ LPAREN! IDENT RPAREN!
    |   ( AVG^ | MAX^ | MIN^ | SUM^ | COUNT^ ) LPAREN! (DISTINCT)? pathExpr RPAREN!
    ;

fromClause
    :   FROM^ identificationVarDecl ( COMMA! identificationVarDecl )*
    ;

identificationVarDecl
    :   collectionMemberDecl
    |   rangeVarDecl
    ;

collectionMemberDecl
    :   IN^ LPAREN! pathExpr RPAREN! ( AS! )? IDENT
    ;

rangeVarDecl!
    :   abstractSchemaName:. ( AS! )? i:IDENT
        {
            #abstractSchemaName.setType(ABSTRACT_SCHEMA_NAME);
            #rangeVarDecl = #(#[RANGE,"RANGE"], #abstractSchemaName, #i); //NOI18N
        }
    ;

whereClause
    :   WHERE^ conditionalExpr
    |   // empty rule
        {
            // Add where true in the case the where clause is omitted
            #whereClause = #(#[WHERE,"WHERE"], #[TRUE,"TRUE"]); //NOI18N
        }
    ;

pathExpr
    :   IDENT ( DOT^ IDENT )*
    ;

conditionalExpr
    :   conditionalTerm ( OR^ conditionalTerm )*
    ;

conditionalTerm
    :   conditionalFactor ( AND^ conditionalFactor )*
    ;

conditionalFactor
    :   ( NOT^ )? conditionalPrimary
    ;

conditionalPrimary
    :   ( betweenExpr )=> betweenExpr
    |   ( likeExpr )=> likeExpr
    |   ( inExpr )=> inExpr
    |   ( nullComparisonExpr )=> nullComparisonExpr
    |   ( emptyCollectionComparisonExpr )=> emptyCollectionComparisonExpr
    |   ( collectionMemberExpr )=> collectionMemberExpr 
    |   comparisonExpr
    ;

betweenExpr
    :   arithmeticExpr ( n:NOT! )? BETWEEN^ arithmeticExpr AND! arithmeticExpr
        {
            // map NOT BETWEEN to single operator NOT_BETWEEN
            if (#n != null)
                #BETWEEN.setType(NOT_BETWEEN);
        }
    ;

likeExpr
    :   pathExpr ( n:NOT! )? LIKE^ ( stringLiteral | parameter ) escape
        {
            // map NOT LIKE to single operator NOT_LIKE
            if(#n != null)
                #LIKE.setType(NOT_LIKE);
        }
    ;

escape
    :   ESCAPE^ ( stringLiteral | parameter )
    |   // empty rule
    ;

inExpr
    :   pathExpr ( n:NOT! )? IN^ LPAREN! inCollectionElement ( COMMA! inCollectionElement )* RPAREN!
        {
            // map NOT BETWEEN to single operator NOT_IN
            if (#n != null)
                #IN.setType(NOT_IN);
        }
    ;

nullComparisonExpr
    :   ( pathExpr | parameter ) IS! ( n:NOT! )? NULL^
        {
            // map NOT NULL to single operator NOT_NULL
            if (#n != null)
                #NULL.setType(NOT_NULL);
        }
    ;

emptyCollectionComparisonExpr
    :   pathExpr IS! ( n:NOT! )? EMPTY^
        {
            // map IS NOT EMPTY to single operator NOT_EMPTY
            if (#n != null)
                #EMPTY.setType(NOT_EMPTY);
        }
    ;

collectionMemberExpr
    :   ( pathExpr | parameter ) 
        ( n:NOT! )? MEMBER^ ( OF! )? pathExpr
        {
            // map NOT MEMBER to single operator NOT_MEMBER
            if (#n != null)
                #MEMBER.setType(NOT_MEMBER);
        }
    ;

comparisonExpr
    :   arithmeticExpr ( ( EQUAL^ | NOT_EQUAL^ | LT^ | LE^ | GT^ | GE^ ) arithmeticExpr )*
    ;

arithmeticExpr
    :   arithmeticTerm ( ( PLUS^ | MINUS^ ) arithmeticTerm )*
    ;

arithmeticTerm 
    :   arithmeticFactor ( (STAR^ | DIV^ ) arithmeticFactor )*
    ;

arithmeticFactor
    :   MINUS^ {#MINUS.setType(UNARY_MINUS);} arithmeticFactor
    |   PLUS^  {#PLUS.setType(UNARY_PLUS);} arithmeticFactor
    |   arithmeticPrimary
    ;

arithmeticPrimary
    :   pathExpr 
    |   literal
    |   LPAREN! conditionalExpr RPAREN!
    |   parameter
    |   function
    ;

function
    :   CONCAT^ LPAREN! conditionalExpr COMMA! conditionalExpr RPAREN!
    |   SUBSTRING^ LPAREN! conditionalExpr COMMA! conditionalExpr COMMA! conditionalExpr RPAREN!
    |   LENGTH^ LPAREN! conditionalExpr RPAREN!
    |   LOCATE^ LPAREN! conditionalExpr COMMA! conditionalExpr ( COMMA! conditionalExpr )? RPAREN!
    |   ABS^ LPAREN! conditionalExpr RPAREN! 
    |   SQRT^ LPAREN! conditionalExpr RPAREN!
    |   MOD^ LPAREN! conditionalExpr COMMA! conditionalExpr RPAREN!
    ;

parameter
    :   INPUT_PARAMETER
    ;

orderbyClause
    :   ORDER^ BY! orderbyItem ( COMMA! orderbyItem )*
    |   // empty rule
    ;

orderbyItem
    :   pathExpr direction
    ;

direction
    :   ASC
    |   DESC
    |   // empty rule
        {
            // ASC is added as default
            #direction = #[ASC, "ASC"]; //NOI18N
        }
    ;

inCollectionElement
    :   literal
    |   parameter
    ;

literal
    :   TRUE
    |   FALSE
    |   stringLiteral
    |   INT_LITERAL
    |   LONG_LITERAL
    |   FLOAT_LITERAL
    |   DOUBLE_LITERAL
    ;

stringLiteral
    :   s:STRING_LITERAL
        {
            // strip quotes from the token text
            String text = #s.getText();
            #s.setText(text.substring(1,text.length()-1));
        }
    ;
