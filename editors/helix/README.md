# MoonBit Highlight for Helix

Tree-sitter powered syntax highlighting for MoonBit in Helix editor.

## Prerequisites

- Helix 23.10+ (24.03+ recommended for best tree-sitter support)
- Git (for downloading the grammar)
- C compiler (gcc/clang/msvc) for building the parser

## Installation

### Step 1: Add language configuration

Copy `helix.toml` to your Helix languages config:

```bash
# Linux/macOS
cp editors/helix.toml ~/.config/helix/languages.toml

# Windows
copy editors\helix.toml %APPDATA%\helix\languages.toml
```

### Step 2: Install queries

Helix loads tree-sitter queries from its runtime directory. You need to copy the query files:

```bash
# Find Helix runtime directory
hx --health | grep "Runtime dir"

# Typical locations:
# Linux:   ~/.config/helix/runtime/
# macOS:   ~/Library/Application Support/helix/runtime/
# Windows: %APPDATA%\helix\runtime\

# Create query directory and copy files
mkdir -p <helix-runtime>/queries/moonbit
cp queries/highlights.scm <helix-runtime>/queries/moonbit/
cp queries/indents.scm    <helix-runtime>/queries/moonbit/
cp queries/locals.scm     <helix-runtime>/queries/moonbit/
cp queries/injections.scm <helix-runtime>/queries/moonbit/
```

Or use the provided PowerShell/Bash helper scripts below.

### Step 3: Build the grammar

Open Helix and run:

```vim
:fetch-grammars
```

Or from command line:

```bash
hx --grammar fetch
hx --grammar build
```

### Step 4: Verify

Check if MoonBit is recognized:

```bash
hx --health moonbit
```

Open a `.mbt` file and you should see syntax highlighting.

## Query Compatibility

Helix uses the same tree-sitter query syntax as Neovim. The captures in our queries are compatible:

- `@keyword`, `@type`, `@function`, `@variable`, `@string`, `@number`, `@comment`, etc.
- `@indent` / `@dedent` for indentation
- `@definition.*` / `@reference` for locals/scopes

## Helper Scripts

### Bash (Linux/macOS)

```bash
HELIX_RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/helix/runtime"
mkdir -p "$HELIX_RUNTIME/queries/moonbit"
cp queries/*.scm "$HELIX_RUNTIME/queries/moonbit/"
echo "MoonBit queries installed to $HELIX_RUNTIME/queries/moonbit"
```

### PowerShell (Windows)

```powershell
$HelixRuntime = "$env:APPDATA\helix\runtime"
New-Item -ItemType Directory -Force -Path "$HelixRuntime\queries\moonbit"
Copy-Item "queries\*.scm" "$HelixRuntime\queries\moonbit\"
Write-Host "MoonBit queries installed to $HelixRuntime\queries\moonbit"
```

## Troubleshooting

### Grammar fetch fails

Ensure the `git` command is in your PATH. Check with:

```bash
hx --grammar fetch
```

If it fails, manually clone the repo and point `languages.toml` to the local path:

```toml
[language.grammar]
source = { path = "/path/to/moonmark/src" }
```

### No highlighting after install

1. Check `hx --health moonbit` for errors
2. Ensure queries are in the correct runtime directory
3. Try rebuilding: `hx --grammar build`

### Block comment not working

Helix 23.10+ supports `block-comment-tokens`. Ensure your Helix version is up to date.

## Development

Test queries locally:

```bash
tree-sitter query queries/highlights.scm examples/demo.mbt
tree-sitter query queries/indents.scm examples/demo.mbt
tree-sitter query queries/locals.scm examples/demo.mbt
```
