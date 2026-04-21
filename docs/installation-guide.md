# MacOS Hacker Toolkit - Installation Guide

## System Requirements

### Minimum Requirements
- **macOS**: 14.0+ (Sonoma/Tahoe) or later
- **Processor**: Apple Silicon (M1/M2/M3) or Intel Core i5+
- **RAM**: 16GB (32GB+ recommended for AI/ML features)
- **Storage**: 100GB free space (tools + wordlists)
- **Network**: Internet connection for initial setup

### Recommended Requirements
- **macOS**: Latest version (15.0+)
- **Processor**: Apple Silicon M2/M3 Pro/Max
- **RAM**: 32GB (64GB+ for extensive AI/ML usage)
- **Storage**: 256GB+ SSD (NVMe)
- **External Hardware**: RTL-SDR, Ubertooth, Alfa Wi-Fi adapter

## Prerequisites

### 1. Update macOS

Ensure your system is up to date:

```bash
# Check current version
sw_vers -productVersion

# Update via command line (if needed)
sudo softwareupdate -l
sudo softwareupdate -i -a

# Or update via System Preferences
# System Settings > General > Software Update
```

### 2. Install Xcode Command Line Tools

```bash
# Install Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p

# Accept license (if prompted)
sudo xcodebuild -license accept
```

### 3. Install Homebrew

Homebrew is the primary package manager for MacOS Hacker Toolkit.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs, use:
# echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile

# Verify installation
brew --version
```

### 4. Install Python 3.11+

```bash
# Install Python via Homebrew
brew install python@3.11

# Set as default
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"

# Install pip and virtualenv
python3 -m pip install --upgrade pip virtualenv

# Verify
python3 --version
pip3 --version
```

## Installation Methods

### Method 1: DMG Installer (Recommended)

1. **Download DMG**
   - Visit: https://github.com/mac-hacker-toolkit/releases
   - Download latest `MacOSHackerToolkit-X.X.X.dmg`

2. **Install Application**
   ```bash
   # Mount DMG
   hdiutil attach MacOSHackerToolkit-X.X.X.dmg
   
   # Copy to Applications
   cp -R "/Volumes/MacOS Hacker Toolkit/MacOS Hacker Toolkit.app" /Applications/
   
   # Unmount
   hdiutil detach /Volumes/MacOS Hacker Toolkit/
   ```

3. **Run First-Time Setup**
   ```bash
   # Launch from command line first time
   open /Applications/MacOS Hacker Toolkit.app
   
   # Or launch from Applications folder
   ```

   The setup wizard will:
   - Install missing dependencies
   - Download Ollama models
   - Configure permissions
   - Run compatibility tests

### Method 2: Homebrew Tap

```bash
# Add tap
git -C /usr/local/Homebrew/Library/Taps remote add mac-hacker-toolkit https://github.com/mac-hacker-toolkit/homebrew-tap

# Alternatively, use:
brew tap mac-hacker-toolkit/toolkit

# Install brew install mac-hacker-toolkit

# Verify installation which mht
mht --version
```

### Method 3: Git Build (Development)

```bash
# Clone repository
git clone https://github.com/mac-hacker-toolkit/mac-hacker-toolkit.git
cd mac-hacker-toolkit

# Install dependencies
./scripts/install-dependencies.sh

# Build project
xcodebuild -scheme "MacOS Hacker Toolkit" -configuration Release

# Install
cp -R build/Release/"MacOS Hacker Toolkit.app" /Applications/
```

## AI/ML Components Installation

### Option A: Ollama (Recommended)

Ollama is the default LLM engine for MacOS Hacker Toolkit.

```bash
# Install Ollamacurl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Download recommended models
ollama pull mistral:7b-instruct-q4_0
ollama pull llama3:8b-instruct-q4_0
ollama pull llama2:7b-chat-q4_0

# Verifyollama list

# Test
ollama run mistral "Explain what an XSS vulnerability is"
```

**Optional Models:**
```bash
# Code generation model
ollama pull codellama:7b

# Larger models for better reasoning
ollama pull mixtral:8x7b-instruct-v0.1-q6_K

# Smaller models for faster inference
ollama pull phi:2.7b
```

### Option B: LM Studio

For users who prefer a GUI interface.

```bash
# Download LM Studio
# https://lmstudio.ai

# Install (drag to Applications)
cp -R "/Volumes/LM Studio/LM Studio.app" /Applications/

# Launch LM Studio
open /Applications/LM Studio.app

# First-time setup:
# 1. Download model from UI (e.g., "Llama 3 8B Instruct Q4")
# 2. Start server (port 8080)
# 3. Verify: curl http://localhost:8080/v1/models
```

### CoreML Models

Pre-trained CoreML models are included in the application bundle.

**Available Models:**
```swift
// Models are automatically loaded from:
// MacOS Hacker Toolkit.app/Contents/Resources/models/

// Wi-Fi Anomaly Detector
// /models/WiFiAnomalyDetector.mlmodel

// Malware Classifier
// /models/MalwareClassifier.mlmodel

// Traffic Classifier
// /models/TrafficClassifier.mlmodel

// Signal Detector
// /models/SignalClassifier.mlmodel
```

**Model Training (Optional):**
```bash
# Install CreateML
# Included with Xcode

# Train custom Wi-Fi model
python3 scripts/train_wifi_model.py --data captures/ --output models/

# Train custom malware classifier
python3 scripts/train_malware_model.py --samples samples/ --output models/
```

## Hardware Driver Installation

### RTL-SDR Dongle

```bash
# Install RTL-SDR library
brew install rtl-sdr

# Test installation
rtl_test

# Expected output:
# Found 1 device(s):
# 0: Realtek, RTL2838UHIDIR, SN: 00000001

# Troubleshooting
# If device not found:
# sudo ln -s /usr/local/lib/librtlsdr.dylib /usr/lib/librtlsdr.dylib
```

### HackRF

```bash
# Install HackRF tools
brew install hackrf

# Test
hackrf_info

# Install firmware (if needed)
brew install dfu-util
# Follow: https://github.com/mossmann/hackrf/wiki/Updating-Firmware
```

### Ubertooth

```bash
# Install Ubertooth
brew install ubertooth

# Test
ubertooth-util -s

# Update firmware (if needed)
ubertooth-dfu -r
```

### Wi-Fi Adapters

For external Wi-Fi adapters with monitor mode support:

```bash
# Alfa AWUS036ACH (RTL8812AU)
git clone https://github.com/morrownr/8812au-20210629
cd 8812au-20210629
sudo make install
sudo cp 8812au.ko /System/Library/Extensions/
sudo touch /System/Library/Extensions/
sudo kextload /System/Library/Extensions/8812au.ko

# TP-Link TL-WN722N (AR9271 chipset)
# Use: brew install --HEAD librtlsdr
```

### Bluetooth Adapters

```bash
# Test built-in Bluetooth
system_profiler SPBluetoothDataType

# For external adapters, see: docs/bluetooth-adapters.md
```

## Post-Installation Setup

### 1. Grant Permissions

The toolkit requires several macOS permissions.

```bash
# Accessibility (for GUI automation)
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
  "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.mac-hacker-toolkit.app',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,1640995200);"

# Full Disk Access (for forensics tools)
sudo tccutil reset SystemPolicyAllFiles
echo "Grant Full Disk Access in System Preferences > Security & Privacy > Privacy"
open /System/Library/PreferencePanes/Security.prefPane
```

**Manual Granting:**
1. System Settings > Privacy & Security
2. Grant permissions for:
   - Files and Folders → Full Disk Access
   - Accessibility → MacOS Hacker Toolkit
   - Bluetooth → MacOS Hacker Toolkit
   - Camera (for QR code tools)
   - Microphone (for audio analysis)

### 2. Configure Ollama

```bash
# Edit Ollama configuration
nano ~/.ollama/config.json

{
  "host": "127.0.0.1",
  "port": 11434,
  "models": {
    "mistral": "mistral:7b-instruct-q4_0",
    "llama3": "llama3:8b-instruct-q4_0",
    "custom": "custom-model:latest"
  },
  "context_size": 4096,
  "gpu_layers": -1  // Auto-detect
}
```

### 3. Configure Toolkit

```bash
# Run setup wizard
/Applications/MacOS\ Hacker\ Toolkit.app/Contents/MacOS/setup

# Or manually create config
mkdir -p ~/.mac-hacker-toolkit
nano ~/.mac-hacker-toolkit/config.toml

# Sample configuration:
[general]
install_path = "/Applications/MacOS Hacker Toolkit.app"
wordlist_path = "/Users/Shared/wordlists"
temp_dir = "/tmp/mht"

[ai]
provider = "ollama"  # ollama, lmstudio, openai
host = "localhost"
port = 11434
default_model = "mistral:7b-instruct-q4_0"
enabled = true

[hardware]
wifi_adapter = "en0"
rtl_sdr_device = 0
ubertooth_device = 0

[security]
sandbox_mode = true
audit_logging = true
auto_redact = true
```

### 4. Download Wordlists

```bash
# Download rockyou2023 (warning: ~45GB uncompressed)
cd /Users/Shared/
wget https://github.com/leylajakk/rockyou-2023/raw/main/rockyou-2023.txt.bz2

# Extract
bunzip2 rockyou-2023.txt.bz2

# Or use smaller wordlists
cd /Users/Shared/wordlists
wget https://github.com/danielmiessler/SecLists/raw/master/Passwords/Leaked-Databases/rockyou-75.txt

# Set permissions
chmod 644 *.txt
```

## Verification

### 1. Run Compatibility Test

```bash
# Built-in compatibility test
/Applications/MacOS\ Hacker\ Toolkit.app/Contents/MacOS/compatibility-test

# Expected output:
Checking system requirements... ✅
Checking Xcode tools... ✅
Checking Homebrew... ✅
Checking Python... ✅
Checking Ollama... ✅
Checking tools (50/50)... ✅
Overall: SYSTEM READY
```

### 2. Test Core Tools

```bash
# Test network tools
nmap -sV --version
masscan --version
wireshark --version  # GUI should launch

# Test AI
ollama run mistral "Say hello"

# Test hardware
rtl_test -t 2
glucose -l  # List Bluetooth devices
```

### 3. Launch GUI

```bash
# From Applications
open /Applications/MacOS\ Hacker\ Toolkit.app

# From command line
/Applications/MacOS\ Hacker\ Toolkit.app/Contents/MacOS/mac-hacker-toolkit
```

## Troubleshooting

### Ollama Not Starting

```bash
# Check if running
ps aux | grep ollama

# Check logs
journalctl -u ollama --no-pager

# Manual start
ollama serve

# Check port
lsof -i :11434

# Firewall issues
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /path/to/ollama
```

### Tools Not Found

```bash
# Check PATH
echo $PATH

# Check if tools installed
which nmap
which aircrack-ng
which hashcat

# Re-run dependency installer
/Applications/MacOS\ Hacker\ Toolkit.app/Contents/MacOS/install-dependencies
```

### Permission Denied

```bash
# Reset permissions
sudo tccutil reset All

# Reset Full Disk Access
sudo tccutil reset SystemPolicyAllFiles

# Re-grant manually
# System Settings > Privacy & Security > Full Disk Access
```

### Wi-Fi Adapter Issues

```bash
# Check adapter
system_profiler SPAirPortDataType

# Load driver manually
sudo kextload /System/Library/Extensions/AppleAirPort.kext/

# Check for errors
sudo dmesg | grep -i airport
```

### SDR Not Detected

```bash
# Check USB
system_profiler SPUSBDataType

# Check if claimed by other driver
sudo lsof | grep usb

# Force driver load
sudo killall -9 airportd
sudo launchctl load -w /System/Library/LaunchAgents/com.apple.airport.menu-extras.plist
```

## Uninstall

### Remove Application

```bash
# Remove app
sudo rm -rf /Applications/MacOS\ Hacker\ Toolkit.app

# Remove configuration
rm -rf ~/.mac-hacker-toolkit
rm -rf ~/.mac_hacker_toolkit

# Remove logs
sudo rm -rf /var/log/mac-hacker-toolkit
```

### Remove Dependencies (Optional)

```bash
# Remove Ollama (if installed via script)
sudo rm -rf /usr/local/bin/ollama
sudo rm -rf ~/.ollama

# Remove SDR tools
brew uninstall rtl-sdr hackrf ubertooth

# Remove Homebrew (if no longer needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

### Restore Permissions

```bash
# Reset all permissions
sudo tccutil reset All
```

---

## Docker Alternative

For users who prefer containerized environment:

```bash
# Build Docker image
docker build -t mac-hacker-toolkit .

# Run with device access
docker run -it --rm \
 --device /dev/ttyUSB0:/dev/ttyUSB0 \
 --device /dev/null:/dev/null \
 -p 3000:3000 \
 -v $(pwd)/data:/data \
 mac-hacker-toolkit
```

**Note**: Docker support is limited due to hardware access requirements. Native installation recommended.

---

## Support

- **Documentation**: https://docs.machacker.org
- **GitHub Issues**: https://github.com/mac-hacker-toolkit/issues
- **Discord**: https://discord.gg/macht
- **Email**: support@machacker.org

---

**Document Version**: 1.2  
**Last Updated**: 2024-01-15  
**Maintainers**: MacOS Hacker Toolkit Team
