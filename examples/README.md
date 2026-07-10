# MoonBit Depsight Examples

This directory contains three example MoonBit projects demonstrating
different dependency health scenarios that `depsight` can analyze.

Each example is a MoonBit module descriptor (`moon.mod`) 鈥?a test fixture
that exercises a particular class of dependency health issue. They are
designed to be analyzed by `depsight`, not built as standalone MoonBit
binaries.

## Examples

### `healthy_project/`
A minimal MoonBit project with only the standard library as a dependency.
`depsight` should report a high health score and no diagnostics.

```bash
moon run --target js . -- tree --workspace examples/healthy_project
moon run --target js . -- audit --workspace examples/healthy_project
```

### `outdated_project/`
A project that depends on an old version of `moonbitlang/x`. `depsight`
should surface an `OUTDATED-001` diagnostic pointing to the available
newer version.

```bash
moon run --target js . -- tree --workspace examples/outdated_project
moon run --target js . -- outdated --workspace examples/outdated_project
```

### `risky_project/`
A project whose dependencies may trigger copyleft / deprecated-API
diagnostics depending on the data `depsight` is able to fetch from
public registries at audit time.

```bash
moon run --target js . -- audit --workspace examples/risky_project
```

## Notes

- These fixtures are not intended to be `moon build`-able MoonBit
  binaries. They exist so `depsight` can demonstrate how it scores
  different real-world dependency configurations.
- All three use Apache-2.0 / MIT-licensed mock dependencies that are
  resolvable from `https://mooncakes.io/`.