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
"trait" @keyword.type
"impl" @keyword
"async" @keyword
"await" @keyword
"raise" @keyword.exception
"try" @keyword.exception
"catch" @keyword.exception
"noraise" @keyword
"if" @keyword.conditional
"else" @keyword.conditional
"match" @keyword.conditional
"guard" @keyword.conditional
"while" @keyword.repeat
"for" @keyword.repeat
"in" @keyword.repeat
"loop" @keyword.repeat
"break" @keyword.repeat
"continue" @keyword.repeat
"return" @keyword.return
"defer" @keyword
"import" @keyword.import
"package" @keyword.import
"as" @keyword.import
"extern" @keyword
"declare" @keyword
"open" @keyword
"with" @keyword
"derive" @keyword
"default" @keyword
"suberror" @keyword

;; ---- LITERALS ----
(integer_literal) @number
(float_literal) @number.float
(boolean_literal) @boolean
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
(named_type) @type
(generic_type) @type
(tuple_type) @type
(fn_type) @type.function
(array_type) @type.builtin
(option_type) @type
(result_type) @type.builtin
(ref_type) @type
(external_type) @type.modifier
(type_param) @type.parameter

;; ---- FUNCTIONS & METHODS ----
(function_declaration (identifier) @function)
(impl_method (identifier) @function)
(trait_method (identifier) @function)
(closure_expr) @function
(call_expr (identifier) @function.call)

;; Method calls via field access + call pattern
(method_call (method: (identifier) @method.call))
(field_access (field: (identifier) @property))

;; ---- VARIABLES & PARAMETERS ----
(value_declaration (ident_pattern (identifier) @variable))
(param (name: (identifier) @variable.parameter))
(param (label: (identifier) @variable.parameter))

;; Pattern variables in match/guard
(match_arm (pattern (ident_pattern (identifier) @variable)))
(guard_expr (pattern (ident_pattern (identifier) @variable)))
(for_expr (pattern (ident_pattern (identifier) @variable)))

;; ---- FIELDS ----
(field_def (name: (identifier) @property))
(enum_variant (name: (identifier) @type.enum.variant))
(struct_expr (name: (identifier) @property))

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
"~" @operator
"<<" @operator
">>" @operator
"=>" @operator
"->" @operator
"::" @operator
"|>" @operator
".." @operator
"... " @operator
"..<" @operator
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

;; ---- ATTRIBUTES ----
(attribute (name: (identifier) @attribute))
(attr_arg (key: (identifier) @attribute))

;; Special attribute highlighting
((attribute (name: (identifier) @_attr)) (#eq? @_attr "deprecated")) @attribute.deprecated
((attribute (name: (identifier) @_attr)) (#eq? @_attr "cfg")) @attribute.preprocessor

;; ---- COMMENTS ----
(line_comment) @comment
(block_comment) @comment

;; ---- SPECIAL PATTERNS ----
(wildcard_pattern) @variable.parameter
(rest_pattern) @variable.parameter
(or_pattern) @variable.parameter

;; ---- ERROR HANDLING HIGHLIGHTS ----
(try_expr) @exception
(catch_arm) @exception
(raise_expr) @exception

;; ---- ASYNC HIGHLIGHTS ----
(await_expr) @function.builtin
(defer_expr) @function.builtin

;; ---- PACKAGE & IMPORT ----
(package_clause (package_name) @module)
(import_declaration (path: (package_name) @module))
(import_from_declaration (path: (package_name) @module))
(import_member (name: (identifier) @variable))
(import_member (alias: (identifier) @variable))