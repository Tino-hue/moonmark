;; ============================================================
;; MoonHighlight — Locals (variable scope) Queries
;; Used for local variable renaming and go-to-definition
;; ============================================================

;; Function parameters are local definitions
(param (identifier) @definition.var)

;; Let/const bindings
(value_declaration (ident_pattern (identifier) @definition.var))

;; For loop variables
(for_expr (pattern (ident_pattern (identifier) @definition.var)))

;; Match arm bindings
(match_arm (pattern (ident_pattern (identifier) @definition.var)))
(catch_arm (pattern (ident_pattern (identifier) @definition.var)))

;; Guard bindings
(guard_expr (pattern (ident_pattern (identifier) @definition.var)))
