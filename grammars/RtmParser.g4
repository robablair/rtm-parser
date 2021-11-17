parser grammar RtmParser;

options {
	tokenVocab = RtmLexer;
}

start:
	rtm_source
	| FREE_TEXT+; // for files that are included with '$INCLUDE FILENAME'

rtm_source: (
		SOURCE_TYPE SOURCE_DESC? (overlay | name_definition)*
	)? (source_end | EOF);

overlay:
	overlay_name declarations prog (proc | name_include)* statement* abort?;
//statements outide of procs? Probably a mistake, does RTM not produce compile error?

source_end: DOLLAR_END;

//TODO: allow @ ?
name_definition: DOLLAR_NAME (IDENTIFIER | NAME_END) NAME_TEXT*;
name_include:
	DOLLAR_INCLUDE (STAR | IDENTIFIER) (LB IDENTIFIER RB)?;

overlay_name: DOLLAR_ENTRY IDENTIFIER;

declarations: files? data_area* ext?;

files: DOLLAR_FILES (IDENTIFIER COMMA?)*;

data_area:
	(
		DOLLAR_DATA
		| DOLLAR_DATA_SHARED
		| DOLLAR_EXTDATA
		| DOLLAR_SCRNDATA
		| DOLLAR_USERDATA
	) data_declarations;

data_declarations:
	NEWLINE* ((data_field | name_include) COMMA? NEWLINE*)* NEWLINE+;
data_field:
	(IDENTIFIER | FIELD_IDENTIFIER | FILL) (
		edit_mask (STAR NUMERIC_LITERAL)?
		| (STAR NUMERIC_LITERAL)? group_mask
		| EQUAL (IDENTIFIER | FIELD_IDENTIFIER) group_mask?
	)?;
edit_mask: (
		IDENTIFIER
		| COPY_MASK (PREFIX IDENTIFIER)?
		| code_string_mask
		| group_mask
	);
group_mask:
	NEWLINE* LSB NEWLINE* (data_field COMMA? NEWLINE*)+ NEWLINE* RSB;
code_string_mask:
	CODE_STRING_START CODE_STRING_DELIM? CODE_STRING_VALUE+ (
		CODE_STRING_DELIM CODE_STRING_DELIM? CODE_STRING_VALUE+
	)* CODE_STRING_END;

ext: DOLLAR_EXT (IDENTIFIER COMMA?)*;

parameter_list: (assignable | STAR) (COMMA? (assignable | STAR))*;
call_parameter_list:
	LB (argument (COMMA | argument | COMMA argument)*)? (
		COLON (call_return_parameter COMMA?)*
	)? RB;
call_return_parameter: assignable | IGNORED_RETURN | STAR;
argument: (AT? (IDENTIFIER | argument_keyword) EQUAL)? (
		expression
		| argument_keyword
		| STAR
	)
	| LB (argument COMMA?)+ RB;
return_statement_list: LB (expression (',' expression)*)? RB;

prog: DOLLAR_PROG LB parameter_list? RB statement*;

proc:
	IDENTIFIER PROC (LB parameter_list? RB)? statement* ENDPROC (
		terminator_statement
	)*;

abort:
	DOLLAR_ABORT (LB parameter_list? RB)? statement* terminator_statement?;

terminator_statement:
	return
	| QUITZUG
	| DIE LB NUMERIC_LITERAL RB;

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
	| value = function_call										# function
	| value = if_expression										# if
	| value = case_expression									# case
	| value = expression bracket_expression						# bracket
	| value = literal											# literalExpr
	| value = identifier_expression								# identifier;

identifier_expression:
	IDENTIFIER
	| FIELD_IDENTIFIER
	| AT_VARIABLE
	| RTMFILE_NAME
	| REM;

statement:
	expression
	| do_block
	| while_statement
	| repeat_statement
	| until_statement
	| always_statement
	| never_statement
	| terminator_statement
	| SEMI_COLON
	| name_include
	| statement_keyword
	| cursor_movement
	| COMMA;

do_block: DO statement* END;

while_statement: WHILE expression statement;
repeat_statement: REPEAT statement;
until_statement: UNTIL expression statement;
always_statement: ALWAYS statement;
never_statement: NEVER statement;

assignable: (FIELD_IDENTIFIER | IDENTIFIER | AT_VARIABLE) bracket_expression?;

function_call: (IDENTIFIER | function_keyword) call_parameter_list
	| OVERLAY IDENTIFIER call_parameter_list;

// This doesn't handle TEMP.VAR[1[2,3]] properly yet. (When no comma separates the '1' and the '[')
bracket_expression:
	LSB (expression | bracket_expression | STAR) (
		COMMA? (expression | bracket_expression | STAR)
	)* RSB;

if_expression: IF expression THEN? statement (ELSE statement)?;

// Can case be used on anything other than a codestring?
case_expression: CASE expression statement+ ENDCASE;

//add dates, hex, ?
literal:
	NUMERIC_LITERAL
	| STRING_LITERAL
	| DATE_LITERAL
	| HEX_LITERAL
	| KEY_LITERAL;

cursor_movement: LEFT | BACK | RIGHT | CR | UP | DOWN | HAT;

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
	| DIE
	| KEYED;

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
	| ALTSCR
	| OUTONLY
	| OUT
	| NOABORT
	| FIXERRS;

argument_keyword: DATA | CLEAR | link_keyword;

link_keyword: WRITE | READ | ABORT;
// | OPEN | CLOSE | CREATE | WRITE_ACC | WRITE_REJ | SET | OPEN_QUEUE | WRITE_EOF | WRITE_ERR;