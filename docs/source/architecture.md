# MacOS Hacker Toolkit - System Architecture

## 1. Overview

The MacOS Hacker Toolkit is built on a modular architecture that seamlessly integrates traditional security tools with modern AI/ML capabilities. The architecture is designed to maximize performance on Apple Silicon while maintaining extensibility and ease of development.

**Architecture Layers:**
- User Interface Layer (SwiftUI)
- AI/ML Orchestration Layer (Ollama, CoreML, LangChain)
- Tool Integration Layer (Network, Wireless, Crypto, RE)
- Hardware Abstraction Layer (Wi-Fi/Bluetooth, RTL-SDR, GPU/Neural Engine)

## 2. Core Components

### 2.1. Frontend Architecture (SwiftUI)

The user interface is built using SwiftUI for native macOS integration and optimal performance on Apple Silicon.

**Key UI Components:**
- **MainDashboard**: Central hub with tool categories and AI assistant
- **ToolLauncher**: Generic wrapper for launching any tool within GUI
- **AIChatPanel**: LLM-powered assistant for tool guidance
- **ResultsAnalyzer**: AI-enhanced analysis of tool outputs
- **TimelineView**: Chronological view of security testing activities
- **ReportGenerator**: Automated report generation with AI summaries

**UI Features:**
- Drag & Drop for PCAP files, binaries, disk images
- Quick Actions: AI-suggested next steps based on current context
- Multi-Window Support: Separate windows for different tools
- Split View: Compare tool outputs side-by-side
- Dark Mode: Native macOS dark mode support
- Touch Bar: Tool shortcuts on supported MacBooks

### 2.2. AI/ML Orchestration Layer

The AI/ML layer provides intelligent capabilities across all tool categories through a unified interface.

#### Ollama Integration

Ollama serves as the primary LLM provider, running models locally on Apple Silicon. Key functions:

- **Query**: Send prompts to LLM with context
- **Vulnerability Analysis**: AI-driven interpretation of scan results
- **Exploit Generation**: Assistance in exploit development
- **Wordlist Generation**: Context-aware password lists
- **Report Generation**: Automated security report writing

**API Endpoint**: `http://localhost:11434/api/generate`

#### CoreML Integration

CoreML provides on-device machine learning for performance-sensitive tasks:

- **WiFiAnomalyDetector**: Detects rogue access points
- **MalwareClassifier**: Classifies binaries as benign/malicious
- **TrafficClassifier**: Identifies protocols from encrypted traffic
- **SignalAnalyzer**: RF signal classification for RTL-SDR

All models run on Apple Silicon's Neural Engine for maximum performance and privacy.

#### LangChain Workflows

LangChain orchestrates complex AI workflows across multiple tools:

- **Vulnerability Analysis Pipeline**: Scan → Interpret → Risk Assess → Remediate
- **Report Generation**: Multi-stage report creation with executive summaries
- **Exploit Chaining**: Automated exploit path finding
- **Forensic Analysis**: Timeline reconstruction from artifacts

#### LM Studio Wrapper

Alternative LLM interface for users who prefer LM Studio's GUI:

- **API**: Compatible with OpenAI API format
- **Models**: Supports Llama 2, Llama 3, Mistral, Phi, etc.
- **GPU Acceleration**: Optimized for Apple Silicon
- **UI**: Native macOS application interface

### 2.3. Tool Integration Layer

The tool integration layer provides abstraction between the GUI and underlying security tools.

#### Tool Manager

Central coordinator for all tool operations:

- **Tool Registration**: Load tools from configuration
- **Job Scheduling**: Manage concurrent tool execution
- **Output Processing**: Parse and structure tool outputs
- **AI Enhancement**: Optional AI post-processing
- **Sandboxing**: Isolate tool execution

**Key methods:**
- `initializeTools()`: Load all available tools
- `launchTool(tool, parameters)`: Execute a tool
- `processOutput(tool, output, job)`: Handle tool results
- `handleError(error, job)`: Error management

#### Command Builder Pattern

Generic command construction for different tools:

- **NmapCommandBuilder**: Constructs optimized Nmap commands
- **AircrackCommandBuilder**: Wi-Fi attack parameter building
- **HashcatCommandBuilder**: Password cracking optimization
- **Custom builders for each tool category**

Supports AI-driven parameter optimization based on target context.

### 2.4. Hardware Abstraction Layer

The HAL ensures consistent access to hardware peripherals across different Mac models.

#### Wireless Interface

Unified Wi-Fi/Bluetooth access:

- **Monitor Mode**: Enable via private frameworks
- **Packet Capture**: Integrated with libpcap
- **Packet Injection**: Injection framework integration
- **Firmware Management**: Driver and firmware controls

Supports both Apple Airport cards (limited) and external USB adapters (full).

#### RTL-SDR Integration

Software-defined radio support:

- **RTL-SDR Library**: Native macOS drivers
- **Multiple Devices**: RTL-SDR v3, HackRF, LimeSDR
- **Frequency Range**: 500kHz to 1.75GHz (with tuner)
- **Sample Rates**: Up to 3.2 MS/s
- **Real-time DSP**: Fourier transforms, filtering, demodulation

#### GPU/Neural Engine Acceleration

Hardware acceleration layer:

- **OpenCL**: Cross-platform compute (Hashcat, Pyrit)
- **Metal**: Apple GPU compute (Hashcat)
- **Neural Engine**: CoreML inference acceleration
- **Auto-Selection**: Automatic backend selection

## 3. Data Flow Architecture

### 3.1. Scan Data Pipeline

Raw Scan Data → Parser → Normalizer → AI Analyzer → Results Database → GUI
    ↓
Real-time Feeds (Dashboard)
    ↓
Report Generator → PDF/HTML Reports

### 3.2. AI Processing Pipeline

Tool Output → Context Builder → Prompt Generator → LLM Query → Response Parser
    ↓                                  ↓
Confidence Scorer              AI Insights
    ↓                                  ↓
Knowledge Graph Update        GUI Integration

### 3.3. Model Training Pipeline

Raw Data → Preprocessing → Feature Extraction → Model Training → Validation → CoreML Model
 ↓          ↓           ↓           ↓          ↓           ↓
Labeling → Augmentation → Feature Store → Hyperparameter → Testing → Deployment

## 4. Security & Privacy

### 4.1. Local Processing Guarantee

- **No Cloud Dependencies**: All AI/ML processing stays on device
- **Offline Operation**: Tools work without internet connectivity
- **Data Isolation**: Sandboxed tool execution environments
- **Encrypted Storage**: AES-256 encryption for sensitive data
- **Audit Logging**: Encrypted log files with tamper detection

### 4.2. Tool Isolation

Each tool runs in its own sandbox:

- **Restricted Filesystem**: Read/write only in specific directories
- **Network Isolation**: Optional blocking of network access
- **Hardware Access**: Controlled access to Wi-Fi, SDR, etc.
- **Memory Limits**: Prevents runaway processes
- **Time Limits**: Timeout enforcement

### 4.3. Audit Logging

Comprehensive activity tracking:

- **Execution Logs**: All tool launches and parameters
- **AI Usage**: When and how AI is invoked
- **Results**: Tool outputs with optional redaction
- **User Actions**: GUI interactions
- **System Events**: Hardware access, privilege elevation

**Privacy Features:**
- Automatic PII redaction
- IP address anonymization
- Credential masking
- Volume encryption support

## 5. Plugin System Architecture

### 5.1. Plugin Interface

Standardized plugin system for extending functionality:

- **ToolkitPlugin**: Main plugin interface
- **PluginCommand**: Custom commands
- **AIEnhancement**: AI-powered extensions

Plugins are sandboxed with restricted permissions and resource limits.

### 5.2. Plugin Loading

Dynamic loading at runtime:

- **Bundle Loading**: Load .bundle files from plugins directory
- **Signature Verification**: Optional code signing check
- **Dependency Resolution**: Automatic dependency installation
- **Hot Reloading**: Update plugins without restart

## 6. Performance Optimization

### 6.1. Parallel Execution

Concurrent tool execution:

- **Task Groups**: Swift async/await task groups
- **Semaphore Control**: Limit concurrent processes
- **Core Affinity**: CPU core optimization
- **Load Balancing**: Dynamic adjustment based on system load

**Default max concurrent**: Number of CPU cores

### 6.2. GPU Acceleration

Hardware acceleration for compute-intensive tasks:

- **Hashcat**: OpenCL/Metal auto-selection
- **Pyrit**: GPU-accelerated WPA cracking
- **TensorFlow**: Metal Performance Shaders for ML
- **CoreML**: Neural Engine for inference

### 6.3. Memory Management

Efficient resource usage:

- **Streaming Processing**: Large files processed in chunks
- **Memory-Mapped Files**: Efficient binary analysis
- **LRU Cache**: AI model predictions caching
- **Auto-Cleanup**: Temporary file cleanup

## 7. Extension Points

### 7.1. Custom AI Models

Train and integrate CoreML models:

- **CreateML Integration**: Train models in Xcode
- **Turicreate Support**: Python-based training
- **MLX Framework**: Apple ML research framework
- **TensorFlow Lite**: Import pre-trained models

### 7.2. Custom Tool Wrappers

Add new tools to the toolkit:

- **ToolWrapper Protocol**: Standard interface
- **Command Builder**: Parameter construction
- **Output Parser**: Structured data extraction
- **AI Enhancement**: Optional post-processing

### 7.3. Custom Reporting Templates

Generate custom reports:

- **ReportTemplate Protocol**: Template interface
- **Jinja2 Support**: Python template engine
- **Markdown/PDF**: Multiple output formats
- **AI Summarization**: Executive summary generation

## 8. Deployment Architecture

### 8.1. Build Configuration

Multiple build targets:

- **Release**: Optimized, full features, stripped
- **Debug**: No optimization, debug symbols, logging
- **Minimal**: Core tools only, no AI (for restricted environments)

### 8.2. Distribution

Multiple distribution methods:

- **DMG Package**: Standard macOS installer
- **Homebrew Tap**: Command-line installation
- **Mac App Store**: Limited version (subset of tools)
- **Enterprise PKG**: Mass deployment for organizations

### 8.3. Updates

Automatic update system:

- **Sparkle Framework**: Industry standard for macOS
- **GitHub Releases**: Hosted update files
- **Delta Updates**: Efficient binary patches
- **Plugin Updates**: Independent plugin system

## 9. Monitoring & Observability

### 9.1. Metrics Collection

Performance and usage tracking:

- **Execution Metrics**: Tool launch times, success rates
- **Resource Usage**: CPU, memory, GPU utilization
- **AI Usage**: How often AI features are invoked
- **Hardware**: Temperature, fan speeds, thermal throttling
- **Custom Metrics**: Plugin-specific metrics

**Privacy**: All metrics are local-only unless explicitly shared

### 9.2. Logging

Comprehensive logging system:

- **Console.app Integration**: Native macOS logging
- **Log Levels**: Debug, Info, Warning, Error, Fault
- **Categories**: Network, Tools, AI, Hardware, UI
- **Log Rotation**: Automatic archival
- **Privacy**: Automatic PII redaction

## 10. Future Architecture Considerations

### 10.1. Distributed Mode

Multi-device operation:

- **Multi-Mac Clustering**: Distribute workloads across multiple Macs
- **iPad Companion**: Use iPad as display/control surface
- **Apple Watch**: Notifications and simple controls

### 10.2. Cloud Integration (Optional)

Privacy-preserving cloud features:

- **Team Collaboration**: Encrypted shared workspaces
- **Model Sharing**: Exchange trained models
- **Threat Intelligence**: Federated learning (opt-in, anonymized)

### 10.3. Hardware Evolution

Future hardware support:

- **Vision Pro**: AR topology visualization
- **External GPU**: Enhanced cracking performance
- **FPGA**: Custom acceleration for security tasks

---

**Architecture Version**: 1.0  
**Last Updated**: 2024-01-15  
**Maintainers**: MacOS Hacker Toolkit Team
