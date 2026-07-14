# MoonBit Depsight · 项目申报书

| 项 | 内容 |
|---|---|
| **名称** | MoonBit Depsight — 依赖健康诊断器 |
| **GitHub** | https://github.com/Tino-hue/moonmark |
| **GitLink** | https://www.gitlink.org.cn/LittleFish/moonbit-depsight |
| **Gitee** | https://gitee.com/xiaoruoyu1206/moon-bit-depsight |
| **版本** | 0.5.3（mooncakes.io 已发布，build_status=success） |
| **方向** | 生态工具：MoonBit 依赖审计 + 健康评分 CLI |
| **性质** | 原创 |

## 简介

读取 `moon.mod` 递归构建依赖图，5 维度加权评分（新鲜度/合规/废弃密度/体积/活跃度），输出 terminal/HTML/JSON/SARIF/Markdown 5 种格式，可对接 CI。

## 核心功能

1. DAG + DFS + Memo + 循环检测
2. 跨层废弃 API Reverse-BFS（MoonBit 生态首创）
3. 5 维 0-100 健康评分，可配置权重
4. 12+ SPDX 许可证合规 + 强 copyleft 高风险标记
5. 5 种输出格式 + 5 种便捷命令

## 适用场景

- **日常开发**：`depsight audit` 评估新依赖
- **CI/CD**：`--fail-on-score` / `--fail-on-critical` 阻断流水线
- **长期维护**：`--baseline auto` 自动 diff 历史报告

## 当前进度

52 个 .mbt / 267 个测试 / 0 fail / 自审计 98/100 / mooncakes.io v0.5.3

> 详细架构/创新点/选型/计划/风险 → [docs/PROPOSAL_DETAILED.md](docs/PROPOSAL_DETAILED.md)