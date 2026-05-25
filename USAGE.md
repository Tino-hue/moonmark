# Usage Guide — MoonBit Depsight

## Installation

```bash
moon add LittleFish/depsight
```

## Commands

### `depsight tree [package]`

Show the dependency tree for a package.

```bash
# Show full dependency tree
depsight tree my-package

# Limit tree depth
depsight tree my-package --depth 3
```

### `depsight audit`

Run a dependency health audit.

```bash
# Terminal output (default)
depsight audit

# JSON output for CI/CD
depsight audit --json

# CI integration: fail if health score < 80
depsight audit --fail-on-score 80

# CI integration: fail if critical issues found
depsight audit --fail-on-critical
```

### `depsight report`

Generate a full diagnostic report.

```bash
# Terminal report (default)
depsight report

# HTML report with interactive dependency tree
depsight report --html -o report.html

# JSON report
depsight report --json
```

## Global Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help message |
| `-v`, `--version` | Show version |
| `--offline` | Use local cache only, no network requests |
| `--cache-dir <path>` | Specify cache directory |
| `--depth <n>` | Max dependency tree depth (default: 10) |

## Health Score Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Version Freshness | 25% | Distance between current and latest version |
| License Compliance | 20% | Presence of high-risk copyleft licenses |
| Deprecated API Density | 25% | Ratio of deprecated APIs to total public APIs |
| Size Reasonableness | 20% | Transitive dependency size within acceptable range |
| Maintenance Activity | 10% | Repository commit/release activity (reserved) |

## Output Formats

### Terminal (default)

Color-coded output grouped by severity:
- **Critical** (red): Cycle detection, high-risk licenses
- **Warning** (yellow): Outdated versions, deprecated APIs
- **Info** (green): No issues found

### HTML (`--html`)

Single-file interactive report with:
- Overview dashboard with overall health score
- Collapsible dependency tree
- Detailed diagnostics table with suggestions

### JSON (`--json`)

Structured output for CI/CD pipelines:
```json
{
  "overall_score": 85,
  "node_count": 12,
  "diagnostics": [...],
  "health_scores": [...],
  "summary": { "critical": 0, "warning": 2, "info": 5 }
}
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Dependency Audit
  run: |
    moon run depsight audit --fail-on-score 80 --fail-on-critical
```

### GitLink CI

```yaml
- name: Dependency Audit
  script: |
    moon run depsight audit --fail-on-score 80 --fail-on-critical
```
