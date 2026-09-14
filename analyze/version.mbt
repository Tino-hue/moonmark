///|
/// 版本号单一来源（single source of truth）
///
/// analyze 包被 CLI 与报告渲染器共同依赖，因此把版本常量放在这里，
/// 供 cli 包的 `constants.mbt` 转发，避免 analyze 反向依赖 cli 造成循环。
/// 发布新版本时需要同步更新：
///   1. 本文件 depsight_version 常量
///   2. /moon.mod 中的 version 字段
///   3. Git tag  v<VERSION>
pub let depsight_version : String = "0.6.0"
