# Installation Guide

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [First-Time Setup](#first-time-setup)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| macOS | 14.0 (Sonoma) | 14.4+ |
| RAM | 8 GB | 16 GB |
| Storage | 2 GB free | 10 GB free |
| Apple Silicon | M1 | M2/M3/M4 |

### Required Software

1. **Xcode** (15.0+)
   ```bash
   # From Mac App Store or:
   xcode-select --install
   ```

2. **Homebrew** (package manager)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **XcodeGen** (for building from source)
   ```bash
   brew install xcodegen
   ```

---

## Installation Methods

### Method 1: DMG (Recommended for Users)

1. Download the latest `.dmg` from [Releases](https://github.com/noktirnal42/mac_hacker_toolkit/releases)
2. Mount the DMG:
   ```bash
   hdiutil attach MacHackerToolkit-*.dmg
   ```
3. Drag `MacHackerToolkit.app` to your Applications folder
4. Eject the DMG:
   ```bash
   hdiutil detach /Volumes/Mac\ Hacker\ Toolkit
   ```
5. Launch from Launchpad or Spotlight

### Method 2: Build from Source (Recommended for Developers)

```bash
# Clone the repository
git clone https://github.com/noktirnal42/mac_hacker_toolkit.git
cd mac_hacker_toolkit

# Install XcodeGen if not already installed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build the application
xcodebuild -scheme MacHackerToolkit -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Find and launch the built app
open ~/Library/Developer/Xcode/DerivedData/MacHackerToolkit-*/Build/Products/Release/MacHackerToolkit.app
```

---

## First-Time Setup

### 1. Install Security Tools

Run the installation script to install all required security tools:

```bash
cd mac_hacker_toolkit
./scripts/install.sh
```

This installs:
- Network scanners (nmap, masscan, rustscan)
- Wi-Fi tools (aircrack-ng, wireguard-tools)
- Bluetooth tools (bettercap)
- Password crackers (hashcat, john)
- Reverse engineering tools (radare2, binwalk)
- And 140+ more tools

### 2. Set Up AI Features (Optional but Recommended)

Mac Hacker Toolkit uses **Ollama** for local LLM-powered analysis, ensuring your data never leaves your machine.

```bash
# Install Ollama
brew install ollama

# Start Ollama service (runs in background)
ollama serve

# Pull recommended models
ollama pull mistral      # General security analysis
ollama pull llama3       # Advanced reasoning
ollama pull codellama    # Code analysis
```

### 3. Grant Permissions

On first launch, the app will request:

| Permission | Purpose | How to Grant |
|------------|---------|--------------|
| Bluetooth | Discover nearby BLE devices | System Settings → Privacy & Security → Bluetooth |
| Local Network | Network scanning | Allow when prompted |
| Full Disk Access | Forensics tools | System Settings → Privacy & Security → Full Disk Access |

---

## Tool Categories

### Network Security Tools

| Tool | Installed | Description |
|------|-----------|-------------|
| nmap | ✓ | Network discovery and security auditing |
| masscan | ✓ | Fast TCP port scanner |
| rustscan | ✓ | Modern port scanner (10x faster than nmap) |
| wireshark | ✓ | Packet analyzer |
| netcat | ✓ | Network Swiss Army knife |
| tcpdump | ✓ | Command-line packet analyzer |

### Wi-Fi Tools

| Tool | Installed | Description |
|------|-----------|-------------|
| aircrack-ng | ✓ | Wi-Fi security testing suite |
| airodump-ng | Via aircrack-ng | Capture WPA handshakes |
| aireplay-ng | Via aircrack-ng | Inject/deauth packets |
| cowpatty | ✓ | WPA/WPA2 passphrase cracker |
| pyrit | ✓ | WPA/WPA2 password cracker |
| wifite2 | ✓ | Automated Wi-Fi attacks |

### Bluetooth Tools

| Tool | Installed | Description |
|------|-----------|-------------|
| bettercap | ✓ | BLE and Classic Bluetooth testing |
| btlejuice | ✓ | BLE MITM proxy |
| ubertooth-tools | Via homebrew | Ubertooth One utilities |

### Password Tools

| Tool | Installed | Description |
|------|-----------|-------------|
| hashcat | ✓ | Fast GPU-accelerated password cracker |
| john | ✓ | John the Ripper |
| hydra | ✓ | Network login cracker |
| medusa | ✓ | Parallel network login cracker |

### Reverse Engineering

| Tool | Installed | Description |
|------|-----------|-------------|
| radare2 | ✓ | Command-line hex editor |
| binwalk | ✓ | Firmware analysis |
| strings | ✓ | Extract strings from binaries |
| objdump | ✓ | Object file disassembler |
| xxd | ✓ | Hex dump tool |

### Forensics

| Tool | Installed | Description |
|------|-----------|-------------|
| sleuthkit | ✓ | Digital forensics tools |
| autopsy | ✓ | Forensic UI (requires Java) |
| volatility3 | ✓ | Memory forensics |
| testdisk | ✓ | Photo/recovery |
| foremost | ✓ | File carver |

---

## Configuration

### Tool Paths

Tools are automatically detected from your PATH. To specify custom locations:

```bash
# Create config directory
mkdir -p ~/.config/machackertoolkit

# Copy default config
cp /Applications/MacHackerToolkit.app/Contents/Resources/config.toml \
   ~/.config/machackertoolkit/config.toml
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MHT_TOOL_PATH` | `/usr/local/bin` | Custom tool directory |
| `MHT_OLLAMA_URL` | `http://localhost:11434` | Ollama API URL |
| `MHT_LOG_LEVEL` | `info` | Log verbosity |

---

## Troubleshooting

### "App is damaged and can't be opened"

**Cause:** Code signing issue with DMG

**Fix:**
```bash
xattr -cr /Applications/MacHackerToolkit.app
```

### "Operation not permitted" errors

**Cause:** Missing System Preferences permissions

**Fix:**
1. Go to System Settings → Privacy & Security → Security & Privacy
2. Grant Full Disk Access to Terminal
3. Grant Bluetooth access to MacHackerToolkit

### Tools not found

**Cause:** PATH not configured

**Fix:**
```bash
# Add to your ~/.zshrc or ~/.bashrc
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
source ~/.zshrc
```

### AI features not working

**Cause:** Ollama not running

**Fix:**
```bash
# Check if Ollama is running
pgrep -f ollama

# Start Ollama
ollama serve

# Verify models installed
ollama list
```

---

## Uninstallation

### Via DMG Installation

```bash
rm -rf /Applications/MacHackerToolkit.app
rm -rf ~/Library/Application\ Support/MacHackerToolkit
rm -rf ~/Library/Preferences/com.worldhackerlabs.machackertoolkit.plist
```

### Via Homebrew (if installed that way)

```bash
brew uninstall --cask mac-hacker-toolkit
```

---

## Updating

### DMG Installation

Download and install the latest version from [Releases](https://github.com/noktirnal42/mac_hacker_toolkit/releases).

### Build from Source

```bash
cd mac-hacker-toolkit
git pull origin main
xcodegen generate
xcodebuild -scheme MacHackerToolkit -configuration Release build \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```