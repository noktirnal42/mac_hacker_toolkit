# Mac Hacker Toolkit

<div align="center">

![Mac Hacker Toolkit](https://img.shields.io/badge/Version-1.0.3-blue.svg)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-green.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-purple.svg)

**A comprehensive security testing suite for macOS with AI-powered analysis**

[Features](#features) • [Installation](#installation) • [Quick Start](#quick-start) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## 🎯 Overview

Mac Hacker Toolkit is a professional-grade security testing application built natively for macOS. It provides security researchers, penetration testers, and system administrators with over **150+ security tools** organized into an intuitive graphical interface with deep **AI/ML integration** for advanced threat detection and analysis.

### Key Differentiators

- **Native macOS Application** — Built with SwiftUI for optimal performance and native macOS experience
- **AI-Powered Analysis** — Local LLM integration via Ollama for privacy-preserving AI analysis
- **Apple Silicon Optimized** — Hardware-accelerated ML via CoreML and Neural Engine
- **150+ Security Tools** — Pre-configured integration with industry-standard security tools
- **Modern UI/UX** — Glassmorphism design with real-time monitoring dashboards

---

## ✨ Features

### 📡 Network Security

| Tool | Description |
|------|-------------|
| **Nmap** | Network discovery and security auditing |
| **Masscan** | Fast TCP port scanner |
| **Wireshark** | Packet capture and protocol analysis |
| **RustScan** | Modern port scanner |

### 📶 Wi-Fi & Wireless

| Tool | Description |
|------|-------------|
| **Aircrack-ng Suite** | Wi-Fi network security testing |
| **Kismet** | Wireless detector and intrusion detection |
| **Wifite2** | Automated wireless attack tool |

### 🔵 Bluetooth Security

| Tool | Description |
|------|-------------|
| **Bettercap** | BLE and Bluetooth Classic testing |
| **Ubertooth** | SDR-based Bluetooth monitoring |
| **Btlejuice** | Bluetooth Low Energy proxy |

### 💥 Exploitation

| Tool | Description |
|------|-------------|
| **Metasploit** | Penetration testing framework |
| **Empire** | PowerShell and Python post-exploitation |
| **Covenant** | .NET command and control framework |

### 🔍 Digital Forensics

| Tool | Description |
|------|-------------|
| **Autopsy** | Digital forensics platform |
| **Volatility** | Memory forensics framework |
| **Binwalk** | Firmware analysis tool |

### ⚙️ Reverse Engineering

| Tool | Description |
|------|-------------|
| **Ghidra** | Software reverse engineering framework |
| **Radare2** | Command-line hex editor and debugger |
| **Frida** | Dynamic instrumentation toolkit |
| **Hopper** | macOS disassembler |

### 🔐 Password Security

| Tool | Description |
|------|-------------|
| **Hashcat** | Fast password cracker |
| **John the Ripper** | Password cracking tool |
| **Hydra** | Network login cracker |

### 🤖 AI/ML Security

| Feature | Description |
|---------|-------------|
| **Ollama Integration** | Local LLM for privacy-preserving analysis |
| **CoreML Models** | On-device anomaly detection |
| **LangChain Workflows** | Multi-step automated vulnerability analysis |
| **AI Assistant** | Context-aware security expert chat |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mac Hacker Toolkit UI                        │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐  │
│  │Dashboard│ │  AI Hub  │ │ Network │ │Wireless│ │Forensics │  │
│  └────┬────┘ └────┬─────┘ └────┬────┘ └───┬────┘ └────┬─────┘  │
└───────┼───────────┼────────────┼──────────┼───────────┼────────┘
        │           │            │          │           │
┌───────┴───────────┴────────────┴──────────┴───────────┴────────┐
│                      Service Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ToolManager  │  │AIOrchestrator│ │  HardwareMonitor        │ │
│  │(150+ tools) │  │(Ollama/CoreML)│ │(WiFi/BT/GPU/SDR)       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │AuditLogger  │  │PluginManager│  │  UpdateManager          │ │
│  │(AES-256)    │  │(Sandboxing) │  │  (Auto-update)          │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
        │                       │                    │
┌───────┴───────────────────────┴────────────────────┴───────────┐
│                    System Integration                           │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ CoreWLAN │  │IOBluetooth│  │  IOKit   │  │   Metal/GPU   │  │
│  │ (Wi-Fi)  │  │ (BT)      │  │ (System) │  │   (ML)        │  │
│  └──────────┘  └───────────┘  └──────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **macOS** | 14.0 (Sonoma) | 14.0+ |
| **RAM** | 8 GB | 16 GB |
| **Storage** | 2 GB | 10 GB |
| **Processor** | Apple Silicon M1 | M2/M3/M4 |
| **Xcode** | 15.0 | 16.0+ |

### Required Dependencies

- [Homebrew](https://brew.sh) — Package manager
- [Ollama](https://ollama.ai) — Local LLM inference (optional but recommended)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — Project generation

---

## 🚀 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/noktirnal42/mac_hacker_toolkit.git
cd mac_hacker_toolkit

# Install dependencies
./scripts/install.sh

# Generate Xcode project and build
xcodegen generate
xcodebuild -scheme MacHackerToolkit -configuration Release build

# Launch the app
open /Users/$USER/Library/Developer/Xcode/DerivedData/MacHackerToolkit-*/Build/Products/Release/MacHackerToolkit.app
```

### DMG Installation

Download the latest release from the [Releases page](https://github.com/noktirnal42/mac_hacker_toolkit/releases):

```bash
# Mount the DMG
hdiutil attach MacHackerToolkit-*.dmg

# Copy to Applications
cp -R /Volumes/Mac\ Hacker\ Toolkit/MacHackerToolkit.app /Applications/

# Eject the DMG
hdiutil detach /Volumes/Mac\ Hacker\ Toolkit
```

### First-Time Setup

```bash
# Install all security tools
./scripts/install.sh

# Install Ollama for AI features (optional but recommended)
brew install ollama

# Pull recommended AI models
ollama pull mistral
ollama pull llama3
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](INSTALLATION.md) | Detailed installation and setup guide |
| [USAGE.md](USAGE.md) | How to use each feature of the toolkit |
| [ARCHITECTURE.md](docs/architecture.md) | Technical architecture documentation |
| [TOOL-CATALOG.md](docs/tool-catalog.md) | Complete list of 150+ security tools |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

---

## 🔧 Building from Source

### Prerequisites

```bash
# Install XcodeGen
brew install xcodegen

# Install required tools
brew install nmap masscan wireguard-tools
```

### Build Steps

```bash
# Generate Xcode project
xcodegen generate

# Build for Debug
xcodebuild -scheme MacHackerToolkit -configuration Debug build

# Build for Release
xcodebuild -scheme MacHackerToolkit -configuration Release build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Project Structure

```
mac-hacker-toolkit/
├── MacHackerToolkit/
│   ├── Sources/
│   │   ├── App/              # App entry point and state
│   │   ├── Models/           # Data models
│   │   ├── Services/         # Core services (ToolManager, AIOrchestrator, etc.)
│   │   ├── Views/            # SwiftUI views
│   │   ├── Protocols/        # Protocol definitions
│   │   └── Utilities/        # Helper utilities
│   ├── Resources/            # Assets, tool definitions JSON
│   └── SupportingFiles/      # Info.plist, entitlements
├── docs/                     # Documentation
├── scripts/                  # Installation scripts
├── project.yml               # XcodeGen configuration
└── Package.swift             # Swift Package Manager config
```

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the submission process.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/mac_hacker_toolkit.git

# Create a feature branch
git checkout -b feature/amazing-feature

# Make changes and commit
git commit -m 'Add amazing feature'

# Push and create PR
git push origin feature/amazing-feature
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Ethical Guidelines

**Mac Hacker Toolkit is designed exclusively for:**

- ✅ **Authorized penetration testing** with written consent
- ✅ **Security research and education**
- ✅ **Defensive security operations**
- ✅ **Compliance auditing**

**Users must:**

- 🔒 Obtain proper authorization before testing any system
- 📜 Comply with all applicable local, state, and federal laws
- 🎯 Use tools responsibly and ethically
- 📝 Report vulnerabilities through proper channels (e.g., CVE, bug bounty)

**This toolkit does NOT condone:**

- ❌ Unauthorized access to any system
- ❌ Any malicious activities
- ❌ Cybercrime of any kind

---

## 🐛 Support

- **Issues**: [GitHub Issues](https://github.com/noktirnal42/mac_hacker_toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/noktirnal42/mac_hacker_toolkit/discussions)
- **Wiki**: [GitHub Wiki](https://github.com/noktirnal42/mac_hacker_toolkit/wiki)

---

<div align="center">

**Built with ❤️ for the security community**

</div>