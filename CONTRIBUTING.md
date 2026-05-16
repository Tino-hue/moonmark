# Contributing to MoonMark 🌙

Thank you for your interest in contributing to MoonMark! This document outlines how to participate in the development of this project.

## Development Setup

### Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.cn/download/) (v0.1.33+)
- Git
- A code editor (VS Code with MoonBit extension recommended)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/Tino-hue/moonmark.git
cd moonmark

# Build the project
moon build

# Run tests
moon test

# Run examples
moon run examples/usage.mbt
```

## Project Structure

```
moonmark/
├── src/
│   ├── lib.mbt            # Main entry point, public API
│   ├── ast.mbt            # AST type definitions
│   ├── lexer.mbt          # Tokenizer (Phase 1)
│   ├── block_parser.mbt   # Block-level parser (Phase 2)
│   ├── inline_parser.mbt  # Inline parser (Phase 3)
│   └── html_renderer.mbt  # HTML output (Phase 4)
├── test/
│   └── suite.mbt          # CommonMark compliance tests
├── examples/
│   └── usage.mbt          # Usage examples
├── README.md              # Project documentation
├── LICENSE                # MIT License
└── moon.json              # Package manifest
```

## Coding Conventions

- Follow MoonBit's official [style guide](https://www.moonbitlang.cn/docs/style-guide/)
- Use `pub` for public API functions and types
- Add doc comments (`///`) to all public functions
- Keep functions focused and under 50 lines when possible
- Use pattern matching over if/else chains for enum types

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes with clear commit messages
4. Ensure all tests pass: `moon test`
5. Push to your fork and open a Pull Request

### Commit Message Format

```
type: brief description

Detailed explanation if needed.
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Testing

All CommonMark test cases live in `test/suite.mbt`. When adding new features:

1. Add test cases covering the new functionality
2. Verify existing tests still pass
3. Include edge cases and error conditions

## Reporting Bugs

If you find a Markdown input that produces incorrect HTML:

1. Check against the [CommonMark demo](https://spec.commonmark.org/demo/)
2. Open an issue with:
   - The input Markdown
   - Expected output (per spec)
   - Actual output from MoonMark

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

*Happy parsing! 🌙*
