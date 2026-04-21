# Contributing to MacOS Hacker Toolkit

## Welcome!

Thank you for your interest in contributing to the MacOS Hacker Toolkit. We welcome contributions from security researchers, developers, and designers who want to build the ultimate security suite for macOS.

## How to Contribute

### 1. Reporting Bugs
If you find a bug, please open an issue on GitHub:
- Use a descriptive title.
- Provide a detailed description of the bug.
- Include steps to reproduce the issue.
- Specify your macOS version and hardware (M1, M2, M3, Intel).
- Attach logs or screenshots if applicable.

### 2. Suggesting Enhancements
Have an idea for a new tool or a feature?
- Open an issue with the label `enhancement`.
- Explain why the feature would be useful.
- Provide examples of how it should work.
- Suggest possible tools or libraries to implement it.

### 3. Adding New Tools
To add a new security tool to the toolkit:
- Ensure the tool is compatible with macOS.
- Create a SwiftUI wrapper if the tool is CLI-only.
- Update the `tool-catalog.md` with the tool's details.
- Implement the `CommandBuilder` protocol for parameter construction.
- Add an optional AI enhancement using the `AIEnhancement` protocol.

### 4. Improving AI/ML Capabilities
We are always looking for ways to make the toolkit smarter:
- Contribute new CoreML models for security tasks.
- Improve LLM prompts for better vulnerability analysis.
- Develop new LangChain workflows for automation.
- Benchmarking local LLMs for security performance on Apple Silicon.

## Development Workflow

### Prerequisites
- macOS 14.0+
- Xcode 15+
- Homebrew
- Git

### Setup
1. Fork the repository.
2. Clone your fork locally.
3. Install dependencies using `./scripts/install-dependencies.sh`.
4. Create a new branch for your feature: `git checkout -b feature/my-awesome-tool`.

### Commit Guidelines
We follow the Conventional Commits specification:
- `feat: add x-ray scanning tool`
- `fix: resolve memory leak in wireshark wrapper`
- `docs: update tool catalog for v1.2`
- `refactor: optimize Ollama API client`
- `test: add integration tests for nmap`

### Pull Request Process
1. Push your changes to your fork.
2. Open a Pull Request (PR) to the `main` branch.
3. Provide a clear description of your changes and why they are beneficial.
4. Link any related issues (e.g., `Fixes #123`).
5. Ensure all tests pass and the code follows our style guide.
6. Respond to reviewer feedback and make necessary changes.

## Code of Conduct

We are committed to providing a welcoming and inclusive community. All contributors are expected to:
- Be respectful and kind to others.
- Use inclusive language.
- Avoid harassment and discrimination.
- Collaborate constructively.

Contributions that violate our code of conduct will be removed, and the contributor may be banned from the project.

## License

By contributing to this project, you agree that your contributions will be licensed under the project's main license (see `LICENSE` file).

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-15  
**Maintainers**: MacOS Hacker Toolkit Team
