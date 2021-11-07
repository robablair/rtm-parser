lexer grammar RtmLexer;

channels {
	COMMENTS_CHANNEL
}

SOURCE_TYPE: (RTM | ZUG) -> mode(SOURCE_DESCRIPTION);

FULL_LINE_COMMENT:
	NEWLINE '*' INPUTCHARACTER* -> channel(COMMENTS_CHANNEL);
INLINE_COMMENT:
	'<<' INPUTCHARACTER* -> channel(COMMENTS_CHANNEL);

DOLLAR_ENTRY: DOLLAR ENTRY;
DOLLAR_FILES: DOLLAR FILES;
DOLLAR_DATA: DOLLAR DATA;
DOLLAR_DATA_SHARED: DOLLAR DATA_SHARED;
DOLLAR_EXT: DOLLAR EXT;
DOLLAR_EXTDATA: DOLLAR EXTDATA;
DOLLAR_INCLUDE: DOLLAR INCLUDE;
DOLLAR_NAME: DOLLAR NAME;
DOLLAR_PROG: DOLLAR PROG;
DOLLAR_END: DOLLAR END -> mode(END_OF_SOURCE);

LB: '(';
RB: ')';
COLON: ':';
SEMI_COLON: ';';
COMMA: ',';
DOLLAR: '$';
HAT: '^';
AT: '@';
LSB: '[';
RSB: ']';
DOT: '.';
ELLIPSIS: '...';

//Assignments
ASSIGN: '_';
INCREMENT: '++';
DECREMENT: '--';
ADD_TO: '+_';

//Arithmetic
PLUS: '+';
MINUS: '-';
STAR: '*';
SLASH: '/';
DOUBLE_SLASH: '//';
SLASH_COLON: '/:';

//Logical
BIT_AND: '&';
BIT_OR: '!';
BIT_XOR: '%';
BIT_SHIFT_LEFT: '<:';
BIT_SHIFT_RIGHT: ':>';

//Relations
EQUAL: '=';
NOT_EQUAL: '#';
LESS_THAN: '<';
MORE_THAN: '>';
LESS_OR_EQUAL: '<=';
MORE_OR_EQUAL: '>=';

//Literals
NUMERIC_LITERAL: [0-9]+;
STRING_LITERAL: '"' ~["\\\r\n\u0085\u2028\u2029]* '"';
DATE_LITERAL: STRING_LITERAL 'D';

//Keywords
RTM: 'RTM';
ZUG: 'ZUG';
OVERLAY: 'OVERLAY';
PROC: 'PROC';
RETURN: 'RETURN';
ENDPROC: 'ENDPROC';
QUITZUG: 'QUITZUG';
DO: 'DO';
END: 'END';
CASE: 'CASE';
ENDCASE: 'ENDCASE';
ALWAYS: 'ALWAYS';
NEVER: 'NEVER';
UNTIL: 'UNTIL';
WHILE: 'WHILE';
REPEAT: 'REPEAT';
EXIT: 'EXIT';
IF: 'IF';
THEN: 'THEN';
ELSE: 'ELSE';
AND: 'AND';
OR: 'OR';
ENTRY: 'ENTRY';
ABORT: 'ABORT';
DATA: 'DATA';
DATA_SHARED: 'DATA,SHARED';
EXT: 'EXT';
EXTDATA: 'EXTDATA';
EXTRACT: 'EXTRACT';
FILE: 'FILE';
FILES: 'FILES';
INCLUDE: 'INCLUDE';
LIVE: 'LIVE';
LIVEUSER: 'LIVEUSER';
NAME: 'NAME';
NEWCLUSTERS: 'NEWCLUSTERS';
OPT: 'OPT';
PROG: 'PROG';
RECORD: 'RECORD';
SCRNDATA: 'SCRNDATA';
SNAPSHOT: 'SNAPSHOT';
TEST: 'TEST';
TESTUSER: 'TESTUSER';
USERDATA: 'USERDATA';
DOWN: 'DOWN';
ERASE: 'ERASE';
CR: 'CR';
BACK: 'BACK';
BEEP: 'BEEP';
CLEAR: 'CLEAR';
LEFT: 'LEFT';
RIGHT: 'RIGHT';
TABSTOP: 'TABSTOP';
UP: 'UP';
FLASH: 'FLASH';
HI: 'HI';
LO: 'LO';
KEYED: 'KEYED';
NOABORT: 'NOABORT';
ALLOC: 'ALLOC';
COPYR: 'COPYR';
INDEX: 'INDEX';
LOCK: 'LOCK';
NOGROUP: 'NOGROUP';
PACK: 'PACK';
READ: 'READ';
READLOCK: 'READLOCK';
REF: 'REF';
RELEASE: 'RELEASE';
SEGPTR: 'SEGPTR';
TESTLOCK: 'TESTLOCK';
UNLOCK: 'UNLOCK';
WRITE: 'WRITE';
UNPACK: 'UNPACK';
BNUM: 'BNUM';
DELETE: 'DELETE';
INIT: 'INIT';
APPLY: 'APPLY';
CONCAT: 'CONCAT';
CONVERT: 'CONVERT';
LENGTH: 'LENGTH';
MATCH: 'MATCH';
TRANSLATE: 'TRANSLATE';
SUBSTR: 'SUBSTR';
ABS: 'ABS';
EXP2: 'EXP2';
MAX: 'MAX';
MIN: 'MIN';
RANDOM: 'RANDOM';
REM: 'REM';
ALTSCR: 'ALTSCR';
DISCARD: 'DISCARD';
ERROR: 'ERROR';
DIE: 'DIE';
RC: 'RC';
TRUNC: 'TRUNC';
WAIT: 'WAIT';
VID: 'VID';
IN: 'IN';
INFLD: 'INFLD';
INOPT: 'INOPT';
SETOPT: 'SETOPT';
VALID: 'VALID';
OUT: 'OUT';
SETERR: 'SETERR';
FIXERRS: 'FIXERRS';
OUTIF: 'OUTIF';
OUTIMM: 'OUTIMM';
OUTONLY: 'OUTONLY';
ADD: 'ADD';
DEL: 'DEL';
FIRST: 'FIRST';
NEXT: 'NEXT';
FIND: 'FIND';
FND: 'FND';

//Edit masks
CHAR_MASK: [AX] [0-9]+;
NUMERIC_MASK: [NUSFZ] [BLP-]* [0-9]+ ('.' [0-9]+)*;
DATA_MASK: 'D' [AUEFDMYNHBL]+;
FIELD_MASK: ['] FIELD_IDENTIFIER;
PREFIX: 'PREFIX';
FILL: 'FILL';

CODE_STRING_START: 'C^' -> mode(CODE_STRING_MODE1);

FIELD_IDENTIFIER: [WFHG] [0-9]? DOLLAR IDENTIFIER;
IDENTIFIER: [a-zA-Z] [a-zA-Z0-9.]*;
AT_VARIABLE: '@' [0-4ABCD];
RTMFILE_NAME: DOLLAR IDENTIFIER;
IGNORED_RETURN: '\'' (FIELD_IDENTIFIER | IDENTIFIER | AT_VARIABLE);

WHITESPACE: [ \t\r\n]+? -> skip; // skip spaces, tabs, newlines

mode SOURCE_DESCRIPTION;
SOURCE_DESCRIPTION_SKIP: NEWLINE -> skip, mode(DEFAULT_MODE);
SOURCE_DESC: INPUTCHARACTER+ -> mode(DEFAULT_MODE);

mode CODE_STRING_MODE1;
CODE_STRING_VALUE: [A-Z0-9 ',/]+;
CODE_STRING_NEWLINE: NEWLINE -> skip, mode(CODE_STRING_MODE2);
CODE_STRING_DELIM: HAT;
CODE_STRING_END: '^^' -> mode(DEFAULT_MODE);
CODE_STRING_TRAILING_WS: WHITESPACE NEWLINE -> skip, mode(CODE_STRING_MODE2);
CODE_STRING_FULL_LINE_COMMENT:
	WHITESPACE FULL_LINE_COMMENT -> channel(COMMENTS_CHANNEL), type(FULL_LINE_COMMENT);
CODE_STRING_END_LINE_COMMENT:
	WHITESPACE INLINE_COMMENT -> channel(COMMENTS_CHANNEL), type(INLINE_COMMENT);

mode CODE_STRING_MODE2;
CODE_STRING_DELIM_2: HAT -> type(CODE_STRING_DELIM), mode(CODE_STRING_MODE1);
CODE_STRING_END_2: '^^' -> type(CODE_STRING_END), mode(DEFAULT_MODE);
CODE_STRING_TRAILING_WS2: WHITESPACE NEWLINE -> skip;
CODE_STRING_FULL_LINE_COMMENT_2:
	WHITESPACE FULL_LINE_COMMENT -> channel(COMMENTS_CHANNEL), type(FULL_LINE_COMMENT);
CODE_STRING_END_LINE_COMMENT_2:
	WHITESPACE INLINE_COMMENT -> channel(COMMENTS_CHANNEL), type(INLINE_COMMENT);
CODE_STRING_WHITESPACE:
	WHITESPACE -> skip;

mode END_OF_SOURCE;
FREE_TEXT: INPUTCHARACTER* (NEWLINE | EOF) -> channel(COMMENTS_CHANNEL);

//fragments
fragment INPUTCHARACTER: ~[\r\n\u0085\u2028\u2029];

fragment NEWLINE:
	'\r\n'
	| '\r'
	| '\n'
	| '\u0085' // <Next Line CHARACTER (U+0085)>'
	| '\u2028' //'<Line Separator CHARACTER (U+2028)>'
	| '\u2029'; //'<Paragraph Separator CHARACTER (U+2029)>'