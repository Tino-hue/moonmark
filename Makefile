# =============================================================================
# MoonBit Depsight — 统一构建入口
# =============================================================================
# 用法：
#   make <target>
#
# Windows 用户：
#   - 方案 A：choco install make  (使用 Chocolatey)
#   - 方案 B：winget install GnuWin32.Make
#   - 方案 C：直接复制下面的 moon 命令手动执行
#
# 主要目标：
#   make all          → 完整开发流程（默认）
#   make precommit    → 提交前检查（最常用）
#   make release-check→ 发布前全量检查
#   make build-release→ 构建生产版 bundle
#   make example-*    → 运行三个示例项目审计
#   make sync         → 手动同步到 GitLink/Gitee
# =============================================================================

SHELL := /bin/bash

.PHONY: all check fmt fmt-fix info test test-all build build-release \
        clean example-healthy example-outdated example-risky \
        precommit release-check sync help

# -----------------------------------------------------------------------------
# 默认目标：完整开发流程
# -----------------------------------------------------------------------------
all: check fmt info test build

help:
	@echo "MoonBit Depsight — 统一构建入口"
	@echo ""
	@echo "主要目标："
	@echo "  make all              完整开发流程 (check + fmt + info + test + build)"
	@echo "  make precommit        提交前快速检查 (check + fmt + test)"
	@echo "  make release-check    发布前全量检查"
	@echo ""
	@echo "代码质量："
	@echo "  make check            类型检查（--deny-warn，警告当错误）"
	@echo "  make fmt              格式检查"
	@echo "  make fmt-fix          自动修复格式"
	@echo "  make info             生成接口文件 (.mbti)"
	@echo ""
	@echo "测试："
	@echo "  make test             单元+集成+E2E 测试（跳过性能基准）"
	@echo "  make test-all         全量测试（含性能基准，30-60 秒）"
	@echo ""
	@echo "构建："
	@echo "  make build            构建 JS bundle（debug 模式）"
	@echo "  make build-release    构建生产版 bundle（体积更小）"
	@echo "  make clean            清理构建产物"
	@echo ""
	@echo "示例演示："
	@echo "  make example-healthy  审计 healthy_project 示例"
	@echo "  make example-outdated 审计 outdated_project 示例"
	@echo "  make example-risky    审计 risky_project 示例"
	@echo ""
	@echo "发布 / 同步："
	@echo "  make sync             手动同步 main + tags 到 GitLink/Gitee"
	@echo "  make release-check    发布前全量检查"

# -----------------------------------------------------------------------------
# 代码质量检查
# -----------------------------------------------------------------------------

## 类型检查（警告当错误）
check:
	@echo "▶ moon check --target js --deny-warn"
	@moon check --target js --deny-warn

## 格式检查
fmt:
	@echo "▶ moon fmt --check"
	@moon fmt --check

## 自动修复格式
fmt-fix:
	@echo "▶ moon fmt（自动修复格式）"
	@moon fmt

## 生成接口文件
info:
	@echo "▶ moon info（生成 .mbti 接口文件）"
	@moon info

# -----------------------------------------------------------------------------
# 测试
# -----------------------------------------------------------------------------

## 常规测试（跳过性能基准）
test:
	@echo "▶ moon test --target js（跳过性能基准）"
	@moon test --target js

## 全量测试（含性能基准）
test-all:
	@echo "▶ moon test --target js --no-skip（全量，含性能基准）"
	@moon test --target js --no-skip

# -----------------------------------------------------------------------------
# 构建
# -----------------------------------------------------------------------------

## 构建 debug 版 JS bundle
build:
	@echo "▶ moon build --target js"
	@moon build --target js

## 构建 release 版 JS bundle（体积更小）
build-release:
	@echo "▶ moon build --target js --release"
	@moon build --target js --release

## 清理构建产物
clean:
	@echo "▶ 清理构建产物"
	@rm -rf _build/ 2>/dev/null || true
	@rm -rf core/ 2>/dev/null || true
	@rm -f trace.json 2>/dev/null || true

# -----------------------------------------------------------------------------
# 示例项目演示
# -----------------------------------------------------------------------------

DEPSIGHT_JS := _build/js/debug/build/depsight.js

example-healthy: build
	@echo "━━━ 审计 examples/healthy_project ━━━"
	@node $(DEPSIGHT_JS) audit --target-pkg examples/healthy_project

example-outdated: build
	@echo "━━━ 审计 examples/outdated_project ━━━"
	@node $(DEPSIGHT_JS) audit --target-pkg examples/outdated_project

example-risky: build
	@echo "━━━ 审计 examples/risky_project ━━━"
	@node $(DEPSIGHT_JS) audit --target-pkg examples/risky_project

# 一键运行全部三个示例
examples: example-healthy example-outdated example-risky

# -----------------------------------------------------------------------------
# 快捷组合
# -----------------------------------------------------------------------------

## 预提交检查（开发者本地）
precommit: check fmt test
	@echo ""
	@echo "✅ 预提交检查全部通过：check + fmt + test"

## 发布前全量检查
release-check: check fmt info test-all build-release example-healthy
	@echo ""
	@echo "✅ 发布检查全部通过，可以打 tag 发布 v0.6.0"

# -----------------------------------------------------------------------------
# 多仓库同步（手动）
# -----------------------------------------------------------------------------

## 手动同步 main + stable + tags 到 GitLink / Gitee
sync:
	@echo "━━━ 同步到 GitLink ━━━"
	-git push gitlink main:main
	-git push gitlink stable:stable 2>/dev/null || echo "  [skip] stable 分支暂未创建"
	-git push gitlink --tags
	@echo ""
	@echo "━━━ 同步到 Gitee ━━━"
	-git push gitee main:main
	-git push gitee stable:stable 2>/dev/null || echo "  [skip] stable 分支暂未创建"
	-git push gitee --tags
	@echo ""
	@echo "✅ 同步完成"
