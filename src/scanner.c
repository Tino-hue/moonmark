// MoonHighlight — External Scanner for MoonBit
// Handles complex lexical constructs that can't be expressed in grammar.js:
//   - String literals with escape sequences
//   - Raw multi-line strings (#|"..."|#)
//   - Interpolated strings ($"..." / $|"..."|{expr}|)
//   - Byte literals (b'...')
//   - Byte string literals (b"..." / b#|"..."|#)

#include <tree_sitter/parser.h>
#include <wctype.h>

// Token types (must match externals order in grammar.js)
enum TokenType {
  STRING_LITERAL,
  RAW_STRING_LITERAL,
  INTERPOLATED_STRING_LITERAL,
  BYTE_LITERAL,
  BYTES_LITERAL,
};

// Scanner state
typedef struct {
  bool in_interpolation;
  int interpolation_depth;
} Scanner;

void *tree_sitter_moonbit_external_scanner_create() {
  Scanner *scanner = (Scanner *)malloc(sizeof(Scanner));
  scanner->in_interpolation = false;
  scanner->interpolation_depth = 0;
  return scanner;
}

void tree_sitter_moonbit_external_scanner_destroy(void *payload) {
  free(payload);
}

unsigned tree_sitter_moonbit_external_scanner_serialize(void *payload, char *buffer) {
  Scanner *scanner = (Scanner *)payload;
  buffer[0] = scanner->in_interpolation ? 1 : 0;
  buffer[1] = scanner->interpolation_depth & 0xFF;
  return 2;
}

void tree_sitter_moonbit_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  Scanner *scanner = (Scanner *)payload;
  if (length >= 2) {
    scanner->in_interpolation = buffer[0] == 1;
    scanner->interpolation_depth = (unsigned char)buffer[1];
  } else {
    scanner->in_interpolation = false;
    scanner->interpolation_depth = 0;
  }
}

// Advance past whitespace
static void skip(TSLexer *lexer) {
  while (iswspace(lexer->lookahead)) {
    lexer->advance(lexer, false);
  }
}

// Check if current position starts a valid escape sequence
static bool is_escape(TSLexer *lexer) {
  if (lexer->lookahead != '\\') return false;
  lexer->advance(lexer, false);
  switch (lexer->lookahead) {
    case 'n': case 't': case 'r': case '\\':
    case '\'': case '"': case '0':
    case 'x': case 'u': case '{':
      return true;
    default:
      return false;
  }
}

// Scan a regular string literal: "..."
bool scan_string_literal(TSLexer *lexer) {
  if (lexer->lookahead != '"') return false;
  lexer->advance(lexer, true); // consume opening "

  while (lexer->lookahead != '\0') {
    if (lexer->lookahead == '"') {
      lexer->advance(lexer, true); // consume closing "
      return true;
    }
    if (lexer->lookahead == '\\' && is_escape(lexer)) {
      lexer->advance(lexer, true); // consume escaped char
    } else if (lexer->lookahead == '\n' || lexer->lookahead == '\r') {
      // Regular strings don't span lines
      return false;
    }
    lexer->advance(lexer, true);
  }
  return false; // unterminated
}

// Scan raw string literal: #|"..."|#
bool scan_raw_string_literal(TSLexer *lexer) {
  // Check for #| or #" prefix
  if (lexer->lookahead != '#') return false;
  lexer->advance(lexer, true);

  if (lexer->lookahead != '|') {
    // Not a raw string, bail out
    return false;
  }
  lexer->advance(lexer, true); // consume #|

  // Now scan until |#
  while (lexer->lookahead != '\0') {
    if (lexer->lookahead == '|') {
      lexer->advance(lexer, true);
      if (lexer->lookahead == '#') {
        lexer->advance(lexer, true); // consume closing |#
        return true;
      }
      // | not followed by #, continue
    }
    lexer->advance(lexer, true);
  }
  return false; // unterminated
}

// Scan interpolated string literal: $"..." or $|"..."|{...}|...
bool scan_interpolated_string_literal(TSLexer *lexer) {
  if (lexer->lookahead != '$') return false;
  lexer->advance(lexer, true); // consume $

  bool is_raw = false;
  if (lexer->lookahead == '|') {
    is_raw = true;
    lexer->advance(lexer, true); // consume $|
  }

  if (lexer->lookahead != '"') return false;
  lexer->advance(lexer, true); // consume "

  while (lexer->lookahead != '\0') {
    if (lexer->lookahead == '"') {
      if (!is_raw) {
        lexer->advance(lexer, true);
        return true;
      }
      // In raw mode, check for "| ending
      lexer->advance(lexer, true);
      if (lexer->lookahead == '|') {
        lexer->advance(lexer, true);
        return true;
      }
      continue;
    }

    // Interpolation expression \{...}
    if (lexer->lookahead == '\\') {
      lexer->advance(lexer, true);
      if (lexer->lookahead == '{') {
        // Found interpolation start, let the grammar handle the expression
        lexer->result_symbol = INTERPOLATED_STRING_LITERAL;
        return true;
      }
      // Regular escape sequence
      lexer->advance(lexer, true);
    } else {
      lexer->advance(lexer, true);
    }
  }
  return false;
}

// Scan byte literal: b'...'
bool scan_byte_literal(TSLexer *lexer) {
  if (lexer->lookahead != 'b') return false;
  lexer->advance(lexer, true);

  if (lexer->lookahead != '\'') return false;
  lexer->advance(lexer, true); // consume '

  while (lexer->lookahead != '\0') {
    if (lexer->lookahead == '\'') {
      lexer->advance(lexer, true); // consume closing '
      return true;
    }
    if (lexer->lookahead == '\\' && is_escape(lexer)) {
      lexer->advance(lexer, true);
    }
    lexer->advance(lexer, true);
  }
  return false;
}

// Scan byte string literal: b"..." or b#|"..."|#
bool scan_bytes_literal(TSLexer *lexer) {
  if (lexer->lookahead != 'b') return false;
  lexer->advance(lexer, true);

  if (lexer->lookahead == '\'') {
    // This is a byte literal, not bytes
    return false;
  }

  bool is_raw = false;
  if (lexer->lookahead == '#') {
    lexer->advance(lexer, true);
    if (lexer->lookahead == '|') {
      is_raw = true;
      lexer->advance(lexer, true);
    } else {
      return false;
    }
  }

  if (lexer->lookahead != '"') return false;
  lexer->advance(lexer, true); // consume "

  while (lexer->lookahead != '\0') {
    if (is_raw) {
      if (lexer->lookahead == '|') {
        lexer->advance(lexer, true);
        if (lexer->lookahead == '#') {
          lexer->advance(lexer, true);
          return true;
        }
      }
    } else {
      if (lexer->lookahead == '"') {
        lexer->advance(lexer, true);
        return true;
      }
    }
    if (lexer->lookahead == '\\' && is_escape(lexer)) {
      lexer->advance(lexer, true);
    }
    lexer->advance(lexer, true);
  }
  return false;
}

// Main entry point for Tree-sitter external scanner
bool tree_sitter_moonbit_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  // Skip any leading whitespace
  skip(lexer);

  // Try each token type
  if (valid_symbols[STRING_LITERAL] && scan_string_literal(lexer)) {
    lexer->result_symbol = STRING_LITERAL;
    return true;
  }

  if (valid_symbols[RAW_STRING_LITERAL] && scan_raw_string_literal(lexer)) {
    lexer->result_symbol = RAW_STRING_LITERAL;
    return true;
  }

  if (valid_symbols[INTERPOLATED_STRING_LITERAL] && scan_interpolated_string_literal(lexer)) {
    lexer->result_symbol = INTERPOLATED_STRING_LITERAL;
    return true;
  }

  if (valid_symbols[BYTE_LITERAL] && scan_byte_literal(lexer)) {
    lexer->result_symbol = BYTE_LITERAL;
    return true;
  }

  if (valid_symbols[BYTES_LITERAL] && scan_bytes_literal(lexer)) {
    lexer->result_symbol = BYTES_LITERAL;
    return true;
  }

  return false;
}