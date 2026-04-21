# Contributing to Mac Hacker Toolkit

Thank you for your interest in contributing to Mac Hacker Toolkit!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Bug Reports](#bug-reports)
- [Feature Requests](#feature-requests)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

**Expected Behavior:**
- Be respectful and inclusive
- Use welcoming and inclusive language
- Be constructive and collaborative
- Show empathy towards other contributors
- Focus on what is best for the community

**Unacceptable Behavior:**
- Harassment, discrimination, or intimidation
- Personal attacks or derogatory comments
- Publishing others' private information
- Other conduct that could reasonably be considered inappropriate

---

## Getting Started

### Fork the Repository

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mac_hacker_toolkit.git
   cd mac_hacker_toolkit
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/noktirnal42/mac_hacker_toolkit.git
   ```

### Understanding the Project

- **SwiftUI/Swift** - Primary development language
- **XcodeGen** - Project generation
- **150+ tools** - Integration with existing security tools

---

## Development Setup

### Prerequisites

```bash
# Install XcodeGen
brew install xcodegen

# Install required tools
brew install nmap masscan aircrack-ng bettercap hashcat
```

### Build the Project

```bash
# Generate Xcode project
xcodegen generate

# Build for Debug
xcodebuild -scheme MacHackerToolkit -configuration Debug build

# Build for Release
xcodebuild -scheme MacHackerToolkit -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Code Style

- Follow Swift API Design Guidelines
- Use Swift formatting (`swift format`)
- Maximum line length: 120 characters
- Use meaningful variable and function names

---

## Making Changes

### 1. Create a Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create a feature branch
git checkout -b feature/your-feature-name
# OR
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clean, commented code
- Add tests for new functionality
- Update documentation as needed
- Follow existing code style

### 3. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "Add: Brief description of changes

- Detailed bullet points if needed
- Reference issue numbers: Fixes #123"
```

### 4. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

---

## Pull Request Process

### Before Submitting

1. **Test your changes**
   ```bash
   xcodebuild -scheme MacHackerToolkit -configuration Debug build
   ```

2. **Update documentation**
   - Add comments to new code
   - Update README if needed
   - Add usage examples for new features

3. **Check for lint issues**
   ```bash
   swiftlint lint
   ```

### PR Description Template

```markdown
## Summary
Brief description of changes

## Motivation
Why is this change needed?

## Changes Made
- List of specific changes
- Screenshots if UI changes

## Testing
How was this tested?

## Checklist
- [ ] Code follows style guidelines
- [ ] Code is commented
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. Maintainers will review your PR
2. Address any feedback
3. Once approved, maintainers will merge

### PR Requirements

- ✅ Passes all CI checks
- ✅ Code follows style guidelines
- ✅ Tests pass
- ✅ Documentation updated
- ✅ No merge conflicts

---

## Bug Reports

Please report bugs via [GitHub Issues](https://github.com/noktirnal42/mac_hacker_toolkit/issues).

### Bug Report Template

```markdown
## Description
Clear description of the bug

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- macOS version:
- App version:
- Xcode version:

## Crash Log (if applicable)
Paste crash log here

## Additional Context
Any other context about the problem
```

---

## Feature Requests

We welcome feature requests! Please submit via [GitHub Discussions](https://github.com/noktirnal42/mac_hacker_toolkit/discussions).

### Feature Request Template

```markdown
## Feature Name
Short, descriptive name

## Problem Statement
What problem does this solve?

## Proposed Solution
How would you solve it?

## Use Cases
List specific use cases

## Alternatives Considered
What alternatives were considered?

## Additional Context
Screenshots, mockups, or other information
```

---

## Project Structure

```
MacHackerToolkit/
├── Sources/
│   ├── App/              # App entry point
│   ├── Models/           # Data models
│   ├── Services/         # Core services
│   │   ├── ToolManager.swift
│   │   ├── AIOrchestrator.swift
│   │   ├── HardwareMonitor.swift
│   │   ├── AuditLogger.swift
│   │   ├── PluginManager.swift
│   │   └── UpdateManager.swift
│   ├── Views/            # SwiftUI views
│   │   ├── Dashboard/
│   │   ├── AI/
│   │   ├── Tools/
│   │   ├── Forensics/
│   │   └── ...
│   ├── Protocols/        # Protocol definitions
│   └── Utilities/        # Helper utilities
└── ...
```

---

## Labels

We use labels to categorize issues and PRs:

| Label | Description |
|-------|-------------|
| `bug` | Bug reports |
| `enhancement` | New features |
| `documentation` | Documentation improvements |
| `good first issue` | Beginner-friendly tasks |
| `help wanted` | Assistance needed |
| `question` | Questions/discussions |
| `security` | Security-related |

---

## Recognition

Contributors will be recognized in:
- Release notes
- CONTRIBUTORS file
- [GitHub Contributors](https://github.com/noktirnal42/mac_hacker_toolkit/graphs/contributors) page

---

## Questions?

- **GitHub Discussions**: For questions about using the project
- **GitHub Issues**: For bug reports and feature requests
- **Email**: Contact maintainers via GitHub

---

Thank you for contributing to Mac Hacker Toolkit! 🎉