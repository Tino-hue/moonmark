;; ============================================================
;; MoonHighlight — Injection Queries
;; Enable Tree-sitter to parse embedded languages
;; ============================================================

;; External function body strings (JS/Wasm/C code in extern "...")
(extern_fn_declaration (string_literal) @javascript)
