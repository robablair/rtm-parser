parser grammar RtmParser;

options {
	tokenVocab = RtmLexer;
}

start:
	rtm_source
	| FREE_TEXT+; // for files that are included with '$INCLUDE FILENAME'

rtm_source: (
		SOURCE_DESCRIPTION (overlay | name_definition | NL)*
	)? (source_end | EOF);

overlay:
	overlay_name NL* files? (data_area | NL)* ext? NL* prog (
		proc
		| abort
		| name_include
		| statement
		| NL
	)*;
//statements outide of procs? Probably a mistake, does RTM not produce compile error?

source_end: DOLLAR_END;

//TODO: allow @ ?
name_definition: DOLLAR_NAME (ID | NAME_END) FREE_TEXT*;
name_include:
	DOLLAR_INCLUDE (STAR | ID | DATA_ID_OR_MASK) (
		LB (ID | DATA_ID_OR_MASK) RB
	)?;

overlay_name: DOLLAR_ENTRY ID;

files: DOLLAR_FILES NL* ((ID | name_include) (COMMA | NL)+)*;
ext: DOLLAR_EXT NL* ((ID | name_include) (COMMA | NL)+)*;

data_area:
	(
		DOLLAR_DATA (COMMA SHARED)?
		| DOLLAR_EXTDATA
		| DOLLAR_SCRNDATA
		| DOLLAR_USERDATA
	) NL* data_declarations?;

data_declarations:
	(data_field | name_include) (
		(COMMA | NL*) (data_field | name_include)
	)*;
data_field: (DATA_ID_OR_MASK | FIELD_ID | FILL) (
		edit_mask (STAR NUMERIC_LITERAL)*
		| (STAR NUMERIC_LITERAL)* group_mask
		| EQUAL (DATA_ID_OR_MASK | FIELD_ID) group_mask?
	)?;
edit_mask: (
		DATA_ID_OR_MASK
		| copy_mask
		| code_string_mask
		| group_mask
	);
copy_mask: COPY_MASK (PREFIX (ID | DATA_ID_OR_MASK))?;
group_mask: NL* LSB NL* (data_field COMMA? NL*)+ NL* RSB;

code_string_mask:
	CODE_STRING_START (
		(WS* NL (NL | WS)* code_string_delim)? code_string_value (
			code_string_delim code_string_value
		)*
	) CODE_STRING_END;
code_string_delim: HAT (WS* NL (NL | WS)* HAT)?;
code_string_value: (CODE_STRING_VALUE | WS)+;

parameter_list: (assignable | STAR) (
		(COMMA | NL)* (assignable | STAR)
	)*;
call_parameter_list:
	LB NL* argument_list? NL* (
		COLON NL* call_return_parameter_list?
	)? NL* RB;
argument_list: argument ((COMMA | NL)* argument)* COMMA?;
call_return_parameter_list:
	call_return_parameter ((COMMA | NL)+ call_return_parameter)*;
call_return_parameter: assignable | IGNORED_RETURN | STAR;
argument:
	ID EQUAL expression
	| RTMFILE_NAME
	| STAR
	| LB NL* argument_list NL* RB
	| expression;
return_statement_list:
	LB (expression ((COMMA | NL)+ expression)*)? RB;

prog: DOLLAR_PROG LB parameter_list? RB (statement | NL)*;

proc:
	ID PROC (LB parameter_list? RB)? (statement | NL)* ENDPROC (
		terminator_statement
	)*;

abort:
	DOLLAR_ABORT (LB parameter_list? RB)? statement* terminator_statement?;

terminator_statement: return | QUITZUG | DIE LB argument RB;

function_call: (ID | OVERLAY ID) call_parameter_list;

expression:
	LB NL* expression NL* RB						# parenthesis
	| assignable (ASSIGN | ADD_TO) NL* expression	# assignmentExpr
	| op = (
		EQUAL
		| NOT_EQUAL
		| LESS_THAN
		| MORE_THAN
		| LESS_OR_EQUAL
		| MORE_OR_EQUAL
	) NL* right = expression # comparison
	| left = expression NL* op = (
		EQUAL
		| NOT_EQUAL
		| LESS_THAN
		| MORE_THAN
		| LESS_OR_EQUAL
		| MORE_OR_EQUAL
	) NL* right = expression															# comparison
	| left = expression NL* op = (AND | OR) NL* right = expression						# conditional
	| op = (MINUS | INCREMENT | DECREMENT) expression									# unary
	| left = expression NL* op = (BIT_AND | BIT_OR | BIT_XOR) NL* right = expression	# infix
	| left = expression NL* op = (
		BIT_SHIFT_LEFT
		| BIT_SHIFT_RIGHT
	) NL* right = expression # infix
	| left = expression NL* op = (
		STAR
		| SLASH
		| DOUBLE_SLASH
		| SLASH_COLON
	) NL* right = expression											# infix
	| left = expression NL* op = (PLUS | MINUS) NL* right = expression	# infix
	| value = function_call												# function
	| value = if_expression												# if
	| value = case_expression											# case
	| value = expression bracket_expression								# bracket
	| value = literal													# literalExpr
	| value = identifier_expression										# identifier;

identifier_expression: ID | FIELD_ID | AT_VARIABLE;

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
	| COMMA
	| HAT;

do_block: DO (statement | NL)* END;

while_statement: WHILE expression NL* statement;
until_statement: UNTIL expression NL* statement;
repeat_statement: REPEAT NL* statement;
always_statement: ALWAYS NL* statement;
never_statement: NEVER NL* statement;

assignable: (FIELD_ID | ID | AT_VARIABLE) bracket_expression?;

bracket_expression:
	LSB (expression | bracket_expression | STAR) (
		COMMA? (expression | bracket_expression | STAR)
	)* RSB;

if_expression:
	IF expression THEN? NL* statement NL* (ELSE NL* statement)?;

case_expression: CASE expression (statement | NL)+ ENDCASE;

literal:
	NUMERIC_LITERAL
	| STRING_LITERAL
	| DATE_LITERAL
	| HEX_LITERAL
	| KEY_LITERAL;

return: RETURN return_statement_list;
