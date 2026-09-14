# MoonBit Depsight Examples

This directory contains three example MoonBit projects demonstrating
different dependency health scenarios that `depsight` can analyze.

Each example is a MoonBit module descriptor (`moon.mod` or `moon.mod.json`)
— a test fixture that exercises a particular class of dependency health
issue. They are designed to be analyzed by `depsight`, not built as
standalone MoonBit binaries.

## Examples

### `healthy_project/`
A minimal MoonBit project with only the standard library as a dependency.
`depsight` should report a high health score and no diagnostics.

```bash
cd examples/healthy_project
node ../../_build/js/debug/build/depsight.js audit --fail-on-score 80
```

### `outdated_project/`
A project that depends on `moonbitlang/x@0.2.0` via a versioned TOML
`import { ... }` block. This exercises `parse_mod_toml` import-block
parsing: `moonbitlang/x` is added as a real dependency node (its
unversioned sibling `moonbitlang/core` is skipped). `OUTDATED-001` is
demonstrated in `risky_project/` below, where a mock registry supplies a
newer `_latest_version`.

```bash
cd examples/outdated_project
node ../../_build/js/debug/build/depsight.js audit --json
```

### `risky_project/`
A fully offline fixture using a local `.mooncakes` mock registry. It
triggers six diagnostic codes: `CYCLE-001`, `LICENSE-001`, `LICENSE-002`,
`DEPRECATED-001`, `DEPRECATED-002`, and `OUTDATED-001` (via
`risky/outdated-lib` whose mock `_latest_version` is `2.0.0`).

```bash
cd examples/risky_project
node ../../_build/js/debug/build/depsight.js audit --offline --json
```

## Notes

- These fixtures are not intended to be `moon build`-able MoonBit
  binaries. They exist so `depsight` can demonstrate how it scores
  different real-world dependency configurations.
- Run the example audits with `--offline` where noted to avoid network
  lookups; `risky_project` is fully self-contained and never touches the
  network.
