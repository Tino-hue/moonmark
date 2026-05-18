; ============================================================
; MoonHighlight — Tree-sitter Highlight Queries for MoonBit
; Maps AST node types to highlight groups (TextMate scopes)
;
; Convention: @function, @type, @variable, @keyword, etc.
; See: https://tree-sitter.github.io/tree-sitter/syntax-highlighting
; ============================================================

;; ---- KEYWORDS ----
"pub" @keyword
"priv" @keyword
"let" @keyword
"const" @keyword
"mut" @keyword
"fn" @keyword.function
"type" @keyword.type
"struct" @keyword.type
"enum" @keyword.type
"trait" @keyword.type-
"impl" @keyword
"async" @keyword
"raise" @keyword.exception
"try" @keyword.exception
"catch" @keyword.exception
"if" @keyword.conditional
"else" @keyword.conditional
"match" @keyword.conditional
"guard" @keyword.conditional
"while" @keyword.repeat
"for" @keyword.repeat
"in" @keyword.repeat
"loop" @keyword.repeat
"break" @keyword.repeat
(continue_expr) @keyword.repeat
"return" @keyword.return
"defer" @keyword
"import" @keyword.import
"package" @keyword.import
"suberror" @keyword

;; ---- LITERALS ----
(number_literal) @number
(bool_literal) @boolean
(char_literal) @character
(string_literal) @string
(raw_string_literal) @string
(interpolated_string_literal) @string
(byte_literal) @character.special
(bytes_literal) @string.special
(unit_literal) @constant.builtin

;; ---- TYPES ----
(builtin_type) @type.builtin
(type_identifier) @type
(tuple_type) @type
(function_type) @type.function
(array_type) @type.builtin
(option_type) @type
(result_type) @type.builtin
(ref_type) @type

;; ---- FUNCTIONS & METHODS ----
(function_declaration (identifier) @function)
(impl_method (identifier) @function)
(trait_method (identifier) @function)
(closure_expr) @function
(function_call (identifier) @function.call)

;; Method calls via field access + call pattern
(method_call (identifier) @method.call)
(field_access (identifier) @property)

;; ---- VARIABLES & PARAMETERS ----
(value_declaration (identifier) @variable)
(param (identifier) @variable.parameter)

;; Pattern variables in match/guard
(match_arm (identifier_pattern (identifier) @variable))
(guard_expr (identifier_pattern (identifier) @variable))
(for_expr (identifier) @variable)

;; ---- FIELDS ----
(field_def (identifier) @property)
(enum_variant (constructor) @type.enum.variant)
(struct_expr (field_init (identifier) @property))

;; ---- OPERATORS ----
"=" @operator
"+=" @operator
"-=" @operator
"*=" @operator
"/=" @operator
"%=" @operator
"<<=" @operator
">>=" @operator
"&=" @operator
"|=" @operator
"^=" @operator
"+" @operator
"-" @operator
"*" @operator
"/" @operator
"%" @operator
"==" @operator
"!=" @operator
"<" @operator
">" @operator
"<=" @operator
">=" @operator
"&&" @operator
"||" @operator
"!" @operator
"&" @operator
"|" @operator
"^" @operator
"<<" @operator
">>" @operator
"=>" @operator
"->" @operator
"::" @operator
"|>" @operator
".." @operator
"is" @operator
"as" @operator

;; ---- PUNCTUATION ----
"(" @punctuation.bracket
")" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket
"[" @punctuation.bracket
"]" @punctuation.bracket
"," @punctuation.delimiter
";" @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter

;; ---- COMMENTS ----
(comment) @comment

;; ---- SPECIAL PATTERNS ----
(wildcard_pattern) @variable.parameter

;; ---- ERROR HANDLING HIGHLIGHTS ----
(try_expr) @exception
(catch_clause) @exception
(raise_expr) @exception

;; ---- PACKAGE & IMPORT ----
(package_clause (qualified_name) @module)
(import_declaration (qualified_name) @module)
