;; ============================================================
;; MoonHighlight — Locals (variable scope) Queries
;; Used for local variable renaming and go-to-definition
;; ============================================================

;; Function parameters are local definitions
(param (identifier) @definition.parameter)

;; Let/const bindings
(value_declaration (identifier) @definition.var)
(value_declaration
  (tuple_pattern
    (identifier_pattern (identifier) @definition.var)))

;; For loop variables
(for_expr (identifier) @definition.var)

;; Match arm bindings
(match_arm (identifier_pattern (identifier) @definition.var))

;; Guard pattern bindings
(guard_pattern (identifier_pattern (identifier) @definition.var))
(guard_pattern
  (constructor_pattern
    (identifier_pattern (identifier) @definition.var)))

;; Variable references
(identifier) @reference

;; Scope definitions
(function_declaration) @scope
(extern_fn_declaration) @scope
(impl_method) @scope
(closure_expr) @scope
(block_expr) @scope
