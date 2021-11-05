parser grammar RtmParser;

options {
	tokenVocab = RtmLexer;
}

start:
	SOURCE_TYPE SOURCE_DESC? (overlay | name_definition)* (
		source_end
		| EOF
	);

overlay: overlay_name declarations prog (proc | name_include)*;

source_end: DOLLAR_END;

//TODO: allow @ ?
name_definition: DOLLAR_NAME (name_body | name_terminator);
name_body: IDENTIFIER (data_field* | proc* | statement*);
name_terminator: ELLIPSIS DOT*;
name_include:
	DOLLAR_INCLUDE (STAR | IDENTIFIER) (LB IDENTIFIER RB)?;

overlay_name: DOLLAR_ENTRY IDENTIFIER;

declarations: files? (data | data_shared)? data_ext? ext?;

files: DOLLAR_FILES IDENTIFIER*;

data: DOLLAR_DATA (data_field | name_include)*;
data_shared: DOLLAR_DATA_SHARED (data_field | name_include)*;
data_ext: DOLLAR_EXTDATA (data_field | name_include)*;
data_field: (
		(((FILL | IDENTIFIER) EQUAL)? IDENTIFIER | FILL) edit_mask
	)
	| FIELD_IDENTIFIER;
edit_mask: (
		CHAR_MASK
		| NUMERIC_MASK
		| DATA_MASK
		| FIELD_MASK
		| code_string_mask
		| group_mask
	) (STAR NUMERIC_LITERAL)? group_prefix?;
group_prefix: PREFIX IDENTIFIER;
group_mask: LSB (data_field COMMA?)+ RSB;
code_string_mask:
	CODE_STRING_START CODE_STRING_VALUE+ CODE_STRING_END;

ext: DOLLAR_EXT IDENTIFIER*;

parameter_list: assignable (COMMA assignable)*;
call_parameter_list:
	LB (argument (COMMA argument)*)? (
		COLON call_return_parameter (COMMA call_return_parameter)*
	)? RB;
call_return_parameter: assignable | IGNORED_RETURN | STAR;
argument: (AT? (IDENTIFIER | keyword) EQUAL)? (
		expression
		| keyword
	);
return_statement_list: LB (expression (',' expression)*)? RB;

prog: DOLLAR_PROG LB parameter_list? RB statement* prog_end;
prog_end: return | QUITZUG;

proc: IDENTIFIER PROC LB parameter_list? RB statement* ENDPROC;

statement:
	expression
	| do_block
	| while_statement
	| return
	| SEMI_COLON
	| name_include
	| keyword //todo refine this
	| cursor_movment
	| display_separator;

do_block: DO statement* END;

while_statement: WHILE expression statement*;

expression: assignment | conditional_or_expression;

assignment: assignable (ASSIGN | ADD_TO) expression;
assignable: (FIELD_IDENTIFIER | IDENTIFIER | AT_VARIABLE) bracket_expression?;

function_call: (IDENTIFIER | function_keyword) call_parameter_list;

// This doesn't handle TEMP.VAR[1[2,3]] properly yet. (When no comma separates the '1' and the '[')
bracket_expression:
	LSB expression (COMMA expression)* RSB
	| LSB expression (COMMA expression)* COMMA? substring_argument RSB
	| LSB substring_argument RSB;
substring_argument:
	LSB expression COMMA (expression | STAR) RSB;

if_expression: IF expression THEN? statement (ELSE statement)?;

// Can case be used on anything other than a codestring?
case_expression: CASE expression statement+ ENDCASE;

conditional_or_expression:
	conditional_and_expression (OR conditional_and_expression)*;

conditional_and_expression:
	inclusive_or_expression (AND inclusive_or_expression)*;

inclusive_or_expression:
	exclusive_or_expression (BIT_OR exclusive_or_expression)*;

exclusive_or_expression:
	and_expression (BIT_XOR and_expression)*;

and_expression:
	equality_expression (BIT_AND equality_expression)*;

equality_expression:
	relational_expression (
		(EQUAL | NOT_EQUAL) relational_expression
	)*
	| ((EQUAL | NOT_EQUAL) relational_expression)+;

relational_expression:
	shift_expression (
		(LESS_THAN | MORE_THAN | LESS_OR_EQUAL | MORE_OR_EQUAL) shift_expression
	)*
	| (
		(LESS_THAN | MORE_THAN | LESS_OR_EQUAL | MORE_OR_EQUAL) shift_expression
	)+;

shift_expression:
	additive_expression (
		(BIT_SHIFT_LEFT | BIT_SHIFT_RIGHT) additive_expression
	)*;

additive_expression:
	multiplicative_expression (
		(PLUS | MINUS) multiplicative_expression
	)*;

multiplicative_expression:
	unary_expression (
		(STAR | SLASH | DOUBLE_SLASH |) unary_expression
	)*;

unary_expression:
	primary_expression
	| MINUS unary_expression
	| INCREMENT unary_expression
	| DECREMENT unary_expression;

primary_expression: (
		literal
		| LB expression RB
		| IDENTIFIER
		| FIELD_IDENTIFIER
		| AT_VARIABLE
		| RTMFILE_NAME
		| function_call
		| if_expression
		| case_expression
	) bracket_expression?;

//add dates, hex, ?
literal: NUMERIC_LITERAL | STRING_LITERAL | DATE_LITERAL;

cursor_movment: LEFT | BACK | RIGHT | CR | UP | DOWN | HAT;
display_separator: COMMA;

return: RETURN return_statement_list;

function_keyword:
	ALLOC
	| COPYR
	| INDEX
	| LOCK
	| NOGROUP
	| PACK
	| READ
	| READLOCK
	| REF
	| RELEASE
	| SEGPTR
	| TESTLOCK
	| UNLOCK
	| WRITE
	| UNPACK
	| BNUM
	| DELETE
	| INIT
	| APPLY
	| CONCAT
	| CONVERT
	| EXT
	| LENGTH
	| MATCH
	| TRANSLATE
	| SUBSTR
	| ABS
	| EXP2
	| MAX
	| MIN
	| RANDOM
	| REM
	| ALTSCR
	| DISCARD
	| ERROR
	| RC
	| TRUNC
	| WAIT
	| VID
	| IN
	| INFLD
	| INOPT
	| SETOPT
	| VALID
	| OUT
	| SETERR
	| OUTIF
	| OUTIMM
	| DIE;

keyword:
	RTM
	| OVERLAY
	| PROC
	| RETURN
	| ENDPROC
	| QUITZUG
	| DO
	| END
	| CASE
	| ENDCASE
	| PROC
	| ENDPROC
	| ALWAYS
	| NEVER
	| UNTIL
	| WHILE
	| REPEAT
	| EXIT
	| IF
	| THEN
	| ELSE
	| AND
	| OR
	| ENTRY
	| ABORT
	| DATA
	| EXT
	| EXTDATA
	| EXTRACT
	| FILE
	| FILES
	| INCLUDE
	| LIVE
	| LIVEUSER
	| NAME
	| NEWCLUSTERS
	| OPT
	| PROG
	| RECORD
	| SCRNDATA
	| SNAPSHOT
	| TEST
	| TESTUSER
	| USERDATA
	| DOWN
	| ERASE
	| CR
	| BACK
	| BEEP
	| CLEAR
	| LEFT
	| RIGHT
	| TABSTOP
	| UP
	| FLASH
	| HI
	| LO
	| KEYED
	| NOABORT
	| ADD
	| DEL
	| FIRST
	| NEXT
	| FIND
	| FND
	| OUTONLY
	| FIXERRS;