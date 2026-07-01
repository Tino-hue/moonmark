# Security Policy

## Supported Versions

The following versions of MoonBit Depsight receive security updates:

| Version | Supported          |
|---------|--------------------|
| 0.5.x   | :white_check_mark: Yes (current) |
| < 0.5.0 | :x: No             |

## Reporting a Vulnerability

We take the security of MoonBit Depsight seriously. If you discover a security vulnerability, please report it privately.

### How to Report

**Please DO NOT file a public GitHub issue for security vulnerabilities.**

Instead, please report security issues via one of the following channels:

1. **GitHub Security Advisories** (preferred)
   Navigate to https://github.com/Tino-hue/moonmark/security/advisories/new
   and submit a private security advisory.

2. **Email**
   Contact the maintainer via the email address listed on their GitHub profile.

### What to Include

When reporting a vulnerability, please include:

- A clear description of the issue and its impact
- Steps to reproduce the vulnerability
- Affected version(s)
- Your assessment of severity (low / medium / high / critical)
- Any potential mitigations or workarounds you have identified
- Your name / handle (for credit in the fix announcement, optional)

### Response Timeline

- **Initial acknowledgment**: within 3 business days
- **Status update**: within 7 business days
- **Fix timeline**: depends on severity
  - Critical: ASAP (typically within 7 days)
  - High: within 30 days
  - Medium / Low: next regular release

### Disclosure Policy

We follow coordinated disclosure:
- We will work with you to understand the issue
- We will develop and test a fix
- We will release the fix in a new version
- After the fix is released, we will publicly disclose the vulnerability with credit to the reporter (unless anonymity is requested)

## Security Considerations

MoonBit Depsight is a CLI tool that:
- Reads local `moon.mod` files (no network access by default)
- Optionally fetches package metadata from GitHub raw URLs and mooncakes.io
- Writes report files to the local filesystem

When using Depsight in CI/CD pipelines:
- Use `--offline` flag if you do not want to make network requests
- Review `--cache-dir` paths to ensure no sensitive data is cached
- Be cautious when running audit reports on untrusted projects

## Acknowledgments

We appreciate the security community's efforts in responsibly disclosing vulnerabilities. Contributors who report valid security issues will be credited (with permission) in the fix release notes.
