# Usage Guide

## Table of Contents

- [Getting Started](#getting-started)
- [Dashboard](#dashboard)
- [Network Scanner](#network-scanner)
- [Wi-Fi Scanner](#wi-fi-scanner)
- [Bluetooth Scanner](#bluetooth-scanner)
- [Password Tools](#password-tools)
- [Forensics](#forensics)
- [Reverse Engineering](#reverse-engineering)
- [AI Features](#ai-features)

---

## Getting Started

### Launching the App

1. Open **MacHackerToolkit** from Applications or Launchpad
2. The main dashboard will appear showing system status
3. Use the sidebar to navigate to different tools

### Navigation

The app uses a **NavigationSplitView** with:
- **Sidebar**: Tool categories
- **Content**: Main tool interface
- **Detail**: Tool-specific details

---

## Dashboard

The dashboard provides a real-time overview of:

### System Status Panel
- CPU usage with historical graph
- Memory usage
- Network activity
- GPU/Neural Engine utilization

### Quick Actions
| Action | Description |
|--------|-------------|
| Quick Scan | Run a fast network discovery |
| AI Assistant | Open AI chat panel |
| System Info | View detailed system information |

### AI Insights Panel
Displays AI-generated insights about your system's security posture.

---

## Network Scanner

### Basic Scan

1. Select **Network Scanner** from the sidebar
2. Choose scan type:
   - **Quick Scan**: Fast discovery of live hosts
   - **Full Scan**: Comprehensive port scan
   - **Custom**: Specify ports and options

3. Enter target:
   - IP address (e.g., `192.168.1.1`)
   - CIDR range (e.g., `192.168.1.0/24`)
   - Hostname (e.g., `example.com`)

4. Click **Start Scan**

### Advanced Options

| Option | Description |
|--------|-------------|
| Port Range | Default: 1-1000, Custom: 1-65535 |
| Scan Type | TCP/SYN/UDP |
| Timing | T1-T5 (slowest to fastest) |
| OS Detection | Enable with `-O` flag |

### Results

After scanning, you'll see:
- **Host List**: Discovered devices with IP, MAC, hostname
- **Port List**: Open ports with service names
- **OS Detection**: Guessed operating system
- **Service Versions**: Banner grabbing results

### Export Results

Click **Export** to save results in:
- JSON (machine-readable)
- XML (for Metasploit integration)
- HTML (visual report)
- CSV (spreadsheet compatible)

---

## Wi-Fi Scanner

### Scanning Access Points

1. Select **Wi-Fi Scanner** from the sidebar
2. Click **Scan** to discover nearby networks
3. View results in the Networks tab

### Network Details

| Column | Description |
|--------|-------------|
| SSID | Network name |
| BSSID | Access point MAC address |
| Signal | Signal strength (dBm) |
| Channel | Wi-Fi channel |
| Security | Encryption type (WPA3/WPA2/WPA/WEP/Open) |

### Handshake Capture

1. Select a target network
2. Go to **Handshakes** tab
3. Click **Start Capture**
4. Wait for client connection (or force deauth)
5. Handshake will be saved to `/tmp/`

### Aircrack-ng Integration

The app integrates with aircrack-ng suite:

```bash
# Monitor mode
sudo airmon-ng start en0

# Capture handshakes
sudo airodump-ng -c [channel] --bssid [mac] -w capture wlan0mon

# Crack (after capturing)
aircrack-ng -w wordlist.txt -b [bssid] capture.cap
```

---

## Bluetooth Scanner

### Discovering Devices

1. Select **Bluetooth Scanner** from the sidebar
2. Click **Scan** to discover nearby devices
3. View paired and discovered devices

### Device Information

| Field | Description |
|-------|-------------|
| Name | Device name |
| Address | Bluetooth MAC address |
| RSSI | Signal strength |
| Type | Classic/BLE/Dual-mode |
| Class | Device category (Phone/Computer/Audio/etc.) |

### GATT Browser (BLE)

For BLE devices:
1. Select a device
2. Go to **GATT Browser** tab
3. Browse services and characteristics
4. Read/Write values

### Bettercap Integration

```bash
# Start BLE enumeration
sudo bettercap -eval "ble.recon on"

# Target specific device
ble.enum [device_address]
```

---

## Password Tools

### Hashcat

1. Select **Password Tools** → **Hashcat**
2. Choose attack mode:
   - **Dictionary**: Wordlist-based
   - **Brute Force**: All combinations
   - **Hybrid**: Dictionary + rules
   - **Association**: Hash comparison

3. Select hash type (auto-detected if possible)
4. Load hash file or paste hash
5. Select wordlist and rules
6. Click **Start**

### Wordlist Generator

Generate custom wordlists:

```bash
# Crunch (pre-installed)
crunch 8 12 abcdefghijklmnopqrstuvwxyz -o wordlist.txt

# CUPP (password profiling)
cupp -i  # Interactive mode
```

---

## Forensics

### Disk Imaging

1. Select **Forensics** → **Disk Imaging**
2. Choose source device
3. Select output format:
   - RAW (.img)
   - E01 (EnCase)
   - AFF (Advanced Forensic Format)
4. Click **Create Image**

### Memory Forensics

1. Select **Forensics** → **Memory**
2. Choose memory source
3. Select profile (OS version)
4. Run volatility plugins:
   - `pslist` - Process list
   - `netscan` - Network connections
   - `malfind` - Malicious processes
   - `hashdump` - Password hashes

### File Recovery

```bash
# PhotoRec (installed)
photorec

# TestDisk
testdisk
```

---

## Reverse Engineering

### Binary Analysis

1. Select **Reverse Engineering** → **Binary Analysis**
2. Load binary file
3. View:
   - File information
   - Strings (extract readable strings)
   - Disassembly (if available)
   - Entropy graph (detect packed/encrypted sections)

### Frida Integration

Dynamic instrumentation:

```bash
# Attach to process
frida -f com.example.app

# List loaded modules
[Local::废话]> modules

# Find function
[Local::废话]> enumerateSymbols "{{module}}" "*crypto*"
```

### Ghidra Integration

1. Export binary from the app
2. Open in Ghidra manually
3. Analyze for vulnerabilities

---

## AI Features

### AI Assistant

Chat with a local LLM for security guidance:

1. Click **AI Assistant** in sidebar or press `⌘⇧K`
2. Ask security-related questions
3. Get context-aware answers

**Example prompts:**
- "How do I analyze this pcap file?"
- "What are the steps for a penetration test?"
- "Explain this malware behavior"

### AI-Powered Analysis

The app uses AI to analyze:
- Network traffic patterns
- Binary files for malicious behavior
- Password strength
- Vulnerability reports

### Ollama Configuration

```bash
# Check Ollama status
ollama list

# Add custom models
ollama pull phi3
ollama pull neural-chat

# Custom model path
export OLLAMA_MODELS=/path/to/models
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧K` | AI Assistant |
| `⌘R` | Quick Scan |
| `⌘,` | Settings |
| `⌘N` | New Project |
| `⌘O` | Open Project |
| `⌘E` | Export Results |
| `⌘F` | Search |
| `⌘W` | Close Window |
| `⌘Q` | Quit |

---

## Exporting Data

All views support exporting:

| Format | Use Case |
|--------|----------|
| JSON | API integration, scripting |
| CSV | Spreadsheet analysis |
| HTML | Visual reports |
| PDF | Documentation |

---

## Logging

Logs are stored at:
```
~/Library/Application Support/MacHackerToolkit/logs/
```

Log levels:
- `debug` - Verbose debugging
- `info` - Informational (default)
- `warning` - Warnings only
- `error` - Errors only

---

## Getting Help

- Press `⌘?` for keyboard shortcuts
- Use the AI Assistant for feature questions
- Check [GitHub Issues](https://github.com/noktirnal42/mac_hacker_toolkit/issues) for bugs