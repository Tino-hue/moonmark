# MoonBit Depsight

A dependency health diagnostic tool for the MoonBit ecosystem.

## Overview

MoonBit Depsight analyzes your `moon.mod.json` and recursively inspects the entire transitive dependency tree to surface risks before they become problems.

## Features (Roadmap)

- **Dependency Tree Visualization**: Recursive resolution of transitive dependencies from mooncakes.io
- **Size Attribution**: Identify which packages bloat your final build artifact
- **Deprecated API Detection**: Cross-package tracking of `@deprecated` usage across dependency layers
- **License Compliance**: Automatic SPDX license identification and copyleft conflict warnings
- **Health Scoring**: Quantified 0-100 health score per package based on version freshness, license compatibility, deprecated API density, and maintenance activity

## Installation

```bash
moon add LittleFish/depsight
```

## Usage

```bash
# Show dependency tree
depsight tree

# Run full audit
depsight audit

# Generate HTML report
depsight report --html -o report.html
```

## Development

```bash
# Build for JS target
moon build --target js

# Run tests
moon test --target js
```

## License

Apache-2.0
