# MacOS "Hacker" Toolkit - Tool Catalog

## AI/ML Tools
| Tool            | Purpose                                                                 | macOS Compatibility | GUI       | AI/ML Backend         | License    | Dependencies               |
|-----------------|-------------------------------------------------------------------------|---------------------|-----------|-----------------------|------------|-----------------------------|
| LM Studio      | Run local LLMs for analysis, automation, and chatbot functionality.   | Native              | Native    | Local LLM             | Freeware   | None                        |
| Ollama         | Simplified local LLM deployment and management.                        | Native              | Native    | Local LLM             | MIT        | None                        |
| LangChain      | Integrate LLMs into workflows (e.g., log analysis, report generation). | Cross-platform      | Web UI    | Local/Cloud LLM       | MIT        | Python                     |
| Llama.cpp      | Run quantized LLMs efficiently on macOS.                               | Native              | CLI       | Local LLM             | MIT        | None                        |
| CreateML       | Train custom ML models for security tasks (e.g., Wi-Fi anomaly detection). | Native       | Native    | CoreML                | Proprietary | Xcode                      |
| Turicreate     | Simplify model training for security tasks.                             | Cross-platform      | Jupyter/CLI | CoreML               | BSD        | Python                     |
| TensorFlow Lite| Run pre-trained models for tasks like malware detection.                | Native              | CLI       | TensorFlow Lite       | Apache 2.0 | Python                     |

## Updated Tool Categories with AI/ML Enhancements

### Network Scanning
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Nmap            | Network discovery and vulnerability scanning. | Native              | CLI/GUI   | AI-driven vulnerability analysis.           |
| Nessus          | Vulnerability scanning.                      | Cross-platform      | Web UI    | AI-generated remediation recommendations.   |
| Masscan         | High-speed network scanning.                 | Cross-platform      | CLI       | Anomaly detection in scan results.          |

### Wi-Fi Security
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Wireshark       | Packet analysis.                             | Native              | Native    | ML-based rogue AP detection.                |
| Aircrack-ng     | Wi-Fi security assessment.                   | Cross-platform      | CLI       | AI-driven WPA3 cracking strategies.         |
| Bettercap       | MITM attacks and Wi-Fi reconnaissance.       | Cross-platform      | CLI       | AI-driven session hijacking detection.      |

### Password Cracking
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Hashcat         | Password cracking.                           | Cross-platform      | CLI       | AI-generated wordlists.                     |
| John the Ripper | Password cracking.                           | Cross-platform      | CLI       | Smart brute-force strategies.               |
| Hydra           | Brute-force attacks.                         | Cross-platform      | CLI       | Context-aware brute-forcing.                |

### Exploitation
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Metasploit      | Exploit development and execution.           | Cross-platform      | CLI/GUI   | AI-assisted exploit development.            |
| Frida           | Dynamic instrumentation.                     | Cross-platform      | CLI       | AI-driven payload obfuscation.              |
| Evilginx        | Phishing simulation.                         | Cross-platform      | CLI       | AI-generated phishing payloads.             |

### Reverse Engineering
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Ghidra          | Software reverse engineering.                | Cross-platform      | Native    | AI-assisted decompilation.                  |
| Hopper          | Reverse engineering.                        | Native              | Native    | Vulnerability detection in binaries.        |
| Radare2         | Binary analysis.                             | Cross-platform      | CLI       | AI-driven binary analysis.                  |

### Forensics
| Tool            | Purpose                                      | macOS Compatibility | GUI       | AI/ML Enhancements                          |
|-----------------|----------------------------------------------|---------------------|-----------|---------------------------------------------|
| Autopsy         | Digital forensics.                           | Cross-platform      | Web UI    | ML-based file carving.                      |
| Volatility      | Memory forensics.                           | Cross-platform      | CLI       | Anomaly detection in memory dumps.         |
| Binwalk         | Firmware analysis.                           | Cross-platform      | CLI       | AI-driven steganography detection.          |