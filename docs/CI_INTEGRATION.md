# CI/CD 集成指南

Depsight 专为 CI 场景设计，支持结构化 JSON 输出和可配置的退出码。

## GitHub Actions

```yaml
name: Depsight Audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH

      - name: Build Depsight
        run: moon build --target js

      - name: Run Dependency Audit
        run: node _build/js/debug/build/depsight.js audit --json -o audit.json

      - name: Upload Audit Report
        uses: actions/upload-artifact@v4
        with:
          name: depsight-audit
          path: audit.json
```

### 带阈值的严格模式

```yaml
      - name: Run Dependency Audit (strict)
        run: node _build/js/debug/build/depsight.js audit --fail-on-score 80 --fail-on-critical
```

当健康分低于 80 或发现 critical 问题时，CI 会失败。

### HTML 报告上传

```yaml
      - name: Generate HTML Report
        run: node _build/js/debug/build/depsight.js report --html -o depsight-report.html

      - name: Upload HTML Report
        uses: actions/upload-artifact@v4
        with:
          name: depsight-report
          path: depsight-report.html
```

## GitLink CI

```yaml
stages:
  - build
  - audit

build:
  stage: build
  image: moonbitlang/moonbit:latest
  script:
    - moon build --target js
  artifacts:
    paths:
      - _build/js/debug/build/depsight.js

audit:
  stage: audit
  image: node:20
  script:
    - node _build/js/debug/build/depsight.js audit --fail-on-score 80
```

## 本地预提交钩子

```bash
#!/bin/sh
# .git/hooks/pre-commit

node _build/js/debug/build/depsight.js audit --fail-on-critical
if [ $? -ne 0 ]; then
  echo "Critical dependency issues found. Commit aborted."
  exit 1
fi
```

## JSON 输出格式

```json
{
  "overall_score": 96,
  "node_count": 4,
  "diagnostics": [
    {
      "level": "Info",
      "code": "LICENSE-002",
      "message": "No license info: root@1.0.0",
      "path": ["root@1.0.0"],
      "suggestions": []
    }
  ],
  "health_scores": [
    {
      "node_id": "root@1.0.0",
      "total": 96,
      "freshness": 100,
      "compliance": 80,
      "deprecated_density": 100,
      "size_reasonableness": 100,
      "activity": 100
    }
  ],
  "summary": {
    "critical": 0,
    "warning": 0,
    "info": 4
  }
}
```
