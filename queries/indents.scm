;; ============================================================
;; MoonHighlight — Indentation Queries
;; Used by editors that support Tree-sitter-based indentation
;; ============================================================

[
  (source_file)
  (block_expr)
  (function_declaration)
  (struct_declaration)
  (enum_declaration)
  (trait_declaration)
  (impl_block)
  (if_expr)
  (match_expr)
  (guard_expr)
  (while_expr)
  (for_expr)
  (loop_expr)
  (try_expr)
] @indent

"}" @dedent
")" @dedent
"]" @dedent
"else" @dedent
(catch_clause) @dedent