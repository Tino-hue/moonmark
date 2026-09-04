/// ============================================================
/// 版本与常量统一管理
///
/// 单点定义：修改版本号只需改此文件。
/// 发布新版本时，需要同时更新以下三处保持一致：
///   1. 本文件 version 常量
///   2. /moon.mod 中的 version 字段
///   3. Git tag  v<VERSION>  （如 v0.6.0）
/// ============================================================

///|
/// 语义化版本号（SemVer），对应发布到 mooncakes.io 和 Git tag。
pub let version : String = "0.6.0"

///|
/// CLI `--version` 输出和帮助标题中的完整品牌名。
pub fn version_full() -> String {
  "MoonBit Depsight v" + version
}

///|
/// 发布日期，每次发布时更新。
pub let release_date : String = "2026-09-23"

// 退出码约定（与 PRD 9.4 保持一致）

///|
pub let exit_ok : Int = 0

///|
pub let exit_audit_fail : Int = 1 // --fail-on-score 或 --fail-on-critical 触发

///|
pub let exit_args_error : Int = 2 // 参数解析错误 / 未知选项

///|
pub let exit_internal_error : Int = 3 // 分析过程内部错误

///|
pub let exit_io_error : Int = 4 // 文件读写 / 网络 IO 错误
