parser grammar RtmParser;

options {
	tokenVocab = RtmLexer;
}

start:
	SOURCE_TYPE SOURCE_DESC? (overlay | name_definition)* (
		source_end
		| EOF
	);

overlay:
	overlay_name declarations prog (proc | name_include)* statement* abort?; //statements outide of procs? Probably a mistake, does RTM not produce compile error?

source_end: DOLLAR_END;

//TODO: allow @ ?
name_definition: DOLLAR_NAME (IDENTIFIER | NAME_END) NAME_TEXT*;
name_include:
	DOLLAR_INCLUDE (STAR | IDENTIFIER) (LB IDENTIFIER RB)?;

overlay_name: DOLLAR_ENTRY IDENTIFIER;

declarations: files? data_area* ext?;

files: DOLLAR_FILES (IDENTIFIER COMMA?)*;

data_area:
	data
	| data_shared
	| data_ext
	| data_scrn
	| data_user;
data: DOLLAR_DATA data_declarations;
data_shared: DOLLAR_DATA_SHARED data_declarations;
data_ext: DOLLAR_EXTDATA data_declarations;
data_scrn: DOLLAR_SCRNDATA data_declarations;
data_user: DOLLAR_USERDATA data_declarations;
data_declarations:
	NEWLINE* ((data_field | name_include) COMMA? NEWLINE*)* NEWLINE+;
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
	NEWLINE* LSB NEWLINE* (data_field COMMA? NEWLINE*)+ NEWLINE* RSB;
code_string_mask:
	CODE_STRING_START CODE_STRING_DELIM? CODE_STRING_VALUE (
		CODE_STRING_DELIM CODE_STRING_DELIM? CODE_STRING_VALUE
	)* CODE_STRING_END;

ext: DOLLAR_EXT (IDENTIFIER COMMA?)*;

parameter_list: (assignable | STAR) (COMMA? (assignable | STAR))*;
call_parameter_list:
	LB (argument (COMMA | argument | COMMA argument)*)? (
		COLON (call_return_parameter COMMA?)*
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

while_statement: WHILE expression statement;
repeat_statement: REPEAT statement;
until_statement: UNTIL expression statement;

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
	| HEX_LITERAL;

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
	| ALTSCR
	| OUTONLY
	| OUT
	| NOABORT
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
	| ADD
	| DEL
	| FIRST
	| NEXT
	| FIND
	| FND;