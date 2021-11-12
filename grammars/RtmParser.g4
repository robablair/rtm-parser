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
name_definition: DOLLAR_NAME (IDENTIFIER | NAME_END) NAME_TEXT*;
name_include:
	DOLLAR_INCLUDE (STAR | IDENTIFIER) (LB IDENTIFIER RB)?;

overlay_name: DOLLAR_ENTRY IDENTIFIER;

declarations: files? (data | data_shared)? data_ext? ext?;

files: DOLLAR_FILES IDENTIFIER*;

data: DOLLAR_DATA DATA_NEWLINE* data_declarations DATA_NEWLINE*;
data_shared:
	DOLLAR_DATA_SHARED DATA_NEWLINE* data_declarations DATA_NEWLINE*;
data_ext:
	DOLLAR_EXTDATA DATA_NEWLINE* data_declarations DATA_NEWLINE*;
data_declarations: (data_field | name_include) (
		COMMA? DATA_NEWLINE* (data_field | name_include)
	)*;
data_field:
	IDENTIFIER edit_mask? (STAR NUMERIC_LITERAL)?
	| (FILL | IDENTIFIER) EQUAL IDENTIFIER edit_mask?
	| FILL EQUAL IDENTIFIER
	| FIELD_IDENTIFIER;
edit_mask: (
		IDENTIFIER
		| COPY_MASK (PREFIX IDENTIFIER)?
		| code_string_mask
		| group_mask
	);
group_mask:
	DATA_NEWLINE* LSB DATA_NEWLINE* (data_field COMMA? DATA_NEWLINE*)+ DATA_NEWLINE* RSB;
code_string_mask:
	CODE_STRING_START CODE_STRING_VALUE (
		CODE_STRING_DELIM CODE_STRING_DELIM? CODE_STRING_VALUE
	)* CODE_STRING_END;

ext: DOLLAR_EXT IDENTIFIER*;

parameter_list: assignable (COMMA assignable)*;
call_parameter_list:
	LB (argument (COMMA | argument | COMMA argument)*)? (
		COLON call_return_parameter (
			COMMA call_return_parameter?
		)*
	)? RB;
call_return_parameter: assignable | IGNORED_RETURN | STAR;
argument: (AT? (IDENTIFIER | keyword) EQUAL)? (
		expression
		| keyword
		| STAR
	);
return_statement_list: LB (expression (',' expression)*)? RB;

prog: DOLLAR_PROG LB parameter_list? RB statement* prog_end;
prog_end: return | QUITZUG;

proc:
	IDENTIFIER PROC (LB parameter_list? RB)? statement* ENDPROC;

expression:
	LB expression RB							# parenthesis
	| assignable (ASSIGN | ADD_TO) expression	# assignmentExpr
	| op = (
		EQUAL
		| NOT_EQUAL
		| LESS_THAN
		| MORE_THAN
		| LESS_OR_EQUAL
		| MORE_OR_EQUAL
	) right = expression # comparison
	| left = expression op = (
		EQUAL
		| NOT_EQUAL
		| LESS_THAN
		| MORE_THAN
		| LESS_OR_EQUAL
		| MORE_OR_EQUAL
	) right = expression															# comparison
	| left = expression op = (AND | OR) right = expression							# conditional
	| op = (MINUS | INCREMENT | DECREMENT) expression								# unary
	| left = expression op = (BIT_AND | BIT_OR | BIT_XOR) right = expression		# infix
	| left = expression op = (BIT_SHIFT_LEFT | BIT_SHIFT_RIGHT) right = expression	# infix
	| left = expression op = (
		STAR
		| SLASH
		| DOUBLE_SLASH
		| SLASH_COLON
	) right = expression										# infix
	| left = expression op = (PLUS | MINUS) right = expression	# infix
	| function_call												# function
	| if_expression												# if
	| case_expression											# case
	| expression bracket_expression								# bracket
	| value = literal											# literalExpr
	| value = (
		IDENTIFIER
		| FIELD_IDENTIFIER
		| AT_VARIABLE
		| RTMFILE_NAME
	) # identifier;

statement:
	expression
	| do_block
	| while_statement
	| repeat_statement
	| until_statement
	| return
	| SEMI_COLON
	| name_include
	| statement_keyword
	| cursor_movment
	| display_separator;

do_block: DO statement* END;

while_statement: WHILE expression statement*;
repeat_statement: REPEAT statement*;
until_statement: UNTIL expression statement*;

assignable: (FIELD_IDENTIFIER | IDENTIFIER | AT_VARIABLE) bracket_expression?;

function_call: (IDENTIFIER | function_keyword) call_parameter_list;

// This doesn't handle TEMP.VAR[1[2,3]] properly yet. (When no comma separates the '1' and the '[')
bracket_expression:
	LSB (expression | bracket_expression | STAR) (
		COMMA? (expression | bracket_expression | STAR)
	)* RSB;

if_expression: IF expression THEN? statement (ELSE statement)?;

// Can case be used on anything other than a codestring?
case_expression: CASE expression statement+ ENDCASE;

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

statement_keyword:
	EXIT
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
	| OUTONLY
	| FIXERRS;

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
	| KEYED
	| NOABORT
	| ADD
	| DEL
	| FIRST
	| NEXT
	| FIND
	| FND;