// MoonHighlight — Tree-sitter Grammar for MoonBit
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Tino-hue (肖若愚)
//
// Complete grammar definition for MoonBit v0.9.2 syntax.
// Supports: declarations, expressions, control flow, pattern matching,
// types, generics, async, error handling, string interpolation, and more.

// ==================== 辅助函数 ====================
function commaSep(rule) {
  return optional(commaSep1(rule));
}

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

function commaSep2(rule) {
  return seq(rule, ',', commaSep1(rule));
}

function sep1(sep, rule) {
  return seq(rule, repeat(seq(sep, rule)));
}

// ==================== 优先级常量 ====================
const PREC = {
  OR: 1,
  AND: 2,
  EQ: 3,
  CMP: 4,
  BOR: 5,
  BXOR: 6,
  BAND: 7,
  SHIFT: 8,
  RANGE: 8,
  ADD: 9,
  MUL: 10,
  POW: 11,
  UNARY: 12,
  CALL: 13,
  FIELD: 14,
  PIPE: 5,
  ASSIGN: 1,
  FN_TYPE: 1,
  BREAK: 1,
  CONTINUE: 1,
  RETURN: 1,
  RAISE: 1,
};

const OR = PREC.OR;
const AND = PREC.AND;
const EQ = PREC.EQ;
const CMP = PREC.CMP;
const BOR = PREC.BOR;
const BXOR = PREC.BXOR;
const BAND = PREC.BAND;
const SHIFT = PREC.SHIFT;
const RANGE = PREC.RANGE;
const ADD = PREC.ADD;
const MUL = PREC.MUL;
const POW = PREC.POW;
const UNARY = PREC.UNARY;
const CALL = PREC.CALL;
const FIELD = PREC.FIELD;
const PIPE = PREC.PIPE;
const ASSIGN = PREC.ASSIGN;
const FN_TYPE = PREC.FN_TYPE;
const BREAK = PREC.BREAK;
const CONTINUE = PREC.CONTINUE;
const RETURN = PREC.RETURN;
const RAISE = PREC.RAISE;

// ==================== Grammar ====================
module.exports = grammar({
  name: 'moonbit',
  word: $ => $.identifier,

  externals: $ => [],

  extras: $ => [
    $.comment,
    /\s/,
  ],

  conflicts: $ => [
    [$._expression, $.function_call],
    [$.struct_expr],
    [$.method_call, $.field_access, $.closure_expr],
    [$.index_access, $.closure_expr],
    [$.method_call, $.field_access, $.try_expr],
    [$.index_access, $.try_expr],
    [$.method_call, $.field_access, $.defer_expr],
    [$.index_access, $.defer_expr],
    [$.try_expr],
    [$.method_call, $.field_access],
    [$.method_call, $.field_access, $.continue_args],
    [$.index_access, $.continue_args],
    [$.index_access, $.match_arm],
    [$.if_expr],
    [$.tuple_type],
    [$._expression, $.match_arm],
    [$.import_declaration],
    [$.struct_declaration],
    [$._type],
  ],

  rules: {
    // ==================== 顶层规则 ====================
    source_file: $ => repeat(choice($.declaration, $.value_declaration)),

    declaration: $ => choice(
      $.package_clause,
      $.import_declaration,
      $.function_declaration,
      $.extern_fn_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.suberror_declaration,
      $.trait_declaration,
      $.impl_block,
      $.type_alias,
      $.test_declaration,
    ),

    // ==================== 包和导入 ====================
    package_clause: $ => seq(
      'package',
      $.qualified_name,
    ),

    import_declaration: $ => seq(
      'import',
      $.qualified_name,
      optional(seq('as', choice($.identifier, $.type_identifier))),
      optional(seq(
        '{',
        commaSep1(choice($.identifier, $.type_identifier)),
        '}',
      )),
    ),

    qualified_name: $ => prec.left(1, sep1(choice('.', '/'), $.identifier)),

    package_access: $ => seq('@', $.qualified_name),

    // ==================== 函数声明 ====================
    function_declaration: $ => seq(
      repeat($.attribute),
      optional($.visibility),
      optional('async'),
      'fn',
      $.identifier,
      optional($.type_parameters),
      optional($.param_list),
      optional(seq('->', $._type)),
      optional($.error_type),
      $.block_expr,
    ),

    extern_fn_declaration: $ => seq(
      optional($.visibility),
      'extern',
      $.string_literal,
      'fn',
      $.identifier,
      $.param_list,
      optional(seq('->', $._type)),
      '=',
      choice($.string_literal, $.identifier),
    ),

    visibility: $ => choice(
      seq('pub', optional(seq('(', choice('all', 'readonly', 'open'), ')'))),
      'priv',
    ),

    attribute: $ => seq(
      '#[',
      $.identifier,
      optional(seq(
        '(',
        commaSep($.attr_arg),
        ')',
      )),
      ']',
    ),

    attr_arg: $ => choice(
      $.identifier,
      $.type_identifier,
      seq(choice($.identifier, $.type_identifier), '=', choice($.string_literal, $.number_literal, $.identifier, $.type_identifier)),
    ),

    type_parameters: $ => seq(
      '[',
      commaSep1($.type_parameter),
      ']',
    ),

    type_parameter: $ => seq(
      choice($.identifier, $.type_identifier),
      optional(seq(':', $.type_constraint)),
    ),

    type_constraint: $ => seq(
      optional('?'),
      $.type_identifier,
    ),

    param_list: $ => seq(
      '(',
      commaSep($.param),
      ')',
    ),

    param: $ => choice(
      $.self_param,
      seq(
        optional('~'),
        $.identifier,
        optional('?'),
        optional(seq(':', $._type)),
        optional(seq('=', $._expression)),
      ),
    ),

    self_param: $ => seq(
      optional('mut'),
      'self',
    ),

    // ==================== 结构体 ====================
    struct_declaration: $ => seq(
      repeat($.attribute),
      optional($.visibility),
      'struct',
      $.type_identifier,
      optional($.type_parameters),
      optional(seq('(', commaSep($.struct_field), ')')),
      optional(seq('{', repeat($.field_def), '}')),
      optional($.derive_clause),
    ),

    struct_field: $ => seq(
      $.identifier,
      ':',
      $._type,
    ),

    field_def: $ => seq(
      optional($.visibility),
      $.identifier,
      ':',
      $._type,
    ),

    // ==================== 枚举 ====================
    enum_declaration: $ => seq(
      repeat($.attribute),
      optional($.visibility),
      'enum',
      $.type_identifier,
      optional($.type_parameters),
      '{',
      repeat($.enum_variant),
      '}',
      optional($.derive_clause),
    ),

    suberror_declaration: $ => seq(
      repeat($.attribute),
      optional($.visibility),
      'suberror',
      $.type_identifier,
      '{',
      repeat($.enum_variant),
      '}',
    ),

    enum_variant: $ => seq(
      optional($.visibility),
      $.constructor,
      optional(seq(
        '(',
        commaSep1($._type),
        ')',
      )),
    ),

    constructor: $ => $.type_identifier,

    // ==================== Trait ====================
    trait_declaration: $ => seq(
      repeat($.attribute),
      optional($.visibility),
      'trait',
      $.type_identifier,
      optional($.type_parameters),
      optional(seq('with', $.type_identifier, 'as', $.type_identifier)),
      '{',
      repeat($.trait_method),
      '}',
      optional($.derive_clause),
    ),

    trait_method: $ => seq(
      optional($.visibility),
      'fn',
      $.identifier,
      optional($.type_parameters),
      $.param_list,
      optional(seq('->', $._type)),
      optional(choice(';', $.block_expr)),
    ),

    // ==================== Impl ====================
    impl_block: $ => choice(
      seq(
        optional($.visibility),
        'impl',
        choice($.identifier, $.type_identifier),
        'for',
        $._type,
        '{',
        repeat($.impl_method),
        '}',
      ),
      seq(
        optional($.visibility),
        'impl',
        $._type,
        optional('with'),
        '{',
        repeat($.impl_method),
        '}',
      ),
    ),

    type_arguments: $ => seq(
      '[',
      commaSep1($._type),
      ']',
    ),

    impl_method: $ => seq(
      optional($.visibility),
      optional('async'),
      'fn',
      $.identifier,
      optional($.type_parameters),
      $.param_list,
      optional(seq('->', $._type)),
      $.block_expr,
    ),

    // ==================== 类型别名 ====================
    type_alias: $ => seq(
      optional($.visibility),
      'type',
      $.type_identifier,
      optional($.type_parameters),
      '=',
      $._type,
    ),

    // ==================== 测试 ====================
    test_declaration: $ => seq(
      'test',
      optional($.string_literal),
      $.block_expr,
    ),

    derive_clause: $ => seq(
      'derive',
      '(',
      commaSep1(choice($.identifier, $.type_identifier)),
      ')',
    ),

    error_type: $ => seq('raise', optional($._type)),

    // ==================== 表达式 ====================
    _expression: $ => choice(
      $.identifier,
      $.package_access,
      $.number_literal,
      $.char_literal,
      $.bool_literal,
      $.unit_literal,
      'self',
      $.string_literal,
      $.raw_string_literal,
      $.interpolated_string,
      $.byte_literal,
      $.bytes_literal,
      $.tuple_expr,
      $.array_expr,
      $.struct_expr,
      $.unary_expr,
      $.binary_expr,
      $.assign_expr,
      $.pipe_expr,
      $.function_call,
      $.associated_call,
      $.method_call,
      $.field_access,
      $.index_access,
      $.closure_expr,
      $.arrow_expr,
      $.is_expr,
      $.await_expr,
      $.if_expr,
      $.match_expr,
      $.loop_expr,
      $.while_expr,
      $.for_expr,
      $.break_expr,
      $.continue_expr,
      $.return_expr,
      $.raise_expr,
      $.try_expr,
      $.try_suffix_expr,
      $.guard_expr,
      $.defer_expr,
      $.block_expr,
      seq('(', $._expression, ')'),
    ),

    // 基础字面量
    number_literal: $ => /-?\d+(\.\d+)?([eE][+-]?\d+)?/,
    char_literal: $ => seq("'", choice(/[^'\\]/, /\\./), "'"),
    bool_literal: $ => choice('true', 'false'),
    unit_literal: $ => seq('(', ')'),

    // 元组
    tuple_expr: $ => seq(
      '(',
      commaSep2($._expression),
      ')',
    ),

    // 数组
    array_expr: $ => seq(
      '[',
      commaSep($._expression),
      ']',
    ),

    // 结构体构造
    struct_expr: $ => seq(
      $.type_identifier,
      optional(seq('(', commaSep($._expression), ')')),
      optional(seq(
        '{',
        commaSep($.field_init),
        '}',
      )),
    ),

    field_init: $ => seq(
      $.identifier,
      ':',
      $._expression,
    ),

    interpolated_string: $ => seq(
      '$"',
      repeat(choice(
        $.string_fragment,
        $.interpolation,
      )),
      '"',
    ),

    string_fragment: $ => token.immediate(/([^"\\{]|\\[^{])+/),

    interpolation: $ => seq(
      '\\{',
      $._expression,
      '}',
    ),

    // 一元表达式
    unary_expr: $ => prec(UNARY, seq(
      choice('-', '!', '~'),
      $._expression,
    )),

    // 二元表达式（优先级从低到高）
    binary_expr: $ => {
      const table = [
        [prec.left(OR, seq($._expression, '||', $._expression))],
        [prec.left(AND, seq($._expression, '&&', $._expression))],
        [prec.left(EQ, seq($._expression, choice('==', '!='), $._expression))],
        [prec.left(CMP, seq($._expression, choice('<', '<=', '>', '>='), $._expression))],
        [prec.left(BOR, seq($._expression, '|', $._expression))],
        [prec.left(BXOR, seq($._expression, '^', $._expression))],
        [prec.left(BAND, seq($._expression, '&', $._expression))],
        [prec.left(SHIFT, seq($._expression, choice('<<', '>>'), $._expression))],
        [prec.left(RANGE, seq($._expression, choice('..', '..=', '..<', '..>'), $._expression))],
        [prec.left(ADD, seq($._expression, choice('+', '-'), $._expression))],
        [prec.left(MUL, seq($._expression, choice('*', '/', '%'), $._expression))],
        [prec.right(POW, seq($._expression, '**', $._expression))],
      ];
      return choice(...table.map(rule => rule[0]));
    },

    // 赋值（含复合赋值）
    assign_expr: $ => prec.right(ASSIGN, seq(
      choice($.identifier, $.field_access, $.index_access),
      choice('=', ':=', '+=', '-=', '*=', '/='),
      $._expression,
    )),

    // 管道
    pipe_expr: $ => prec.left(PIPE, seq(
      $._expression,
      '|>',
      $._expression,
    )),

    // 函数调用
    function_call: $ => seq(
      choice($.identifier, $.package_access),
      optional($.type_arguments),
      $.arg_list,
    ),

    associated_call: $ => prec(1, seq(
      choice($.builtin_type, $.type_identifier),
      '::',
      choice($.identifier, $.type_identifier),
      optional($.type_arguments),
      choice(
        $.arg_list,
        seq('{', commaSep($.field_init), '}'),
      ),
    )),

    arg_list: $ => seq(
      '(',
      commaSep($._expression),
      ')',
    ),

    // 方法调用
    method_call: $ => seq(
      $._expression,
      '.',
      $.identifier,
      optional($.type_arguments),
      $.arg_list,
    ),

    // 字段访问
    field_access: $ => seq(
      $._expression,
      '.',
      $.identifier,
    ),

    // 索引访问
    index_access: $ => seq(
      $._expression,
      '[',
      $._expression,
      ']',
    ),

    // 闭包
    closure_expr: $ => seq(
      'fn',
      optional($.type_parameters),
      $.param_list,
      choice(
        seq('=>', $._expression),
        $.block_expr,
      ),
    ),

    // 箭头函数
    arrow_expr: $ => prec.left(-1, seq(
      $.identifier,
      '=>',
      choice($._expression, $.block_expr),
    )),

    // If 表达式
    if_expr: $ => seq(
      'if',
      $.if_condition,
      $.block_expr,
      repeat($.else_if_clause),
      optional(seq('else', $.block_expr)),
    ),

    if_condition: $ => $._expression,

    else_if_clause: $ => seq(
      'else',
      'if',
      $.if_condition,
      $.block_expr,
    ),

    // Match 表达式
    match_expr: $ => seq(
      'match',
      $._expression,
      '{',
      repeat($.match_arm),
      '}',
    ),

    match_arm: $ => seq(
      $._pattern,
      optional(seq('if', $._expression)),
      '=>',
      choice($._expression, $.block_expr),
    ),

    // Loop 表达式
    loop_expr: $ => seq(
      'loop',
      $.block_expr,
      optional($.nobreak_clause),
    ),

    // While 表达式
    while_expr: $ => seq(
      'while',
      $.if_condition,
      $.block_expr,
      optional($.nobreak_clause),
    ),

    // For 表达式
    for_expr: $ => seq(
      optional($.label_clause),
      'for',
      choice(
        seq(
          $._pattern,
          optional(seq(',', $._pattern)),
          'in',
          $._expression,
          $.block_expr,
          optional($.nobreak_clause),
        ),
        seq(
          optional($.for_init_list),
          ';',
          optional($._expression),
          ';',
          optional($.for_update_list),
          $.block_expr,
          optional($.nobreak_clause),
        ),
      ),
    ),

    label_clause: $ => prec(1, seq(
      $.identifier,
      '~',
      ':',
    )),

    for_init_list: $ => commaSep1($.for_init_item),

    for_init_item: $ => seq(
      $.identifier,
      '=',
      $._expression,
    ),

    for_update_list: $ => commaSep1($.for_update_item),

    for_update_item: $ => seq(
      $.identifier,
      '=',
      $._expression,
    ),

    nobreak_clause: $ => seq(
      'nobreak',
      $.block_expr,
    ),

    // Break
    break_expr: $ => prec.right(BREAK, seq(
      'break',
      optional(seq($.identifier, '~')),
      optional($._expression),
    )),

    // Continue
    continue_expr: $ => prec.right(CONTINUE, seq(
      'continue',
      optional(seq($.identifier, '~')),
      optional($.continue_args),
    )),

    continue_args: $ => prec.left(1, commaSep1($._expression)),

    // Return
    return_expr: $ => prec.right(RETURN, seq(
      'return',
      optional($._expression),
    )),

    // Raise
    raise_expr: $ => prec.right(RAISE, seq(
      'raise',
      $._expression,
    )),

    // Try 表达式
    try_expr: $ => choice(
      seq('try', '?', $._expression),
      seq('try', '!', $._expression),
      seq(
        'try',
        $._expression,
        repeat1($.catch_clause),
        optional($.noraise_clause),
      ),
    ),

    try_suffix_expr: $ => prec(FIELD, seq($._expression, '?')),

    catch_clause: $ => choice(
      seq('catch', '{', repeat($.match_arm), '}'),
      seq('catch', '(', $._pattern, ')', $.block_expr),
    ),

    noraise_clause: $ => seq('noraise', $.block_expr),

    // Guard 表达式（支持 is 模式匹配）
    guard_pattern: $ => prec(5, seq(
      $._expression,
      'is',
      $._pattern,
    )),

    is_expr: $ => prec.left(4, seq(
      $._expression,
      'is',
      $._pattern,
    )),

    await_expr: $ => prec(UNARY, seq(
      'await',
      $._expression,
    )),

    guard_expr: $ => choice(
      prec(13, seq(
        'guard',
        $.guard_pattern,
        'else',
        choice($._expression, $.block_expr),
      )),
      prec(13, seq(
        'guard',
        $._expression,
        'else',
        choice($._expression, $.block_expr),
      )),
    ),

    defer_expr: $ => seq(
      'defer',
      $._expression,
    ),

    // 代码块（关键：正确设计避免 GLR 冲突）
    block_expr: $ => seq(
      '{',
      repeat($.block_statement),
      optional($._expression),
      '}',
    ),

    block_statement: $ => prec(1, choice(
      seq(choice($.declaration, $._expression), optional(';')),
      seq($.value_declaration, optional(';')),
    )),

    value_declaration: $ => prec.right(1, seq(
      optional($.visibility),
      choice(seq('let', optional('mut')), 'const'),
      $._pattern,
      optional(seq(':', $._type)),
      optional(seq('=', $._expression)),
      optional(';'),
    )),

    // ==================== 模式 ====================
    _pattern: $ => choice(
      $.or_pattern,
      $.as_pattern,
      $.wildcard_pattern,
      $.identifier_pattern,
      $.literal_pattern,
      $.constructor_pattern,
      $.tuple_pattern,
      $.record_pattern,
      $.array_pattern,
      $.range_pattern,
      seq('(', $._pattern, ')'),
    ),

    or_pattern: $ => prec.left(1, seq($._pattern, '|', $._pattern)),

    as_pattern: $ => prec.left(2, seq($._pattern, 'as', $.identifier)),

    range_pattern: $ => prec(1, seq(
      optional(choice($.number_literal, $.identifier)),
      choice('..', '..=', '..<', '..>'),
      choice($.number_literal, $.identifier),
    )),

    wildcard_pattern: $ => '_',

    identifier_pattern: $ => $.identifier,

    literal_pattern: $ => choice(
      $.number_literal,
      $.char_literal,
      $.bool_literal,
      $.string_literal,
    ),

    constructor_pattern: $ => prec.left(1, seq(
      $.constructor,
      optional(seq('(', commaSep1($._pattern), ')')),
    )),

    tuple_pattern: $ => seq(
      '(',
      commaSep2($._pattern),
      ')',
    ),

    array_pattern: $ => seq(
      '[',
      commaSep(choice($._pattern, seq('..', optional($.identifier)))),
      ']',
    ),

    record_pattern: $ => prec(1, seq(
      $.type_identifier,
      '{',
      commaSep(choice($.field_pattern, seq('..', optional($.identifier)))),
      '}',
    )),

    field_pattern: $ => seq(
      $.identifier,
      optional(seq(':', $._pattern)),
    ),

    // ==================== 类型 ====================
    _type: $ => choice(
      seq(choice($.builtin_type, $.type_identifier), optional($.type_arguments)),
      $.tuple_type,
      $.function_type,
      seq('(', $._type, ')'),
    ),

    builtin_type: $ => choice(
      'Unit',
      'Bool',
      'Int', 'Int64', 'Int32', 'Int16', 'Int8',
      'UInt', 'UInt64', 'UInt32', 'UInt16', 'UInt8',
      'Float', 'Float64', 'Float32',
      'Double',
      'Char', 'Byte',
      'String',
      'Bytes',
      'Array',
    ),

    tuple_type: $ => seq(
      '(',
      commaSep2($._type),
      ')',
    ),

    function_type: $ => prec.right(FN_TYPE, seq(
      '(',
      commaSep($._type),
      ')',
      '->',
      $._type,
    )),

    // ==================== 字符串字面量 ====================
    string_literal: $ => seq(
      '"',
      repeat(choice(
        /[^"\\]/,
        /\\./,
      )),
      '"',
    ),

    raw_string_literal: $ => token(seq(
      '#|',
      repeat(choice(
        /[^|#]/,
        /\|[^#]/,
        /#[^|]/,
        /#\|/,
      )),
      '|#',
    )),

    byte_literal: $ => seq(
      'b\'',
      choice(
        /[^'\\]/,
        /\\./,
      ),
      '\'',
    ),

    bytes_literal: $ => seq(
      'b"',
      repeat(choice(
        /[^"\\]/,
        /\\./,
      )),
      '"',
    ),

    // ==================== 标识符 ====================
    identifier: $ => /[a-z_][a-zA-Z0-9_]*/,
    type_identifier: $ => /[A-Z][a-zA-Z0-9_]*/,

    // ==================== 注释 ====================
    comment: $ => choice(
      token(seq('//', /.*/)),
      seq('/*', /[^*]*\*+([^\/\*][^*]*\*+)*\//),
    ),
  },
});
