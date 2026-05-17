// MoonHighlight 鈥?Tree-sitter Grammar for MoonBit
// Phase 1: Lexer Foundation (keywords, identifiers, literals, comments, operators)
//
// Reference:
//   - MoonBit Language Specification v0.9.2: https://docs.moonbitlang.cn/
//   - tree-sitter-rust (best practice reference): https://github.com/tree-sitter/tree-sitter-rust

module.exports = grammar({
  name: 'moonbit',

  conflicts: ($) => [
    [$.ident_pattern, $.constructor_pattern],
    [$.import_declaration, $.import_from_declaration],
    [$.expression, $.type_param],
    [$.fn_type, $.option_type],
    [$.tuple_expr, $.paren_expr],
    [$.enum_expr],
    [$.named_type, $.generic_type],
    [$.expression, $.arg],
    [$.field_access, $.method_call],
    [$.variant_field, $.tuple_type, $.fn_type],
    [$.raises_clause, $.option_type],
    [$.fn_type],
    [$.constructor_pattern],
    [$.raises_clause],
    [$.range_pattern],
  ],

  extras: ($) => [
    $.line_comment,
    $.block_comment,
    /\s/,
  ],

  word: ($) => $.identifier,

  externals: ($) => [
    // Complex string literals handled by external scanner (scanner.c)
    $.string_literal,
    $.raw_string_literal,
    $.interpolated_string_literal,
    $.byte_literal,
    $.bytes_literal,
  ],

  supertypes: ($) => [
    $.expression,
    $.declaration,
    $.pattern,
    $.type,
  ],

  inline: ($) => [
  ],

  rules: {

    //======================================================================
    // SOURCE FILE 鈥?Entry point
    //======================================================================
    source_file: ($) => seq(
      optional($.shebang),
      optional($.package_clause),
      repeat($._import_item),
      repeat($.declaration),
    ),

    shebang: ($) => /#!.*/,

    package_clause: ($) => seq(
      'package',
      field('name', $.package_name),
    ),

    package_name: ($) => /[a-zA-Z_][\w\-]*(\/[a-zA-Z_][\w\-]*)*/,

    _import_item: ($) => choice(
      $.import_declaration,
      $.import_from_declaration,
    ),

    import_declaration: ($) => seq(
      'import',
      field('path', $.package_name),
      optional(seq('as', field('alias', $.identifier))),
    ),

    import_from_declaration: ($) => seq(
      'import',
      optional(seq('@', field('source', $.identifier))),
      field('path', $.package_name),
      'as',
      field('alias', $.identifier),
      optional(seq('{', commaSep1($.import_member), '}')),
    ),

    import_member: ($) => choice(
      field('name', $.identifier),
      seq(field('name', $.identifier), 'as', field('alias', $.identifier)),
    ),

    //======================================================================
    // DECLARATIONS 鈥?Top-level items
    //======================================================================
    declaration: ($) => choice(
      $.function_declaration,
      $.value_declaration,
      $.type_alias_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.trait_declaration,
      $.impl_block,
      $.suberror_declaration,
      $.extern_fn_declaration,
      $.declare_fn_declaration,
    ),

    //----------------------------------------------------------------------
    // Function declaration
    //----------------------------------------------------------------------
    function_declaration: ($) => prec.right(seq(
      repeat($.attribute),
      optional($.visibility),
      optional('async'),
      'fn',
      field('name', $.identifier),
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      optional($.raises_clause),
      optional('noraise'),
      field('body', $.block_expr),
    )),

    param_list: ($) => seq('(', commaSep($.param), ')'),

    param: ($) => seq(
      optional('mut'),
      field('name', $.identifier),
      ':',
      field('type', $.type),
      optional(seq('=', field('default', $.expression))),
    ),

    raises_clause: ($) => seq('raises', optional(field('type', $.type))),

    //----------------------------------------------------------------------
    // Value declaration (let / const)
    //----------------------------------------------------------------------
    value_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      choice('let', 'const'),
      optional('mut'),
      field('pattern', $.pattern),
      optional(seq(':', field('type', $.type))),
      optional(seq('=', field('value', $.expression))),
    ),

    //----------------------------------------------------------------------
    // Type alias
    //----------------------------------------------------------------------
    type_alias_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'type',
      field('name', $.identifier),
      optional($.type_params),
      '=',
      field('alias', $.type),
    ),

    //----------------------------------------------------------------------
    // Struct declaration
    //----------------------------------------------------------------------
    struct_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'struct',
      field('name', $.identifier),
      optional($.type_params),
      optional($.derive_clause),
      '{',
      commaSep($.field_def),
      '}',
    ),

    field_def: ($) => seq(
      optional(choice('priv', 'pub')),
      optional('readonly'),
      field('name', $.identifier),
      ':',
      field('type', $.type),
      optional(seq('=', field('default', $.expression))),
    ),

    derive_clause: ($) => seq('derive', '(', commaSep1($.identifier), ')'),

    //----------------------------------------------------------------------
    // Enum declaration
    //----------------------------------------------------------------------
    enum_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'enum',
      field('name', $.identifier),
      optional($.type_params),
      optional($.derive_clause),
      '{',
      commaSep($.enum_variant),
      '}',
    ),

    enum_variant: ($) => seq(
      optional(choice('priv', 'pub')),
      repeat($.attribute),
      field('name', $.identifier),
      optional($.variant_payload),
      optional(seq('=', field('discriminator', $.integer_literal))),
    ),

    variant_payload: ($) => choice(
      field('type', $.type),
      seq('(', commaSep1($.variant_field), ')'),
      seq('{', commaSep($.field_def), '}'),
    ),

    variant_field: ($) => seq(
      optional(field('label', $.identifier)),
      field('type', $.type),
    ),

    //----------------------------------------------------------------------
    // Trait declaration
    //----------------------------------------------------------------------
    trait_declaration: ($) => seq(
      optional('pub'),
      optional('open'),
      'trait',
      field('name', $.identifier),
      optional($.type_params),
      optional($.super_traits),
      '{',
      repeat($.trait_method),
      '}',
    ),

    super_traits: ($) => seq(
      'with',
      commaSep1($.trait_bound),
    ),

    trait_bound: ($) => seq(
      field('trait', $.identifier),
      optional(seq('as', field('alias', $.identifier))),
    ),

    trait_method: ($) => seq(
      repeat($.attribute),
      optional('default'),
      'fn',
      field('name', $.identifier),
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      optional($.raises_clause),
      optional(seq('=', field('body', $.expression))),
    ),

    //----------------------------------------------------------------------
    // Impl block
    //----------------------------------------------------------------------
    impl_block: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'impl',
      optional($.type_params),
      choice(
        seq(field('trait', $.identifier), 'for', field('self_type', $.type)),
        seq(field('trait', $.identifier), 'as', field('alias', $.identifier), 'for', field('self_type', $.type)),
        field('self_type', $.type),
      ),
      '{',
      repeat($.impl_method),
      '}',
    ),

    impl_method: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'fn',
      field('name', $.identifier),
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      optional($.raises_clause),
      field('body', $.block_expr),
    ),

    //----------------------------------------------------------------------
    // Suberror declaration
    //----------------------------------------------------------------------
    suberror_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'suberror',
      field('name', $.identifier),
      optional($.type_params),
      choice(';', seq('{', optional(commaSep($.enum_variant)), '}')),
    ),

    //----------------------------------------------------------------------
    // Extern function
    //----------------------------------------------------------------------
    extern_fn_declaration: ($) => seq(
      'extern',
      optional($.string_literal),
      'fn',
      field('name', $.identifier),
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      optional(seq('=', field('body', $.string_literal))),
    ),

    //----------------------------------------------------------------------
    // Declare function (signature only)
    //----------------------------------------------------------------------
    declare_fn_declaration: ($) => seq(
      repeat($.attribute),
      optional($.visibility),
      'declare',
      'fn',
      field('name', $.identifier),
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      optional($.raises_clause),
    ),

    //======================================================================
    // EXPRESSIONS
    //======================================================================
    expression: ($) => choice(
      // Literals
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.char_literal,
      $.string_literal,
      $.raw_string_literal,
      $.interpolated_string_literal,
      $.byte_literal,
      $.bytes_literal,

      // Compound literals
      $.unit_literal,
      $.tuple_expr,
      $.array_expr,
      $.struct_expr,
      $.enum_expr,

      // Identifiers & access
      $.identifier,
      $.field_access,
      $.method_call,
      $.index_access,

      // Function-like
      $.call_expr,
      $.closure_expr,
      $.pipeline_expr,

      // Control flow
      $.if_expr,
      $.match_expr,
      $.guard_expr,
      $.while_expr,
      $.for_expr,
      $.loop_expr,
      $.break_expr,
      $.continue_expr,
      $.return_expr,
      $.raise_expr,

      // Error handling
      $.try_expr,

      // Async
      $.await_expr,
      $.defer_expr,

      // Type operations
      $.cast_expr,
      $.is_expr,

      // Assignment & update
      $.assign_expr,
      $.update_expr,

      // Unary & binary
      $.unary_expr,
      $.binary_expr,

      // Grouping
      $.paren_expr,
      $.block_expr,
    ),

    //----------------------------------------------------------------------
    // Literals
    //----------------------------------------------------------------------
    integer_literal: ($) => {
      const digits = /[0-9][0-9_]*/;
      const hex = /0[xX][0-9a-fA-F_]+/;
      const oct = /0[oO][0-7_]+/;
      const bin = /0[bB][01_]+/;
      return token(choice(
        hex, oct, bin, digits,
        seq(digits, /[uU]/),
        seq(digits, /[lL]/),
        seq(digits, /[iI][0-9]?[0-9]?/),
        seq(hex, /[uU]/),
      ));
    },

    float_literal: ($) => token(choice(
      /\d[\d_]*\.\d[\d_]*([eE][+-]?\d[\d_]*)?/,
      /\d[\d_]*([eE][+-]?\d[\d_]*)/,
      /0[xX][0-9a-fA-F_]+\.[0-9a-fA-F_]*([pP][+-]?\d[\d_]*)?/,
    )),

    boolean_literal: ($) => choice('true', 'false'),

    char_literal: ($) => token(/'[^'\\]|'\\.'|'\\x[0-9a-fA-F]{2}'|'\\u\{[0-9a-fA-F]+\}'/),

    unit_literal: ($) => "'()'",

    //----------------------------------------------------------------------
    // Compound expressions
    //----------------------------------------------------------------------
    tuple_expr: ($) => seq('(', commaSep1($.expression), ')'),

    array_expr: ($) => seq('[', commaSep($.expression), ']'),

    struct_expr: ($) => seq(
      field('type', $.type_identifier),
      optional(seq('::', 'new')),
      '{',
      commaSeq(choice(
        seq(field('name', $.identifier), ':', field('value', $.expression)),
        seq('..', field('base', $.expression)),
      )),
      '}',
    ),

    enum_expr: ($) => seq(
      field('enum_type', $.type_identifier),
      '::',
      field('variant', $.identifier),
      optional(seq('(', commaSep($.expression), ')')),
    ),

    //----------------------------------------------------------------------
    // Access & call
    //----------------------------------------------------------------------
    field_access: ($) => prec.left(seq(
      field('object', $.expression),
      '.',
      field('field', $.identifier),
    )),

    method_call: ($) => prec.left(seq(
      field('object', $.expression),
      '.',
      field('method', $.identifier),
      optional(seq('(', commaSep($.expression), ')')),
    )),

    index_access: ($) => prec.left(seq(
      field('object', $.expression),
      '[',
      field('index', $.expression),
      ']',
    )),

    call_expr: ($) => prec.left(seq(
      field('func', $.expression),
      '(',
      commaSep($.arg),
      ')',
    )),

    arg: ($) => choice(
      field('value', $.expression),
      seq(field('label', $.identifier), '=', field('value', $.expression)),
    ),

    closure_expr: ($) => prec.right(1, seq(
      optional($.type_params),
      field('params', $.param_list),
      optional(seq('->', field('return_type', $.type))),
      '=>',
      field('body', $.expression),
    )),

    pipeline_expr: ($) => prec.left(seq(
      field('value', $.expression),
      '|>',
      field('func', $.expression),
    )),

    //----------------------------------------------------------------------
    // Control flow
    //----------------------------------------------------------------------
    if_expr: ($) => prec.right(seq(
      'if',
      optional('let'),
      field('condition', $.pattern),
      optional(seq('=', field('test', $.expression))),
      field('consequence', $.block_expr),
      optional(seq('else', field('alternative', choice($.block_expr, $.if_expr)))),
    )),

    match_expr: ($) => seq(
      'match',
      field('scrutinee', $.expression),
      '{',
      repeat($.match_arm),
      '}',
    ),

    match_arm: ($) => prec.right(1, seq(
      field('pattern', $.pattern),
      optional(seq('if', field('guard', $.expression))),
      '=>',
      field('body', $.expression),
    )),

    guard_expr: ($) => seq(
      'guard',
      field('value', $.expression),
      'is',
      field('pattern', $.pattern),
      optional(seq('=', field('bind', $.expression))),
      'else',
      field('fallback', $.block_expr),
    ),

    while_expr: ($) => seq(
      'while',
      field('condition', $.expression),
      field('body', $.block_expr),
    ),

    for_expr: ($) => seq(
      'for',
      field('pattern', $.pattern),
      'in',
      field('iterable', $.expression),
      field('body', $.block_expr),
    ),

    loop_expr: ($) => seq(
      'loop',
      field('body', $.block_expr),
    ),

    break_expr: ($) => prec.right(1, seq('break', optional($.expression))),

    continue_expr: ($) => 'continue',

    return_expr: ($) => prec.right(1, seq('return', optional($.expression))),

    raise_expr: ($) => prec.right(1, seq('raise', $.expression)),

    //----------------------------------------------------------------------
    // Error handling
    //----------------------------------------------------------------------
    try_expr: ($) => seq(
      'try',
      field('body', $.block_expr),
      optional(seq('catch', '{', repeat1($.catch_arm), '}')),
      optional(seq('noraise', '{', $.expression, '}')),
    ),

    catch_arm: ($) => prec.right(1, seq(
      field('pattern', $.pattern),
      optional(seq('=', field('bind', $.identifier))),
      '=>',
      field('handler', $.expression),
    )),

    //----------------------------------------------------------------------
    // Async
    //----------------------------------------------------------------------
    await_expr: ($) => prec.right(seq('await', $.expression)),

    defer_expr: ($) => prec.right(1, seq('defer', $.expression)),

    //----------------------------------------------------------------------
    // Type operations
    //----------------------------------------------------------------------
    cast_expr: ($) => prec.left(seq(
      field('value', $.expression),
      'as',
      field('type', $.type),
    )),

    is_expr: ($) => prec.left(seq(
      field('value', $.expression),
      'is',
      field('pattern', $.pattern),
    )),

    //----------------------------------------------------------------------
    // Assignment & update
    //----------------------------------------------------------------------
    assign_expr: ($) => prec.left(seq(
      field('left', $.expression),
      '=',
      field('right', $.expression),
    )),

    update_expr: ($) => prec.left(seq(
      field('left', $.expression),
      choice('+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '&=', '|=', '^='),
      field('right', $.expression),
    )),

    //----------------------------------------------------------------------
    // Unary & binary operators
    //----------------------------------------------------------------------
    unary_expr: ($) => prec.right(choice(
      seq('-', field('operand', $.expression)),
      seq('!', field('operand', $.expression)),
      seq('not', field('operand', $.expression)),
    )),

    binary_expr: ($) => {
      const table = [
        ['or', '||'],
        ['and', '&&'],
        ['==', '!=', '<', '>', '<=', '>='],
        ['|'],
        ['^'],
        ['&'],
        ['<<', '>>'],
        ['+', '-'],
        ['*', '/', '%'],
      ];
      return choice(...table.map(([first, ...rest]) =>
        prec.left(seq(
          field('left', $.expression),
          first,
          ...rest.map(op => op),
          field('right', $.expression),
        ))
      ));
    },

    paren_expr: ($) => seq('(', $.expression, ')'),

    block_expr: ($) => seq(
      '{',
      repeat(seq($.expression, ';')),
      optional($.expression),
      '}',
    ),

    //======================================================================
    // PATTERNS
    //======================================================================
    pattern: ($) => choice(
      $.wildcard_pattern,
      $.literal_pattern,
      $.ident_pattern,
      $.constructor_pattern,
      $.tuple_pattern,
      $.array_pattern,
      $.range_pattern,
      $.or_pattern,
      $.guarded_pattern,
    ),

    wildcard_pattern: ($) => '_',

    literal_pattern: ($) => choice(
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.char_literal,
      $.string_literal,
    ),

    ident_pattern: ($) => seq(optional('mut'), field('name', $.identifier)),

    constructor_pattern: ($) => seq(
      optional(seq(field('enum_type', $.type_identifier), '::')),
      field('variant', $.identifier),
      optional(seq('(', commaSep($.pattern), ')')),
    ),

    tuple_pattern: ($) => seq('(', commaSep1($.pattern), ')'),

    array_pattern: ($) => seq('[', commaSep(choice($.pattern, $.rest_pattern)), ']'),

    rest_pattern: ($) => seq('..', optional(field('name', $.identifier))),

    range_pattern: ($) => seq(
      field('start', $.integer_literal),
      '..',
      optional(field('end', $.integer_literal)),
    ),

    or_pattern: ($) => prec.left(seq(field('left', $.pattern), '|', field('right', $.pattern))),

    guarded_pattern: ($) => prec.right(1, seq(field('pattern', $.pattern), 'if', field('condition', $.expression))),

    //======================================================================
    // TYPES
    //======================================================================
    type: ($) => choice(
      $.builtin_type,
      $.named_type,
      $.generic_type,
      $.tuple_type,
      $.fn_type,
      $.array_type,
      $.option_type,
      $.result_type,
      $.ref_type,
      $.external_type,
    ),

    builtin_type: ($) => token(choice(
      'Int', 'UInt', 'Int64', 'UInt64', 'Int32', 'UInt32',
      'Int16', 'UInt16', 'Int8', 'UInt8', 'Int128', 'UInt128',
      'Float', 'Double', 'BigInt',
      'Bool', 'Char', 'Byte', 'Unit', 'String', 'Bytes',
    )),

    named_type: ($) => $.type_identifier,

    generic_type: ($) => seq(field('name', $.type_identifier), '[', commaSep1($.type), ']'),

    tuple_type: ($) => seq('(', commaSep1($.type), ')'),

    fn_type: ($) => seq(
      '(',
      commaSep($.type),
      ')',
      '->',
      field('ret', $.type),
      optional($.raises_clause),
    ),

    array_type: ($) => choice(
      seq('Array', '[', $.type, ']'),
      seq('FixedArray', '[', $.type, ']'),
      seq('ArrayView', '[', $.type, ']'),
      seq('MutArrayView', '[', $.type, ']'),
      seq('ReadOnlyArray', '[', $.type, ']'),
    ),

    option_type: ($) => seq($.type, '?'),

    result_type: ($) => seq('Result', '[', $.type, ',', $.type, ']'),

    ref_type: ($) => seq('&', $.type_identifier),

    external_type: ($) => seq('#external', 'type', $.type_identifier),

    type_identifier: ($) => /[A-Z][\w]*/,

    type_params: ($) => seq('[', commaSep1($.type_param), ']'),

    type_param: ($) => seq(
      field('name', $.identifier),
      optional(seq(':', field('bound', $.identifier))),
    ),

    //======================================================================
    // ATTRIBUTES
    //======================================================================
    attribute: ($) => seq(
      '#[',
      field('name', $.identifier),
      optional(seq('(', commaSep($.attr_arg), ')')),
      ']',
    ),

    attr_arg: ($) => choice(
      $.string_literal,
      $.boolean_literal,
      $.identifier,
      seq(field('key', $.identifier), '=', field('val', $.expression)),
    ),

    visibility: ($) => choice('pub', 'priv'),

    //======================================================================
    // COMMENTS
    //======================================================================
    line_comment: ($) => token(prec(-1, seq('//', /[^\n]*/))),

    block_comment: ($) => token(prec(-1, seq('/*', /[^*]*\*+(?:[^/*][^*]*\*+)*/, '/'))),

    //======================================================================
    // IDENTIFIER
    //======================================================================
    identifier: ($) => /[a-zA-Z_][\w]*/,

    //======================================================================
    // OPERATORS (for highlighting)
    //======================================================================
    _operator: ($) => choice(
      '+', '-', '*', '/', '%',
      '==', '!=', '<', '>', '<=', '>=',
      '&&', '||', '!',
      '&', '|', '^', '~',
      '<<', '>>',
      '..', '...', '..<',
      '=>', '->', '::',
      '|>', '$',
      '@',
    ),
  },
});

//======================================================================
// HELPER FUNCTIONS
//======================================================================

function commaSep(rule) {
  return optional(commaSep1(rule));
}

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

function commaSeq(rule) {
  return optional(commaSeq1(rule));
}

function commaSeq1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}
