;; ============================================================
;; MoonHighlight — Injection Queries
;; Enable Tree-sitter to parse embedded languages (e.g., string interpolation)
;; ============================================================

;; String interpolation: embedded expressions inside $"..." or $|"..."|{...}| strings
(interpolated_string_literal (expression) @moonbit)

;; External function body strings (JS/Wasm/C code in extern "...")
(extern_fn_declaration (body: (string_literal) @javascript))