;; ============================================================
;; MoonHighlight — Locals (variable scope) Queries
;; Used for local variable renaming and go-to-definition
;; ============================================================

;; Function parameters are local definitions
(param (identifier) @definition.var)

;; Let/const bindings
(value_declaration (identifier) @definition.var)

;; For loop variables
(for_expr (identifier) @definition.var)

;; Match arm bindings
(match_arm (identifier_pattern (identifier) @definition.var))

;; Guard bindings
