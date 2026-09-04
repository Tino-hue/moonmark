# MoonBit Depsight v0.6.0 — 多仓库同步与工程化实施方案

> 文档版本：v1.0
> 创建日期：2026-09-04
> 适用版本：v0.6.0
> 范围：Git 多仓库管理 · 工程化优化 · PRD 完善

---

## 目录

- [第一部分：多远程仓库管理与同步方案](#第一部分多远程仓库管理与同步方案)
  - [1.1 现状分析](#11-现状分析)
  - [1.2 分支管理策略](#12-分支管理策略)
  - [1.3 远程仓库配置规范](#13-远程仓库配置规范)
  - [1.4 同步流程](#14-同步流程)
  - [1.5 操作手册](#15-操作手册)
- [第二部分：MoonBit 工程化优化方案](#第二部分moonbit-工程化优化方案)
  - [2.1 项目现状评估](#21-项目现状评估)
  - [2.2 构建流程优化](#22-构建流程优化)
  - [2.3 测试策略优化](#23-测试策略优化)
  - [2.4 代码质量控制](#24-代码质量控制)
  - [2.5 发布与部署流程](#25-发布与部署流程)
  - [2.6 CI/CD 流水线增强](#26-cicd-流水线增强)
- [第三部分：项目评估与 PRD 补充](#第三部分项目评估与-prd-补充)
  - [3.1 项目全面评估](#31-项目全面评估)
  - [3.2 非功能需求补充](#32-非功能需求补充)
  - [3.3 长期演进路线](#33-长期演进路线)

---

# 第一部分：多远程仓库管理与同步方案

## 1.1 现状分析

### 当前远程仓库配置

```
origin  →  GitHub  (主仓库)   https://github.com/Tino-hue/moonmark.git
gitlink →  GitLink (同步镜像) https://gitlink.org.cn/LittleFish/moonbit-depsight.git
gitee   →  Gitee   (同步镜像) https://gitee.com/xiaoruoyu1206/moon-bit-depsight.git
moonbit-depsight → GitLink(重复)  https://www.gitlink.org.cn/LittleFish/moonbit-depsight
```

### 现存问题

1. **重复 remote**：`gitlink` 和 `moonbit-depsight` 指向同一个 GitLink 仓库，配置冗余
2. **分支命名不统一**：`main` 和 `master` 两个默认分支混用，各平台不一致
3. **无明确同步策略**：当前靠手动 `git push <remote>`，容易遗漏
4. **缺少 GitLink/Gitee 端的 CI 配置**：只有 GitHub 有 Actions，其他平台无自动化验证
5. **无标签管理**：至今无任何 git tag，版本发布缺少锚点

---

## 1.2 分支管理策略

采用 **GitHub Flow + 三分支分级** 模型，兼顾简洁性和发布可控性。

### 分支定义

| 分支 | 别名 | 用途 | 生命周期 | 推送权限 |
|------|------|------|----------|----------|
| `main` | 开发分支 | 日常开发集成分支，所有 PR 合入此处 | 永久 | 维护者 + 机器人 |
| `release/*` | 发布分支 | 版本发布候选，如 `release/v0.6.0` | 临时（发布后删除） | 维护者 |
| `stable` | 生产分支 | 已发布的稳定版本锚点 | 永久 | 仅机器人通过 CI 推送 |
| `feature/*` | 功能分支 | 单项功能开发，如 `feature/stats-cmd` | 临时（合入后删除） | 开发者个人 |
| `hotfix/*` | 热修复分支 | 线上紧急修复，如 `hotfix/version-fix` | 临时（合入后删除） | 维护者 |

### 分支流向图

```
feature/* ──PR──▶ main ──cut──▶ release/vX.Y.Z ──tag+merge──▶ stable
                    ▲                                          │
                    │                                          │
hotfix/* ────PR─────┘──────────────────────────────────────────┘
```

### 开发流程（标准功能）

1. 从 `main` 切出功能分支：`git checkout -b feature/f01-api-count main`
2. 在功能分支上开发，本地运行检查和测试
3. 推送 `feature/*` 到 **GitHub origin**，创建 Pull Request
4. CI 通过 + Code Review 通过后，合入 `main`
5. 删除功能分支

### 发布流程

1. 功能冻结后，从 `main` 切出发布分支：`git checkout -b release/v0.6.0 main`
2. 在发布分支上做最后测试、更新 CHANGELOG、修复阻塞 bug
3. CI 全量验证通过后，打 tag：`git tag -a v0.6.0 -m "Release v0.6.0"`
4. 合并 `release/v0.6.0` 到 `stable` 和 `main`
5. 删除 `release/v0.6.0` 分支
6. 触发三平台同步

### 热修复流程

1. 从 `stable` 切出热修复分支：`git checkout -b hotfix/xxx stable`
2. 修复后合入 `main`，cherry-pick 到 `stable`
3. 打补丁 tag：`v0.6.1`
4. 触发三平台同步

---

## 1.3 远程仓库配置规范

### 1.3.1 规范远程命名

清理重复 remote，统一命名：

```bash
# 1. 删除重复的 moonbit-depsight remote
git remote remove moonbit-depsight

# 2. 确认最终配置
git remote rename origin github   # (可选，更清晰；不建议，origin 是惯用法)
```

**最终标准配置**：

```
origin  (push/fetch)  →  GitHub  (主仓库，读写优先)
gitlink (push/fetch)  →  GitLink (镜像，CI 验证后同步)
gitee   (push/fetch)  →  Gitee   (镜像，CI 验证后同步)
```

### 1.3.2 分支命名对齐三平台

所有平台统一使用 `main` 作为默认分支：

| 平台 | 当前默认分支 | 目标默认分支 | 操作 |
|------|-------------|-------------|------|
| GitHub | main | main | 无需改动 |
| GitLink | master | main | GitLink 后台设置默认分支为 main，删除 master |
| Gitee | master / main | main | Gitee 后台设置默认分支为 main，删除 master |

### 1.3.3 保护分支设置

**GitHub（主仓库）**：
- `main` 分支保护：必须通过 PR 合入，禁止直接 push
- `stable` 分支保护：仅机器人可推送
- PR 必须通过 CI 检查 + 至少 1 个 review
- Tag 保护：仅维护者可创建 tag

**GitLink / Gitee（镜像仓库）**：
- 不设保护分支（由同步脚本推送）
- 关闭 Pull Request 入口，引导到 GitHub 协作

---

## 1.4 同步流程

### 1.4.1 核心原则

> **GitHub 为单一可信源（Single Source of Truth）**
> 所有提交、PR、Issue、讨论只在 GitHub 发生。GitLink 和 Gitee 仅作为镜像，不接受直接提交。

### 1.4.2 同步触发时机与流程

```
开发者 push/合入 GitHub main
        │
        ▼
┌─────────────────────┐
│  GitHub Actions CI   │  ← 第一关：构建检查
│  (check/fmt/test)    │
└─────────┬───────────┘
          │ 通过
          ▼
┌─────────────────────┐
│  GitHub Actions CI   │  ← 第二关：自审计
│  (depsight audit)    │
└─────────┬───────────┘
          │ 通过
          ▼
┌─────────────────────────────────────┐
│  GitHub Actions: sync-mirrors job    │  ← 自动化镜像同步
│  1. git push gitlink main:main       │
│  2. git push gitee   main:main       │
│  3. git push gitlink --tags          │
│  4. git push gitee   --tags          │
└─────────────────────────────────────┘
```

### 1.4.3 同步内容范围

| 内容 | GitHub → GitLink | GitHub → Gitee | 说明 |
|------|-----------------|---------------|------|
| `main` 分支 | ✅ 每次 CI 通过后 | ✅ 每次 CI 通过后 | 主干 |
| `stable` 分支 | ✅ 每次 CI 通过后 | ✅ 每次 CI 通过后 | 生产稳定锚点 |
| Tags (`v*`) | ✅ tag 创建后 | ✅ tag 创建后 | 版本锚点 |
| `release/*` 分支 | ❌ 不推送 | ❌ 不推送 | 发布期间的临时分支 |
| `feature/*` 分支 | ❌ 不推送 | ❌ 不推送 | 个人开发分支 |
| `hotfix/*` 分支 | ❌ 不推送 | ❌ 不推送 | 临时修复分支 |
| PR 分支 | ❌ 不推送 | ❌ 不推送 | 仅 GitHub 协作使用 |
| GitHub Actions | N/A（不跨平台） | N/A | GitLink/Gitee 使用各自 CI |

---

## 1.5 操作手册

### 1.5.1 初始化本地环境（一次性）

```bash
# 克隆主仓库
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark

# 添加两个镜像 remote
git remote add gitlink https://gitlink.org.cn/LittleFish/moonbit-depsight.git
git remote add gitee   https://gitee.com/xiaoruoyu1206/moon-bit-depsight.git

# 验证配置
git remote -v
# 预期输出：
# origin   https://github.com/Tino-hue/moonmark.git (fetch/push)
# gitlink  https://gitlink.org.cn/LittleFish/moonbit-depsight.git (fetch/push)
# gitee    https://gitee.com/xiaoruoyu1206/moon-bit-depsight.git (fetch/push)
```

### 1.5.2 日常开发提交

```bash
# 1. 拉取最新 main
git checkout main
git pull origin main

# 2. 切功能分支
git checkout -b feature/f01-api-count

# 3. 开发 + 本地验证
moon check --target js --deny-warn
moon fmt --check
moon test --target js

# 4. 提交（只推 GitHub！）
git add .
git commit -m "feat(analyze): count total public APIs for deprecated density

- Add count_public_apis_from_dir() in package_scan.mbt
- Replace hardcoded total_api_count=10 with real scanned value
- Add unit tests for API counting"

git push origin feature/f01-api-count
# 在 GitHub 创建 PR，等待 CI 通过和 review
```

### 1.5.3 手动同步（紧急情况，CI 故障时）

```bash
# 确保 main 是最新的
git checkout main
git pull origin main

# 1. 推 GitLink
git push gitlink main:main
git push gitlink --tags

# 2. 推 Gitee
git push gitee main:main
git push gitee --tags

# 3. 推 stable（如有）
git push gitlink stable:stable
git push gitee stable:stable
```

### 1.5.4 版本发布操作

```bash
# 1. 切发布分支
git checkout -b release/v0.6.0 main

# 2. 做最后修改（CHANGELOG、版本号、文档）
# 编辑 CHANGELOG.md、cli.mbt 中 VERSION、moon.mod 版本
git add -A
git commit -m "chore(release): bump version to v0.6.0"

# 3. CI 验证通过后，打 tag
git tag -a v0.6.0 -m "Release v0.6.0
- F01: Total API counting for accurate deprecated density
- F02: Transitive size integration
- F03: Version unification
- F04: Deprecated propagation visualization
- F05: stats command
- F06: Enhanced risky example
- F07: Cross-platform path fix"

# 4. 推送 tag 到 GitHub（触发 CI + 自动同步）
git push origin v0.6.0

# 5. 合回 main 和 stable
git checkout main
git merge --no-ff release/v0.6.0
git push origin main

git checkout stable
git merge --no-ff release/v0.6.0
git push origin stable

# 6. 删除发布分支
git branch -d release/v0.6.0
git push origin --delete release/v0.6.0

# 7. 自动同步到 GitLink/Gitee（CI 完成，无需手动）
```

---

# 第二部分：MoonBit 工程化优化方案

## 2.1 项目现状评估

### 2.1.1 优势

| 维度 | 现状 | 评价 |
|------|------|------|
| 架构设计 | 7 层模块化分层，依赖倒置 | 优秀，可扩展性强 |
| 测试覆盖 | 267 个用例，单元+集成+E2E+边界+跨平台+性能 | 优秀，类型全面 |
| 文档完整度 | 6 篇核心文档 + README/CHANGELOG/CONTRIBUTING | 优秀 |
| 代码质量 | 零 TODO/FIXME，`--deny-warn` 通过 | 良好 |
| CI 流水线 | GitHub Actions：check + fmt + info + test + build + audit | 良好 |
| 社区健康文件 | LICENSE、CONTRIBUTING、CODE_OF_CONDUCT、SECURITY、Issue/PR 模板 | 齐全 |

### 2.1.2 不足

| 维度 | 问题 | 严重度 |
|------|------|--------|
| 版本管理 | 无 git tag，CLI 版本号与 moon.mod 不一致 | 高 |
| 同步机制 | 三平台无自动同步，GitLink/Gitee 缺少 CI | 高 |
| 发布流程 | 无标准化 release 流程，无发布 checklist | 中 |
| 性能基准 | benchmark.md 只有阈值，缺真实数据表格 | 中 |
| 构建产物 | 无构建产物上传和版本归档 | 中 |
| 预提交钩子 | 无 git hook 配置，依赖开发者自律 | 中 |
| 代码覆盖 | 无覆盖率报告，无法量化测试覆盖程度 | 低 |
| MoonBit 双后端 | 仅验证 js 目标，未验证 wasm/wasm-gc 可编译性 | 低 |

---

## 2.2 构建流程优化

### 2.2.1 标准化构建命令

在项目根目录创建 `Makefile`（或 `.mbtx` 脚本，待工具链支持后迁移），统一所有操作入口：

```makefile
# Makefile — MoonBit Depsight 统一构建入口
# 用法：make <target>

.PHONY: all check fmt info test test-all build clean release sync

all: check fmt info test build

# 1. 类型检查（警告当错误）
check:
	moon check --target js --deny-warn

# 2. 格式检查
fmt:
	moon fmt --check

# 3. 格式修复
fmt-fix:
	moon fmt

# 4. 生成接口文件
info:
	moon info

# 5. 单元 + 集成测试（跳过性能基准）
test:
	moon test --target js

# 6. 全量测试（含性能基准）
test-all:
	moon test --target js --no-skip

# 7. 构建 JS bundle
build:
	moon build --target js

# 8. 构建生产版本（release 模式，体积更小）
build-release:
	moon build --target js --release

# 9. 清理构建产物
clean:
	rm -rf _build/

# 10. 本地运行示例审计
example-healthy: build
	node _build/js/debug/build/depsight.js audit --target-pkg examples/healthy_project

example-outdated: build
	node _build/js/debug/build/depsight.js audit --target-pkg examples/outdated_project

example-risky: build
	node _build/js/debug/build/depsight.js audit --target-pkg examples/risky_project

# 11. 预提交检查（开发者本地）
precommit: check fmt test

# 12. 发布前全量检查
release-check: check fmt info test-all build-release example-healthy

# 13. 手动同步到三平台
sync:
	git push gitlink main:main
	git push gitee main:main
	git push gitlink --tags
	git push gitee --tags
```

> **Windows 用户**：安装 `make`（choco install make）或使用 PowerShell 别名 `function make { mingw32-make $args }`，或直接执行各步骤中的 `moon` 命令。

### 2.2.2 多后端构建验证

虽然 Depsight 主要目标是 js，但验证核心逻辑包可被其他后端编译，能增强库质量：

```makefile
# 验证核心包（不含 FFI 的纯逻辑）可编译到 wasm-gc
check-wasm:
	# parse, graph, report 这三个纯逻辑包理论上不依赖 JS FFI
	moon check --target wasm-gc
```

**实现策略**：将现有包划分为「纯逻辑包」和「JS FFI 包」，纯逻辑包要求所有后端可编译通过：

| 包 | 纯逻辑 | 依赖 JS FFI | 目标后端 |
|----|--------|------------|----------|
| `parse/` | ✅ 可改造 | 极少（文件读取） | all |
| `report/` | ✅ | 无 | all |
| `graph/` | ✅ | 无 | all |
| `analyze/semver` | ✅ | 无 | all |
| `analyze/license` | ✅ | 无 | all |
| `analyze/health_score` | ✅ | 无 | all |
| `analyze/size` | ✅ | 无 | all |
| `fetch/` | ❌ | HTTP FFI | js only |
| `cache/` | ❌ | FS FFI | js only |
| `cli/` | ❌ | process.argv, exit | js only |
| `analyze/reporters` | ❌ | 终端颜色 FFI | js only |

---

## 2.3 测试策略优化

### 2.3.1 测试分层矩阵

| 层级 | 工具 | 触发时机 | 目标耗时 | 覆盖 |
|------|------|---------|----------|------|
| 单元测试 | `moon test` 内置 | 每次 push / PR | < 10s | 单个函数和数据结构 |
| 集成测试 | `moon test` 内置 | 每次 push / PR | < 30s | 模块间协作（graph→analyze→report） |
| E2E 测试 | `moon test` 内置 + Node 子进程 | 每次 push / PR | < 1min | CLI 入口 → 完整流程 → 输出验证 |
| 性能基准 | `moon test --no-skip` | release 分支 / 手动 | < 2min | 大图构建速度、分析耗时阈值 |
| 跨平台测试 | `moon test` 内置 | 每次 CI | < 30s | 路径、编码、换行符兼容性 |
| 回归测试（示例） | Node 执行 bundle | release 分支 | < 30s | 三个示例项目的预期输出一致 |

### 2.3.2 示例回归测试

新增 `example_regression_test.mbt` 或 shell 脚本，验证三个示例项目的输出是否符合预期：

- `healthy_project` → 健康分 ≥ 90，无 critical
- `outdated_project` → 触发 VERSION-001
- `risky_project` → 触发 LICENSE-002 + 至少 3 种其他诊断

### 2.3.3 快照测试

对终端报告、HTML 报告输出做快照测试（golden file）：

```
test/snapshots/
  healthy_terminal.golden
  outdated_terminal.golden
  risky_html.golden
```

每次 CI 对比当前输出与 golden，差异则失败，防止报告渲染退化。

---

## 2.4 代码质量控制

### 2.4.1 门禁规则

| 检查项 | 工具 | 强制级别 | 触发 |
|--------|------|----------|------|
| 类型安全 | `moon check --deny-warn` | 阻塞（必须通过） | 所有分支 push + PR |
| 代码格式 | `moon fmt --check` | 阻塞（必须通过） | 所有分支 push + PR |
| 接口一致性 | `moon info` | 阻塞（生成 .mbti 必须与提交一致） | PR |
| 测试通过率 | `moon test --target js` | 阻塞（必须全绿） | 所有分支 push + PR |
| 自审计健康分 | `depsight audit --fail-on-score 85` | 警告（低于 85 提醒） | main + release |
| 诊断 Critical | `depsight audit --fail-on-critical` | 阻塞（有 critical 失败） | main + release |
| Code Review | GitHub PR | 阻塞（至少 1 Approvals） | PR 合入 |

### 2.4.2 预提交钩子（Git Hooks）

创建 `.githooks/pre-commit` 脚本，开发者本地启用后自动检查：

```bash
#!/bin/bash
# .githooks/pre-commit — Depsight 预提交检查

echo "▶ Running moon fmt --check"
if ! moon fmt --check; then
    echo "✗ Format check failed. Run 'moon fmt' to fix."
    exit 1
fi

echo "▶ Running moon check --target js --deny-warn"
if ! moon check --target js --deny-warn; then
    echo "✗ Type check failed."
    exit 1
fi

echo "▶ Running moon test --target js (quick)"
if ! moon test --target js 2>&1 | tail -5; then
    echo "✗ Tests failed."
    exit 1
fi

echo "✅ Pre-commit checks passed."
exit 0
```

**启用方式**：
```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

### 2.4.3 Commit 规范

采用 **Conventional Commits** 规范，便于生成 CHANGELOG 和自动版本号：

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

Type 取值：

| type | 含义 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(cli): add stats command` |
| `fix` | Bug 修复 | `fix(analyzer): use transitive_size in health scoring` |
| `docs` | 文档变更 | `docs(README): update examples section` |
| `style` | 格式调整（不影响功能） | `style: apply moon fmt` |
| `refactor` | 重构（非新功能非修复） | `refactor(graph): extract cycle detector` |
| `test` | 测试相关 | `test(semver): add prerelease edge cases` |
| `chore` | 构建/工具/流程 | `chore(ci): add mirror sync workflow` |

Scope 建议使用子目录名：`cli`, `analyze`, `graph`, `parse`, `fetch`, `cache`, `report`, `ci`, `docs`

---

## 2.5 发布与部署流程

### 2.5.1 发布 CheckList

每个版本发布前，逐项确认：

- [ ] `moon check --target js --deny-warn` 通过
- [ ] `moon fmt --check` 通过
- [ ] `moon test --target js` 全部通过
- [ ] `moon test --target js --no-skip` 性能基准通过
- [ ] `moon build --target js --release` 构建成功
- [ ] 三个示例项目回归测试通过
- [ ] CLI 版本号与 `moon.mod` 一致
- [ ] CHANGELOG.md 已更新本次所有变更
- [ ] README.md 已同步更新
- [ ] 自审计健康分 ≥ 90
- [ ] git tag `vX.Y.Z` 已创建
- [ ] （发布后）构建产物归档到 GitHub Release
- [ ] （发布后）发布到 mooncakes.io

### 2.5.2 发布到 mooncakes.io

```bash
# 1. 确保发布分支通过所有检查
make release-check

# 2. 发布包
moon publish

# 3. 验证发布
moon search Tino-hue/depsight
```

### 2.5.3 构建产物归档

在 GitHub Release 中上传构建产物，方便用户直接下载：

```
depsight-v0.6.0-js.zip
  └── depsight.js       (release bundle)
```

通过 GitHub Actions 在 tag 创建时自动完成：
- 构建 release 模式的 JS bundle
- 打包成 zip
- 创建 GitHub Release 并上传

---

## 2.6 CI/CD 流水线增强

### 2.6.1 现有流水线评估

当前两个 workflow：

| Workflow | 内容 | 问题 |
|----------|------|------|
| `ci.yml` | check + fmt + info + test + build | 缺少：多后端验证、示例回归、自审计 |
| `depsight.yml` | 自审计 + 报告上传 | 与 ci.yml 有重复步骤，应合并 |

问题：
1. **重复劳动**：两个 workflow 都重新安装 MoonBit、编译运行，浪费资源
2. **无镜像同步**：CI 通过后没有自动推送到 GitLink/Gitee
3. **无 Release 自动化**：tag 创建后没有自动发布到 GitHub Release 和 mooncakes.io
4. **GitLink/Gitee 无 CI**：两个镜像平台没有自己的 CI 验证

### 2.6.2 新增 Workflow 清单

新增/改造为以下 5 个 workflow：

| 文件 | 触发 | 内容 |
|------|------|------|
| `ci.yml`（改造） | push/PR 到 `main`, `release/*`, `hotfix/*` | 主 CI：安装 → check → fmt → info → test → build → example-regression → **自审计** |
| `mirror-sync.yml`（新增） | push 到 `main`, `stable` + tag 创建 + workflow_dispatch | **镜像同步**：推送到 GitLink 和 Gitee 的 main/stable/tags |
| `release.yml`（新增） | tag `v*` 创建 | **发布流程**：构建 release → 上传 GitHub Release → （可选）发布到 mooncakes.io |
| `weekly-audit.yml`（改造自 depsight.yml） | schedule 每周一 03:00 | 定期审计：构建 + depsight audit + SARIF 上传到 GitHub Security |
| `benchmark.yml`（新增） | workflow_dispatch / release 分支 push | 性能基准：运行全量性能测试并输出报告 |

### 2.6.3 `mirror-sync.yml` 核心实现（GitHub Actions）

```yaml
name: Mirror Sync

on:
  push:
    branches: [main, stable]
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0  # 必须完整历史才能推送镜像

      - name: Configure Git identity
        run: |
          git config user.name  "depsight-bot"
          git config user.email "bot@depsight.local"

      - name: Push to GitLink
        env:
          GITLINK_TOKEN: ${{ secrets.GITLINK_TOKEN }}
        run: |
          git remote add gitlink-mirror https://x-access-token:${GITLINK_TOKEN}@gitlink.org.cn/LittleFish/moonbit-depsight.git
          git push gitlink-mirror main:main --force-with-lease
          git push gitlink-mirror stable:stable --force-with-lease || true
          git push gitlink-mirror --tags --force-with-lease

      - name: Push to Gitee
        env:
          GITEE_TOKEN: ${{ secrets.GITEE_TOKEN }}
        run: |
          git remote add gitee-mirror https://x-access-token:${GITEE_TOKEN}@gitee.com/xiaoruoyu1206/moon-bit-depsight.git
          git push gitee-mirror main:main --force-with-lease
          git push gitee-mirror stable:stable --force-with-lease || true
          git push gitee-mirror --tags --force-with-lease
```

> **配置步骤**：
> 1. 在 GitLink 生成 Personal Access Token
> 2. 在 Gitee 生成 Personal Access Token（推送权限）
> 3. 在 GitHub 项目 Settings → Secrets 中添加：
>    - `GITLINK_TOKEN` = 你的 GitLink PAT
>    - `GITEE_TOKEN` = 你的 Gitee PAT

### 2.6.4 GitLink / Gitee 端 CI 配置

虽然代码从 GitHub 同步过来，但在国内平台也运行自己的 CI，可以提升国内用户信任度：

**GitLink（.gitlink-ci.yml）**：
```yaml
name: GitLink CI
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install MoonBit (CN mirror)
        run: |
          MOONBIT_INSTALL_VERSION=latest curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH
      - name: MoonBit checks
        run: |
          moon update
          moon check --target js --deny-warn
          moon fmt --check
          moon test --target js
          moon build --target js
```

**Gitee（.workflow/build.yml）** 类似，使用 Gitee Go 语法。

---

# 第三部分：项目评估与 PRD 补充

## 3.1 项目全面评估

### 3.1.1 优势（Strengths）

| # | 优势 | 说明 |
|---|------|------|
| S1 | **生态卡位准确** |  MoonBit 生态唯一的依赖审计工具，对标 cargo audit/npm audit，方向选择正确 |
| S2 | **架构设计优秀** | 7 层模块化分层 + 依赖倒置（FileSystem/Registry 接口），可测试可扩展性强 |
| S3 | **功能完整度高** | 5 维评分、5 种输出、5 个命令，核心功能全部落地，SARIF/基线对比等高级功能也已实现 |
| S4 | **首创功能** | 跨包废弃 API Reverse-BFS 传播检测，MoonBit 生态独此一家 |
| S5 | **测试覆盖全面** | 267 用例，6 种测试类型，零失败，质量有保障 |
| S6 | **文档体系完整** | 架构/使用/性能/CI/申报/推广 6 篇文档，与代码同步度高 |
| S7 | **迭代速度快** | 5-7 月两个月 7 个版本，持续跟进工具链 |
| S8 | **多平台部署** | 同时入驻 GitHub/GitLink/Gitee 三平台 |

### 3.1.2 不足（Weaknesses）

| # | 不足 | 改进方案 |
|---|------|----------|
| W1 | **"半实现"功能**：废弃密度硬编码、传递体积未接入 | PRD F01/F02 修复 |
| W2 | **无版本 Tag**：无任何 git tag，历史锚点缺失 | 本次迭代 v0.6.0 起规范化打 Tag |
| W3 | **版本号不一致**：CLI 显示 v0.5.0，实际 v0.5.3 | PRD F03 统一 |
| W4 | **无自动同步**：三平台靠手动 push，容易落后 | mirror-sync workflow 实现自动同步 |
| W5 | **演示效果单薄**：risky 示例只有一种风险场景 | PRD F06 增强 |
| W6 | **缺少全景视图**：没有 stats 类命令一眼看清项目全貌 | PRD F05 新增 stats 命令 |
| W7 | **首创功能展示不足**：废弃传播只有数量没有路径 | PRD F04 可视化 |
| W8 | **无预提交钩子**：依赖开发者自律 | 新增 .githooks/pre-commit |

### 3.1.3 机会（Opportunities）

| # | 机会 | 行动 |
|---|------|------|
| O1 | **9 月黑客松新增社区项目赛道** | 报名参赛，v0.6.0 迭代作为参赛成果 |
| O2 | **MoonBit 生态快速增长** | 包数量增长，依赖健康需求扩大 |
| O3 | **MoonBit 工具链持续演进** | AST parser、体积数据、async 等新能力可用时，实现 v0.7.0 路线图 |
| O4 | **国内开源社区活动** | GitLink/Gitee 平台国内曝光度高，同步+CI后可参加更多赛事 |
| O5 | **IDE 插件集成机会** | 未来可开发 VSCode 插件侧边栏展示 Depsight 报告 |

### 3.1.4 威胁（Threats）

| # | 威胁 | 应对 |
|---|------|------|
| T1 | **官方可能推出类似工具** | 深耕首创功能（废弃传播）、完善用户体验、积累用户群 |
| T2 | **mooncakes.io API 不开放** | 维持当前多源回退策略，增加更多包映射 |
| T3 | **MoonBit 工具链频繁变动** | 锁定 CI 版本，提交前用最新工具链验证，CHANGELOG 记录兼容版本 |
| T4 | **工具类项目被视为"不酷"** | 强化 stats 可视化、HTML 报告交互、传播路径展示，做"最美审计工具" |

---

## 3.2 非功能需求补充

以下补充到 PRD_v0.6.0.md 中。

### 3.2.1 性能需求

| 指标 | 小型项目 (5 节点) | 中型项目 (50 节点) | 大型项目 (200 节点) | 测量方法 |
|------|-------------------|-------------------|---------------------|----------|
| 图构建 | < 50 ms | < 200 ms | < 1 s | benchmark_test.mbt |
| 分析引擎 | < 20 ms | < 100 ms | < 500 ms | benchmark_test.mbt |
| 报告渲染 | < 100 ms | < 500 ms | < 2 s | benchmark_test.mbt |
| 端到端总耗时 | < 200 ms | < 1 s | < 5 s | E2E 定时测试 |
| 内存占用 | < 50 MB | < 100 MB | < 200 MB | Node --expose-gc |
| 新增功能性能退化 | ≤ 10% | ≤ 10% | ≤ 10% | 前后基准对比 |

### 3.2.2 兼容性需求

| 需求项 | 要求 |
|--------|------|
| MoonBit 工具链版本 | 兼容 latest（≥ 0.1.20260713），CHANGELOG 记录最低兼容版本 |
| Node.js 版本 | ≥ 18.x LTS，验证 18.x / 20.x / 22.x 三个 LTS |
| 操作系统 | Windows 10+ / macOS 12+ / Ubuntu 20.04+，三平台 CI 验证通过 |
| 终端兼容 | 支持 ANSI 颜色（Windows Terminal、iTerm2、Terminal.app、VSCode Terminal） |
| 回退兼容 | 关闭颜色输出时，纯文本输出无乱码 |

### 3.2.3 安全性需求

| 需求项 | 要求 |
|--------|------|
| 路径安全 | 所有文件读取使用白名单路径，不允许 `../` 路径穿越 |
| HTTP 请求 | 仅请求白名单域名（githubusercontent.com、api.github.com、mooncakes.io） |
| Token 保护 | CI 中所有 PAT 通过 Secrets 管理，绝不硬编码 |
| 缓存验证 | 缓存文件读取时校验 TTL，防止读取被篡改的过期内容 |
| 输入校验 | CLI 参数、配置文件内容全部做长度和字符校验 |
| 许可证合规 | 项目自身 Apache-2.0，依赖仅引入 moonbitlang/core（MIT/Apache 双许可） |

### 3.2.4 可用性需求

| 需求项 | 要求 |
|--------|------|
| 离线可用 | `--offline` 模式下完全不发起网络请求，功能降级正常 |
| 优雅降级 | 网络失败、文件读取失败时，给出清晰错误信息，不 crash |
| 帮助信息 | 所有命令支持 `--help`，输出清晰使用说明 |
| 退出码约定 | 0=成功，1=审计失败（score/critical 触发），2=参数错误，3=内部错误 |
| 诊断消息 | 每条诊断包含诊断码、严重级、描述、修复建议四要素 |

### 3.2.5 可维护性需求

| 需求项 | 要求 |
|--------|------|
| 模块化 | 新增输出格式 = 新增一个 `*_reporter.mbt`，不改主流程 |
| 可测试性 | I/O 通过接口抽象（FileSystem/Registry），支持 mock 单测 |
| 代码风格 | 所有 PR 通过 `moon fmt --check` + `--deny-warn` |
| 注释规范 | 公共 API 必须有 `///|` doc comment，复杂算法必须有中文步骤说明 |
| 单一职责 | 每个文件不超过 500 行，超长文件必须拆分 |

### 3.2.6 可扩展性需求

| 扩展点 | 设计 |
|--------|------|
| 新诊断维度 | 新增 `*_diagnoser.mbt` + 在 `run_analysis()` 中调用 + 健康评分权重可配置 |
| 新输出格式 | 实现 `render_*_report()` 函数 + 在 CLI 中注册 format 选项 |
| 新注册表源 | 实现 `Registry` trait，注册到 `fetch` 的多源回退列表 |
| 新命令 | 在 CLI 中注册命令名 + 新增 `run_<cmd>` 函数 |
| 自定义评分 | `.depsight.toml [scoring]` 配置权重，总和自动校验为 100 |

---

## 3.3 长期演进路线

### v0.6.x — 当前版本（9 月黑客松）

- ✨ 修复半实现功能（F01/F02/F03）
- ✨ 首创功能可视化（F04）
- ✨ stats 全景统计（F05）
- 🛠 多仓库自动同步
- 🛠 工程化全套升级

### v0.7.0 — AST 级能力增强

- 依赖：MoonBit parser 库可用
- 真正 AST 级 `@deprecated` 扫描（取代正则）
- 语法敏感度提升：参数废弃、变体废弃、trait 方法废弃
- 符号级 API 使用分析：检测你的代码实际调用了哪些废弃 API

### v0.8.0 — 智能升级建议

- `depsight upgrade` 命令：自动生成依赖升级建议
- 冲突检测：检测两个依赖是否依赖同一包的不兼容版本
- 版本图可视化：HTML 报告中展示每个包的可用版本图谱

### v0.9.0 — 并发与增量

- 依赖：MoonBit async 支持
- 并发 fetch 多个包元数据（200 节点从 5s → < 1s）
- 增量分析：缓存图构建结果，只重算变更部分

### v1.0.0 — GA 稳定版

- 稳定 API：所有公共接口冻结
- 完整文档站点（Docusaurus 或 VitePress）
- VSCode 扩展：侧边栏展示 Depsight 报告
- 官网 + Logo + 品牌设计

---

## 附录

### A. 关键配置文件清单

| 文件 | 用途 | 本次是否新增 |
|------|------|-------------|
| `.githooks/pre-commit` | 预提交检查脚本 | ✅ 新增 |
| `Makefile` | 统一构建入口 | ✅ 新增 |
| `.github/workflows/mirror-sync.yml` | 三平台镜像同步 | ✅ 新增 |
| `.github/workflows/release.yml` | 自动化发布 | ✅ 新增 |
| `.github/workflows/benchmark.yml` | 性能基准 | ✅ 新增 |
| `.github/workflows/ci.yml` | 主 CI（改造增强） | 🔧 改造 |
| `.gitlink-ci.yml` | GitLink 平台 CI | ✅ 新增 |
| `docs/PRD_v0.6.0.md` | 产品需求文档 | ✅ 已创建 |
| `docs/ENGINEERING_v0.6.0.md` | 本文档 | ✅ 已创建 |

### B. 三平台同步故障排查

| 现象 | 可能原因 | 解决 |
|------|---------|------|
| mirror-sync workflow 失败（GitLink） | PAT 过期或权限不足 | 重新生成 GitLink PAT，更新 GitHub Secrets |
| mirror-sync workflow 失败（Gitee） | 同分支名 master/main 冲突 | `git push ... main:main` 显式指定目标分支 |
| GitLink/Gitee 页面显示默认分支 master | 平台后台未改默认分支 | 仓库设置 → 基本信息 → 默认分支改为 main |
| 手动同步时出现 non-fast-forward | 镜像平台有人直接提交了代码 | 删除镜像平台的直接提交（应以 GitHub 为准），或用 `--force` 覆盖 |

### C. 术语表

| 术语 | 说明 |
|------|------|
| SSOT | Single Source of Truth，单一可信源（本项目指 GitHub） |
| Reverse-BFS | 反向广度优先搜索，废弃 API 传播检测的核心算法 |
| Transitive Size | 传递体积 = 自身 + 所有子孙依赖体积之和 |
| SARIF | Static Analysis Results Interchange Format，静态分析结果交换格式（GitHub Code Scanning 标准） |
| SemVer | Semantic Versioning，语义化版本号规范 |
| SPDX | Software Package Data Exchange，许可证标识符标准 |
