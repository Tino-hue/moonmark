// MoonHighlight — Tree-sitter Grammar for MoonBit
// Phase: PLANNING (grammar.js skeleton)
// This file defines the complete grammar for MoonBit v0.9.2 syntax

module.exports = grammar({
  name: 'moonbit',

  // Extras: tokens that can appear anywhere (whitespace, comments)
  extras: ($) => [
    $.line_comment,
    $.block_comment,
    /\s/,
  ],

  // Word tokens: used for keyword matching (must be in the grammar)
  word: ($) => $.identifier,

  // Precedences: resolve ambiguous productions
  precedence: ($) => [
    ['left', $.sequence_expression],
    ['right', 'unary_minus', 'not'],
    ['left', $.multiplication, $.division, $.modulo],
    ['left', $.addition, $.subtraction],
    ['left', $.shift_left, $.shift_right],
    ['left', $.bitwise_and],
    ['left', $.bitwise_xor],
    ['left', $.bitwise_or],
    ['left', $.comparison],
    ['left', 'and'],
    ['left', 'or'],
    ['right', '=>'],
    ['right', 'throw'],
  ],

  // External rules: placeholder for scanner.c (C scanner for complex lexing)
  externals: ($) => [
    $.string_literal,
    $.raw_string_literal,
    $.interpolated_string_literal,
    $.byte_literal,
    $.bytes_literal,
  ],

  // Inline rules: rules that should not appear as named children in parent nodes
  inline: ($) => [
    $.source_file,
    $.function_type,
    $.block,
    $.pattern,
  ],

  // -----------------------------------------------------------------------
  // START — Entry point
  // -----------------------------------------------------------------------
  rules: {

    // --------------------------------------------------------------------
    // FILE STRUCTURE
    // --------------------------------------------------------------------
    source_file: ($) => seq(
      optional($.shebang),
      optional($.package_clause),
      repeat($.import_declaration),
      repeat($.top_level_declaration),
    ),

    shebang: ($) => /#!.*/,

    package_clause: ($) => seq('package', $.package_ref),

    package_ref: ($) => sep1(/[\w\-\.]+/, '/'),

    import_declaration: ($) => seq(
      'import',
      optional(seq('as', $.identifier)),
      optional(seq('@', $.identifier)),
      optional(seq('as', $.identifier)),
      optional(seq(
        '{',
        commaSep(
          choice(
            $.identifier,
            seq($.identifier, 'as', $.identifier),
            seq($.identifier, ':', $.identifier),
          )
        ),
        '}'
      )),
    ),

    // --------------------------------------------------------------------
    // TOP-LEVEL DECLARATIONS
    // --------------------------------------------------------------------
    top_level_declaration: ($) => choice(
      $.function_declaration,
      $.value_declaration,
      $.type_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.trait_declaration,
      $.impl_block,
      $.suberror_declaration,
      $.extern_declaration,
      $.declare_declaration,
      $.attribute_decorator,
    ),

    // ---- FUNCTION ----
    function_declaration: ($) => prec.right(seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      optional('async'),
      'fn',
      field('name', $.identifier),
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      optional($.raises_clause),
      optional($.throws_marker),
      field('body', $.block),
    )),

    parameter_list: ($) => seq('(', commaSep($.parameter), ')'),

    parameter: ($) => seq(
      optional('mut'),
      field('label', optional($.identifier)),
      optional(seq($.identifier, ':')),
      field('type', optional($.type)),
      optional(seq('=', $.expression)),
    ),

    raises_clause: ($) => seq('raise', optional($.type)),

    throws_marker: ($) => 'noraise',

    // ---- VALUE ----
    value_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      choice('let', 'const'),
      optional('mut'),
      field('pattern', $.pattern),
      optional(seq(':', $.type)),
      optional(seq('=', $.expression)),
    ),

    // ---- TYPE ALIAS ----
    type_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'type',
      field('name', $.identifier),
      optional($.type_parameters),
      '=',
      field('type', $.type),
    ),

    // ---- STRUCT ----
    struct_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'struct',
      field('name', $.identifier),
      optional($.type_parameters),
      optional($.derive_clause),
      field('body', $.struct_field_list),
    ),

    struct_field_list: ($) => seq('{', commaSep($.struct_field), '}'),

    struct_field: ($) => seq(
      optional('priv'),
      optional('readonly'),
      field('name', $.identifier),
      ':',
      field('type', $.type),
      optional(seq('=', $.expression)),
    ),

    // ---- ENUM ----
    enum_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'enum',
      field('name', $.identifier),
      optional($.type_parameters),
      optional($.derive_clause),
      '{',
      commaSep1($.enum_variant),
      '}',
    ),

    enum_variant: ($) => seq(
      optional('priv'),
      optional($.attribute_list),
      field('name', $.identifier),
      optional($.variant_payload),
      optional(seq('=', $.integer_literal)),
    ),

    variant_payload: ($) => choice(
      $.type,
      seq('(', commaSep1($.type), ')'),
      $.struct_field_list,
    ),

    // ---- TRAIT ----
    trait_declaration: ($) => seq(
      optional('pub'),
      optional('open'),
      'trait',
      field('name', $.identifier),
      optional($.type_parameters),
      optional(seq('with', commaSep1(seq($.identifier, 'as', $.identifier)))),
      field('body', $.trait_item_list),
    ),

    trait_item_list: ($) => seq('{', repeat($.trait_item), '}'),

    trait_item: ($) => seq(
      optional($.attribute_list),
      optional('default'),
      'fn',
      field('name', $.identifier),
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      optional($.raises_clause),
      optional(seq('=', $.expression)),
    ),

    // ---- IMPL ----
    impl_block: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'impl',
      optional($.type_parameters),
      choice(
        seq($.identifier, 'for', $.type),
        seq($.identifier, 'as', $.identifier, 'for', $.type),
      ),
      field('body', $.impl_item_list),
    ),

    impl_item_list: ($) => seq('{', repeat($.impl_item), '}'),

    impl_item: ($) => seq(
      optional($.attribute_list),
      'fn',
      field('name', $.identifier),
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      optional($.raises_clause),
      field('body', $.block),
    ),

    // ---- SUBERROR ----
    suberror_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'suberror',
      field('name', $.identifier),
      optional($.type_parameters),
      choice(
        ';',  // suberror Foo;
        seq('{', optional(commaSep1($.enum_variant)), '}'),
      ),
    ),

    // ---- EXTERN ----
    extern_declaration: ($) => seq(
      'extern',
      optional(seq('"', $.identifier, '"')),
      'fn',
      field('name', $.identifier),
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      optional(seq('=', $.string_literal)),
    ),

    // ---- DECLARE ----
    declare_declaration: ($) => seq(
      optional($.visibility_modifier),
      optional($.attribute_list),
      'declare',
      'fn',
      field('name', $.identifier),
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      optional($.raises_clause),
    ),

    // --------------------------------------------------------------------
    // EXPRESSIONS
    // --------------------------------------------------------------------
    expression: ($) => choice(
      $.literal,
      $.identifier,
      $.unit_literal,
      $.tuple_literal,
      $.array_literal,
      $.struct_creation,
      $.struct_update,
      $.enum_creation,
      $.closure_expression,
      $.parenthesized_expression,
      $.if_expression,
      $.match_expression,
      $.guard_expression,
      $.while_expression,
      $.for_expression,
      $.break_expression,
      $.continue_expression,
      $.return_expression,
      $.assignment_expression,
      $.update_expression,
      $.compound_expression,
      $.try_expression,
      $.sequence_expression,
      $.await_expression,
      $.defer_expression,
      $.method_call,
      $.field_access,
      $.index_access,
      $.type_cast,
      $.is_check,
      $.unary_expression,
      $.binary_expression,
    ),

    literal: ($) => choice(
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.string_literal,
      $.raw_string_literal,
      $.interpolated_string_literal,
      $.char_literal,
      $.byte_literal,
      $.bytes_literal,
    ),

    integer_literal: ($) => token(/\d[\d_]*[uUlL]?|\d[\d_]*N/),

    float_literal: ($) => token(/[\d][\d_]*\.[\d][\d_]*([eE][+-]?[\d][\d_]*)?/),

    boolean_literal: ($) => choice('true', 'false'),

    unit_literal: ($) => "'()'",

    char_literal: ($) => token(/'[^']*'/),

    tuple_literal: ($) => seq('(', commaSep1($.expression), ')'),

    array_literal: ($) => seq('[', commaSep($.expression), ']'),

    // struct creation: TypeName { field: value }
    struct_creation: ($) => seq(
      field('type', $.type_identifier),
      optional(seq('::', 'new')),
      '{',
      commaSep(choice(
        seq(field('name', $.identifier), ':', field('value', $.expression)),
        seq('..', field('spread', $.expression)),
      )),
      '}',
    ),

    // struct update: { ..old, field: new }
    struct_update: ($) => seq(
      '{',
      '..',
      field('base', $.expression),
      optional(seq(',', commaSep(
        seq(field('name', $.identifier), ':', field('value', $.expression)),
      ))),
      '}',
    ),

    // enum creation: EnumName::Variant(args) or EnumName::Variant(label=val)
    enum_creation: ($) => seq(
      field('enum', $.identifier),
      '::',
      field('variant', $.identifier),
      optional(seq('(', commaSep($.expression), ')')),
    ),

    closure_expression: ($) => seq(
      optional($.type_parameters),
      field('parameters', $.parameter_list),
      optional(seq('->', $.type)),
      '=>',
      field('body', $.expression),
    ),

    parenthesized_expression: ($) => seq('(', $.expression, ')'),

    // ---- CONTROL FLOW ----
    if_expression: ($) => seq(
      'if',
      optional('let'),
      field('condition', $.pattern),
      optional(seq('=', $.expression)),
      field('consequence', $.block),
      optional(seq('else', field('alternative', choice($.block, $.if_expression)))),
    ),

    match_expression: ($) => seq(
      'match',
      field('value', $.expression),
      '{',
      repeat1(seq(
        field('pattern', $.pattern),
        optional(seq('if', $.expression)),
        '=>',
        field('body', $.expression),
      )),
      '}',
    ),

    guard_expression: ($) => seq(
      'guard',
      field('value', $.expression),
      'is',
      field('pattern', $.pattern),
      optional(seq('=', $.expression)),
      'else',
      field('block', $.block),
    ),

    while_expression: ($) => seq(
      'while',
      field('condition', $.expression),
      field('body', $.block),
    ),

    for_expression: ($) => seq(
      'for',
      field('pattern', $.pattern),
      'in',
      field('iterable', $.expression),
      field('body', $.block),
    ),

    break_expression: ($) => seq('break', optional($.expression)),

    continue_expression: ($) => seq('continue'),

    return_expression: ($) => seq('return', optional($.expression)),

    // ---- ASSIGNMENT ----
    assignment_expression: ($) => seq(
      field('left', $.expression),
      '=',
      field('right', $.expression),
    ),

    update_expression: ($) => choice(
      seq($.expression, '+=', $.expression),
      seq($.expression, '-=', $.expression),
      seq($.expression, '*=', $.expression),
      seq($.expression, '/=', $.expression),
      seq($.expression, '%=', $.expression),
      seq($.expression, '<<=', $.expression),
      seq($.expression, '>>=', $.expression),
      seq($.expression, '&=', $.expression),
      seq($.expression, '|=', $.expression),
      seq($.expression, '^=', $.expression),
    ),

    compound_expression: ($) => seq('{', $.block, '}'),

    block: ($) => seq(
      repeat(seq($.expression, ';')),
      optional($.expression),
    ),

    // ---- ERROR HANDLING ----
    try_expression: ($) => seq(
      'try',
      field('body', $.block),
      optional(seq('catch', '{', repeat1($.catch_clause), '}')),
      optional(seq('noraise', '{', $.expression, '}')),
    ),

    catch_clause: ($) => seq(
      field('pattern', $.pattern),
      optional(seq('=', $.identifier)),
      '=>',
      field('body', $.expression),
    ),

    // ---- ASYNC ----
    await_expression: ($) => seq('await', $.expression),

    // ---- DEFER ----
    defer_expression: ($) => seq('defer', $.expression),

    // ---- FUNCTION/METHOD CALL ----
    method_call: ($) => seq(
      field('object', $.expression),
      optional(seq('as', $.identifier)),  // as_free_fn
      '.',
      field('method', $.identifier),
      optional(seq('(', commaSep($.expression), ')')),
    ),

    field_access: ($) => seq(
      field('object', $.expression),
      '.',
      field('field', $.identifier),
    ),

    index_access: ($) => seq(
      field('object', $.expression),
      '[',
      field('index', $.expression),
      ']',
    ),

    // ---- TYPE OPERATORS ----
    type_cast: ($) => seq(
      field('value', $.expression),
      'as',
      field('type', $.type),
    ),

    is_check: ($) => seq(
      field('value', $.expression),
      'is',
      field('pattern', $.pattern),
    ),

    // ---- UNARY ----
    unary_expression: ($) => prec.right(seq(
      choice('!', '-', 'not'),
      field('operand', $.expression),
    )),

    // ---- BINARY ----
    binary_expression: ($) => {
      const table = [
        ['||', 'or'],
        ['&&', 'and'],
        ['==', '!=', '<', '>', '<=', '>='],
        ['+', '-', '|'],
        ['*', '/', '%', '&'],
        ['<<', '>>'],
        ['^'],
      ];
      return table.map((ops) => {
        if (ops.length === 1) {
          return prec.left(seq($.expression, ops[0], $.expression));
        }
        return prec.left(...ops.map((op) => seq($.expression, op, $.expression)));
      });
    },

    // ---- SEQUENCE ----
    sequence_expression: ($) => seq('(', repeat1($.expression), ')'),

    // --------------------------------------------------------------------
    // PATTERNS
    // --------------------------------------------------------------------
    pattern: ($) => choice(
      $.wildcard_pattern,
      $.literal_pattern,
      $.identifier_pattern,
      $.rest_pattern,
      $.constructor_pattern,
      $.tuple_pattern,
      $.array_pattern,
      $.range_pattern,
      $.guarded_pattern,
      $.or_pattern,
    ),

    wildcard_pattern: ($) => '_',

    literal_pattern: ($) => choice(
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.string_literal,
    ),

    identifier_pattern: ($) => seq(
      optional('mut'),
      $.identifier,
      optional(seq('=', $.expression)),
    ),

    rest_pattern: ($) => seq('..', optional($.identifier)),

    constructor_pattern: ($) => seq(
      optional(seq($.identifier, '::')),
      $.identifier,
      optional(seq('(', commaSep($.pattern), ')')),
    ),

    tuple_pattern: ($) => seq('(', commaSep1($.pattern), ')'),

    array_pattern: ($) => seq('[', commaSep(choice($.pattern, $.rest_pattern)), ']'),

    range_pattern: ($) => seq($.integer_literal, '..', optional($.integer_literal)),

    guarded_pattern: ($) => seq($.pattern, 'if', $.expression),

    or_pattern: ($) => seq($.pattern, '|', $.pattern),

    // --------------------------------------------------------------------
    // TYPES
    // --------------------------------------------------------------------
    type: ($) => choice(
      $.builtin_type,
      $.type_identifier,
      $.generic_type,
      $.function_type,
      $.tuple_type,
      $.array_type,
      $.option_type,
      $.result_type,
      $.reference_type,
      $.external_type,
    ),

    builtin_type: ($) => token(choice(
      'Int', 'UInt', 'Int64', 'UInt64', 'Float', 'Double',
      'Bool', 'Char', 'Byte', 'Unit', 'String', 'Bytes',
      'Int8', 'Int16', 'Int32', 'Int128',
      'UInt8', 'UInt16', 'UInt32', 'UInt128',
      'BigInt',
    )),

    type_identifier: ($) => alias(/[A-Z][\w]*/, 'type_identifier'),

    generic_type: ($) => seq(
      field('name', $.type_identifier),
      '[',
      commaSep1($.type),
      ']',
    ),

    function_type: ($) => seq(
      '(',
      commaSep($.type),
      ')',
      '->',
      $.type,
      optional($.raises_clause),
    ),

    tuple_type: ($) => seq('(', commaSep1($.type), ')'),

    array_type: ($) => choice(
      seq('Array', '[', $.type, ']'),
      seq('FixedArray', '[', $.type, ']'),
      seq('ArrayView', '[', $.type, ']'),
      seq('MutArrayView', '[', $.type, ']'),
      seq('ReadOnlyArray', '[', $.type, ']'),
    ),

    option_type: ($) => seq($.type, '?'),

    result_type: ($) => seq('Result', '[', $.type, ',', $.type, ']'),

    reference_type: ($) => seq('&', $.type_identifier),

    external_type: ($) => seq('#', 'external', 'type', $.type_identifier),

    type_parameters: ($) => seq('[', commaSep1(seq(
      $.identifier,
      optional(seq(':', $.identifier)),
    )), ']'),

    // --------------------------------------------------------------------
    // ATTRIBUTES
    // --------------------------------------------------------------------
    attribute_list: ($) => repeat1($.attribute_decorator),

    attribute_decorator: ($) => seq(
      '#',
      field('name', $.identifier),
      optional(seq('(', commaSep($.attribute_argument), ')')),
    ),

    attribute_argument: ($) => choice(
      $.string_literal,
      $.boolean_literal,
      $.identifier,
      seq($.identifier, '=', $.expression),
    ),

    // --------------------------------------------------------------------
    // MODIFIERS
    // --------------------------------------------------------------------
    visibility_modifier: ($) => choice('pub', 'priv'),

    derive_clause: ($) => seq('derive', '(', commaSep1($.identifier), ')'),

    // --------------------------------------------------------------------
    // COMMENTS
    // --------------------------------------------------------------------
    line_comment: ($) => token(seq('//', /[^\n]*/)),

    block_comment: ($) => token(seq('/*', /[^*]*\*+(?:[^/*][^*]*\*+)*/, '/')),

    // --------------------------------------------------------------------
    // IDENTIFIER
    // --------------------------------------------------------------------
    identifier: ($) => /[\w]+/,
  },
});

// --------------------------------------------------------------------
// HELPER FUNCTIONS
// --------------------------------------------------------------------
function seq(...rules) {
  return { type: 'SEQ', rules: rules };
}

function choice(...rules) {
  return { type: 'CHOICE', rules: rules };
}

function repeat(rule) {
  return { type: 'REPEAT', rule: rule };
}

function repeat1(rule) {
  return { type: 'REPEAT1', rule: rule };
}

function optional(...rules) {
  return { type: 'OPTIONAL', rules: rules };
}

function alias(rule, name) {
  return { type: 'ALIAS', rule: rule, name: name };
}

function token(pattern) {
  return { type: 'TOKEN', pattern: pattern };
}

function sep1(rule, separator) {
  return { type: 'CHOICE', rules: [seq(rule, repeat(seq(separator, rule))] };
}

function commaSep(rule) {
  return { type: 'CHOICE', rules: [seq(rule, repeat(seq(',', rule))), { type: 'BLANK' }] };
}

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

function prec(direction, rule) {
  return { type: 'PREC', direction, rule };
}

function prec.left(...rules) {
  return { type: 'PREC', direction: 'LEFT', rule: seq(...rules) };
}

function prec.right(...rules) {
  return { type: 'PREC', direction: 'RIGHT', rule: seq(...rules) };
}