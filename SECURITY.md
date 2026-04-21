# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via:

1. **GitHub Security Advisories** - For vulnerabilities in the application code
2. **Email** - For sensitive vulnerabilities: `security@example.com`

### What to Include

When reporting a vulnerability, please include:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/commit/direct line reference)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue including how it could be exploited

### Response Timeline

- **Initial Response**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix Development**: Depends on severity
- **Disclosure**: Coordinated with reporter

## Security Features

### Audit Logging

All operations are logged with:
- Timestamp
- User action
- Affected resources
- AES-256 encryption for sensitive logs

### Sandboxed Tool Execution

Tools run in isolated environments:
- Limited filesystem access
- Network restrictions
- Resource limits

### Data Privacy

- **No cloud connectivity required** - All processing is local
- **AI data stays on device** - Ollama runs locally
- **No telemetry** - No data collection without consent

## Security Best Practices

When using Mac Hacker Toolkit:

1. **Only test systems you own or have written authorization to test**
2. **Keep the application updated** - Use latest version
3. **Review audit logs regularly**
4. **Use least-privilege principles** - Run with minimal required permissions
5. **Secure your wordlists and captured data** - Use encryption

## Known Limitations

- Some security tools require root/sudo privileges
- Wi-Fi monitor mode may be limited on Apple Silicon with certain adapters
- External USB Wi-Fi adapters recommended for full monitor mode support

## Encryption

Sensitive data is encrypted using:
- **AES-256-GCM** for data at rest
- **HMAC-SHA256** for integrity verification
- **PBKDF2** for key derivation

## Updates

Security updates will be released as:
- **Patch releases** (e.g., 1.0.1) for bug fixes
- **Version bumps** for significant security changes

We encourage all users to enable automatic updates or check the [Releases page](https://github.com/noktirnal42/mac_hacker_toolkit/releases) regularly.