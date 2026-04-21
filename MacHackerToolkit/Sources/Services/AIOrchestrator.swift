import Foundation
import Combine
import CoreML

// MARK: - Enums

enum AIState: String, Codable {
    case idle
    case generating
    case error
}

enum AIInsightSeverity: String, Codable, CaseIterable {
    case critical
    case high
    case medium
    case low
    case informational
}

enum ChatRole: String, Codable {
    case system
    case user
    case assistant
}

enum WorkflowStepType: String, Codable {
    case promptBuilder
    case llmQuery
    case responseParser
    case confidenceScorer
    case knowledgeGraphUpdate
}

// MARK: - Models

struct OllamaModel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let model: String
    let modifiedAt: String
    let size: Int
    let digest: String

    private enum CodingKeys: String, CodingKey {
        case name, model, modifiedAt = "modified_at", size, digest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        model = try container.decode(String.self, forKey: .model)
        modifiedAt = try container.decode(String.self, forKey: .modifiedAt)
        size = try container.decode(Int.self, forKey: .size)
        digest = try container.decode(String.self, forKey: .digest)
        id = UUID()
    }

    init(name: String, model: String, modifiedAt: String, size: Int, digest: String) {
        self.id = UUID()
        self.name = name
        self.model = model
        self.modifiedAt = modifiedAt
        self.size = size
        self.digest = digest
    }

    var displayName: String {
        name.replacingOccurrences(of: ":latest", with: "")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: ChatRole
    var content: String
    let timestamp: Date

    init(role: ChatRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }

    var ollamaDict: [String: String] {
        ["role": role.rawValue, "content": content]
    }
}

struct AIConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let model: String
    let createdAt: Date
    var updatedAt: Date
    var toolContext: String?
    var projectContext: String?
    var scanResultContext: [String]?

    init(title: String, model: String, toolContext: String? = nil, projectContext: String? = nil) {
        self.id = UUID()
        self.title = title
        self.messages = []
        self.model = model
        self.createdAt = Date()
        self.updatedAt = Date()
        self.toolContext = toolContext
        self.projectContext = projectContext
    }

    var lastMessage: ChatMessage? {
        messages.last
    }

    var messageCount: Int {
        messages.count
    }

    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
    }
}

struct AIInsight: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let title: String
    let description: String
    let severity: AIInsightSeverity
    let confidence: Double
    let source: String
    let model: String
    let toolContext: String?
    let recommendations: [String]

    init(title: String, description: String, severity: AIInsightSeverity, confidence: Double, source: String, model: String, toolContext: String? = nil, recommendations: [String] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.title = title
        self.description = description
        self.severity = severity
        self.confidence = confidence
        self.source = source
        self.model = model
        self.toolContext = toolContext
        self.recommendations = recommendations
    }
}

struct OllamaGenerateResponse: Codable {
    let model: String
    let createdAt: String
    let response: String
    let done: Bool
    let context: [Int]?
    let totalDuration: Int?
    let evalCount: Int?

    private enum CodingKeys: String, CodingKey {
        case model, response, done, context
        case createdAt = "created_at"
        case totalDuration = "total_duration"
        case evalCount = "eval_count"
    }
}

struct OllamaChatResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaChatMessage
    let done: Bool
    let totalDuration: Int?
    let evalCount: Int?

    private enum CodingKeys: String, CodingKey {
        case model, message, done
        case createdAt = "created_at"
        case totalDuration = "total_duration"
        case evalCount = "eval_count"
    }
}

struct OllamaChatMessage: Codable {
    let role: String
    let content: String
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]

    private enum CodingKeys: String, CodingKey {
        case models = "models" // API returns array under "models" key, but also sometimes top-level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        models = try container.decodeIfPresent([OllamaModel].self, forKey: .models) ?? []
    }
}

struct OllamaPullRequest: Codable {
    let name: String
    let stream: Bool
}

struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let system: String?
    let context: [Int]?
    let stream: Bool
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [[String: String]]
    let stream: Bool
}

// MARK: - CoreML Models

struct CoreMLModel: Identifiable {
    let id: UUID
    let name: String
    let displayName: String
    let typeName: String
    let inputDescriptions: [String: String]
    let outputDescriptions: [String: String]
    var isLoaded: Bool

    init(name: String, displayName: String, typeName: String, inputDescriptions: [String: String] = [:], outputDescriptions: [String: String] = [:], isLoaded: Bool = false) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.typeName = typeName
        self.inputDescriptions = inputDescriptions
        self.outputDescriptions = outputDescriptions
        self.isLoaded = isLoaded
    }
}

enum MLInput {
    case dictionary([String: Any])
    case multiArray([String: Any])
    case single(String, Any)

    var asDictionary: [String: Any] {
        switch self {
        case .dictionary(let dict): return dict
        case .multiArray(let dict): return dict
        case .single(let key, let value): return [key: value]
        }
    }
}

enum MLOutput {
    case dictionary([String: Any])
    case multiArray([String: Any])
    case single(String, Any)
    case prediction(label: String, confidence: Double)

    var asDictionary: [String: Any] {
        switch self {
        case .dictionary(let dict): return dict
        case .multiArray(let dict): return dict
        case .single(let key, let value): return [key: value]
        case .prediction(let label, let confidence): return ["label": label, "confidence": confidence]
        }
    }
}

// MARK: - Workflow Models

struct WorkflowStep: Identifiable, Codable {
    let id: UUID
    let type: WorkflowStepType
    let name: String
    let description: String
    var configuration: [String: String]

    init(type: WorkflowStepType, name: String, description: String, configuration: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.description = description
        self.configuration = configuration
    }
}

struct AIWorkflow: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let steps: [WorkflowStep]
    let requiredModel: String?
    let category: WorkflowCategory

    init(name: String, description: String, steps: [WorkflowStep], requiredModel: String? = nil, category: WorkflowCategory = .analysis) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.steps = steps
        self.requiredModel = requiredModel
        self.category = category
    }
}

enum WorkflowCategory: String, Codable, CaseIterable {
    case analysis
    case exploitation
    case reporting
    case generation
    case forensics
}

struct WorkflowInput {
    let rawData: String
    let metadata: [String: String]
    let toolContext: String?
    let projectContext: String?

    init(rawData: String, metadata: [String: String] = [:], toolContext: String? = nil, projectContext: String? = nil) {
        self.rawData = rawData
        self.metadata = metadata
        self.toolContext = toolContext
        self.projectContext = projectContext
    }
}

struct WorkflowOutput {
    let result: String
    let confidence: Double
    let insights: [AIInsight]
    let intermediateResults: [String: String]
    let duration: TimeInterval

    init(result: String, confidence: Double = 0.0, insights: [AIInsight] = [], intermediateResults: [String: String] = [:], duration: TimeInterval = 0) {
        self.result = result
        self.confidence = confidence
        self.insights = insights
        self.intermediateResults = intermediateResults
        self.duration = duration
    }
}

// MARK: - Audit Log

struct AIAuditEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let action: String
    let model: String
    let input: String
    let output: String?
    let duration: TimeInterval
    let metadata: [String: String]

    init(action: String, model: String, input: String, output: String? = nil, duration: TimeInterval = 0, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.model = model
        self.input = input
        self.output = output
        self.duration = duration
        self.metadata = metadata
    }
}

// MARK: - Errors

enum AIOrchestratorError: LocalizedError {
    case ollamaServerUnavailable
    case modelNotFound(String)
    case generationFailed(String)
    case chatFailed(String)
    case streamingFailed(String)
    case pullFailed(String)
    case coreMLModelNotFound(String)
    case coreMLPredictionFailed(String)
    case workflowStepFailed(String)
    case invalidInput(String)
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .ollamaServerUnavailable: return "Ollama server is not running. Start it with: ollama serve"
        case .modelNotFound(let name): return "Model not found: \(name)"
        case .generationFailed(let reason): return "Generation failed: \(reason)"
        case .chatFailed(let reason): return "Chat failed: \(reason)"
        case .streamingFailed(let reason): return "Streaming failed: \(reason)"
        case .pullFailed(let reason): return "Model pull failed: \(reason)"
        case .coreMLModelNotFound(let name): return "CoreML model not found: \(name)"
        case .coreMLPredictionFailed(let reason): return "CoreML prediction failed: \(reason)"
        case .workflowStepFailed(let step): return "Workflow step failed: \(step)"
        case .invalidInput(let detail): return "Invalid input: \(detail)"
        case .timeout: return "Operation timed out"
        case .cancelled: return "Operation was cancelled"
        }
    }
}

// MARK: - OllamaService

final class OllamaService {
    static let shared = OllamaService()

    private let baseURL: URL
    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    init(baseURL: URL = URL(string: "http://localhost:11434")!) {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)

        self.jsonDecoder = JSONDecoder()
    }

    func isServerRunning() async -> Bool {
        guard let url = URL(string: "/", relativeTo: baseURL) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func listModels() async throws -> [OllamaModel] {
        guard let url = URL(string: "/api/tags", relativeTo: baseURL) else {
            throw AIOrchestratorError.invalidInput("Invalid URL for /api/tags")
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIOrchestratorError.ollamaServerUnavailable
        }

        guard httpResponse.statusCode == 200 else {
            throw AIOrchestratorError.generationFailed("HTTP \(httpResponse.statusCode)")
        }

        let tagsResponse = try jsonDecoder.decode(OllamaTagsResponse.self, from: data)
        return tagsResponse.models
    }

    func generate(model: String, prompt: String, system: String? = nil, context: [Int]? = nil) async throws -> OllamaGenerateResponse {
        guard let url = URL(string: "/api/generate", relativeTo: baseURL) else {
            throw AIOrchestratorError.invalidInput("Invalid URL for /api/generate")
        }

        let requestBody = OllamaGenerateRequest(model: model, prompt: prompt, system: system, context: context, stream: false)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIOrchestratorError.ollamaServerUnavailable
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIOrchestratorError.generationFailed("HTTP \(httpResponse.statusCode): \(body)")
        }

        return try jsonDecoder.decode(OllamaGenerateResponse.self, from: data)
    }

    func chat(model: String, messages: [ChatMessage]) async throws -> OllamaChatResponse {
        guard let url = URL(string: "/api/chat", relativeTo: baseURL) else {
            throw AIOrchestratorError.invalidInput("Invalid URL for /api/chat")
        }

        let messagesDict = messages.map { $0.ollamaDict }
        let requestBody = OllamaChatRequest(model: model, messages: messagesDict, stream: false)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIOrchestratorError.ollamaServerUnavailable
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIOrchestratorError.chatFailed("HTTP \(httpResponse.statusCode): \(body)")
        }

        return try jsonDecoder.decode(OllamaChatResponse.self, from: data)
    }

    func streamingChat(model: String, messages: [ChatMessage]) -> AsyncStream<String> {
        AsyncStream<String> { continuation in
            Task {
                guard let url = URL(string: "/api/chat", relativeTo: baseURL) else {
                    continuation.finish()
                    return
                }

                let messagesDict = messages.map { $0.ollamaDict }
                let requestBody = OllamaChatRequest(model: model, messages: messagesDict, stream: true)

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONEncoder().encode(requestBody)

                let (bytes, response) = try await session.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continuation.finish()
                    return
                }

                for try await line in bytes.lines {
                    guard let lineData = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                          let message = json["message"] as? [String: String],
                          let content = message["content"] else {
                        continue
                    }

                    continuation.yield(content)

                    if let done = json["done"] as? Bool, done {
                        break
                    }
                }

                continuation.finish()
            }
        }
    }

    func pullModel(name: String) async throws {
        guard let url = URL(string: "/api/pull", relativeTo: baseURL) else {
            throw AIOrchestratorError.invalidInput("Invalid URL for /api/pull")
        }

        let requestBody = OllamaPullRequest(name: name, stream: false)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = 600

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIOrchestratorError.ollamaServerUnavailable
        }

        guard httpResponse.statusCode == 200 else {
            throw AIOrchestratorError.pullFailed("HTTP \(httpResponse.statusCode)")
        }
    }
}

// MARK: - CoreMLModelManager

final class CoreMLModelManager {
    static let shared = CoreMLModelManager()

    private var loadedModels: [String: MLModel] = [:]
    private(set) var availableModels: [CoreMLModel] = []

    private let bundledModelNames: [String: String] = [
        "WiFiAnomalyDetector": "WiFiAnomalyDetector",
        "MalwareClassifier": "MalwareClassifier",
        "TrafficClassifier": "TrafficClassifier",
        "SignalAnalyzer": "SignalAnalyzer"
    ]

    private init() {}

    func loadAvailableModels() -> [CoreMLModel] {
        var models: [CoreMLModel] = []

        for (key, fileName) in bundledModelNames {
            let compiledURL = Bundle.main.url(forResource: fileName, withExtension: "mlmodelc")
            let isLoaded = compiledURL != nil && loadModel(name: key, url: compiledURL!)

            let coreMLModel = CoreMLModel(
                name: key,
                displayName: fileName,
                typeName: key,
                inputDescriptions: compiledURL != nil ? describeInputs(for: key) : [:],
                outputDescriptions: compiledURL != nil ? describeOutputs(for: key) : [:],
                isLoaded: isLoaded
            )
            models.append(coreMLModel)
        }

        availableModels = models
        return models
    }

    func predict(model name: String, input: MLInput) async throws -> MLOutput {
        guard let mlModel = loadedModels[name] else {
            throw AIOrchestratorError.coreMLModelNotFound(name)
        }

        let inputDict = input.asDictionary

        let featureProvider: MLFeatureProvider
        do {
            featureProvider = try MLDictionaryFeatureProvider(dictionary: inputDict)
        } catch {
            throw AIOrchestratorError.coreMLPredictionFailed("Failed to create feature provider: \(error.localizedDescription)")
        }

        let prediction: MLFeatureProvider
        do {
            prediction = try await mlModel.prediction(from: featureProvider)
        } catch {
            throw AIOrchestratorError.coreMLPredictionFailed("Prediction failed: \(error.localizedDescription)")
        }

        var outputDict: [String: Any] = [:]
        for featureName in prediction.featureNames {
            let value = prediction.featureValue(for: featureName)
            if let value = value {
                switch value.type {
                case .double:
                    outputDict[featureName] = value.doubleValue
                case .int64:
                    outputDict[featureName] = value.int64Value
                case .string:
                    outputDict[featureName] = value.stringValue
                case .multiArray:
                    if let multiArray = value.multiArrayValue {
                        outputDict[featureName] = multiArray
                    }
                case .dictionary:
                    outputDict[featureName] = value.dictionaryValue
                default:
                    outputDict[featureName] = String(describing: value)
                }
            }
        }

        if let label = outputDict["label"] as? String, let confidence = outputDict["confidence"] as? Double {
            return .prediction(label: label, confidence: confidence)
        }

        return .dictionary(outputDict)
    }

    @discardableResult
    private func loadModel(name: String, url: URL) -> Bool {
        guard loadedModels[name] == nil else { return true }

        do {
            let model = try MLModel(contentsOf: url)
            loadedModels[name] = model
            return true
        } catch {
            return false
        }
    }

    func unloadModel(name: String) {
        loadedModels.removeValue(forKey: name)
        if let index = availableModels.firstIndex(where: { $0.name == name }) {
            availableModels[index].isLoaded = false
        }
    }

    private func describeInputs(for name: String) -> [String: String] {
        guard let model = loadedModels[name] else { return [:] }
        return model.modelDescription.inputDescriptionsByName.reduce(into: [:]) { result, entry in
            result[entry.key] = String(describing: entry.value.type)
        }
    }

    private func describeOutputs(for name: String) -> [String: String] {
        guard let model = loadedModels[name] else { return [:] }
        return model.modelDescription.outputDescriptionsByName.reduce(into: [:]) { result, entry in
            result[entry.key] = String(describing: entry.value.type)
        }
    }
}

// MARK: - AIWorkflowEngine

final class AIWorkflowEngine {
    static let shared = AIWorkflowEngine()

    private let ollamaService = OllamaService.shared
    private(set) var workflows: [AIWorkflow] = []

    private init() {
        workflows = buildBuiltinWorkflows()
    }

    func execute(workflow: AIWorkflow, input: WorkflowInput) async throws -> WorkflowOutput {
        let startTime = Date()
        var intermediateResults: [String: String] = [:]
        var currentData = input.rawData
        var accumulatedInsights: [AIInsight] = []
        var finalConfidence = 0.0

        for step in workflow.steps {
            switch step.type {
            case .promptBuilder:
                let built = buildPrompt(from: input, configuration: step.configuration)
                currentData = built
                intermediateResults["promptBuilder"] = String(built.prefix(500))

            case .llmQuery:
                let modelName = step.configuration["model"] ?? workflow.requiredModel ?? "mistral"
                let systemPrompt = step.configuration["systemPrompt"] ?? systemPromptForCategory(workflow.category)

                let response = try await ollamaService.generate(
                    model: modelName,
                    prompt: currentData,
                    system: systemPrompt
                )
                currentData = response.response
                intermediateResults["llmQuery"] = String(response.response.prefix(500))

            case .responseParser:
                let parsed = parseResponse(currentData, configuration: step.configuration)
                currentData = parsed
                intermediateResults["responseParser"] = String(parsed.prefix(500))

            case .confidenceScorer:
                let (scored, confidence) = scoreConfidence(currentData, configuration: step.configuration)
                currentData = scored
                finalConfidence = confidence
                intermediateResults["confidenceScorer"] = "Confidence: \(confidence)"

            case .knowledgeGraphUpdate:
                let updated = extractKnowledgeGraphEntries(currentData, configuration: step.configuration)
                currentData = updated
                intermediateResults["knowledgeGraphUpdate"] = String(updated.prefix(500))

                let insight = AIInsight(
                    title: "Workflow Insight: \(workflow.name)",
                    description: String(updated.prefix(200)),
                    severity: .informational,
                    confidence: finalConfidence,
                    source: "AIWorkflow",
                    model: workflow.requiredModel ?? "unknown",
                    toolContext: input.toolContext,
                    recommendations: extractRecommendations(from: updated)
                )
                accumulatedInsights.append(insight)
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return WorkflowOutput(
            result: currentData,
            confidence: finalConfidence,
            insights: accumulatedInsights,
            intermediateResults: intermediateResults,
            duration: duration
        )
    }

    func workflow(for category: WorkflowCategory) -> AIWorkflow? {
        workflows.first { $0.category == category }
    }

    // MARK: - Built-in Workflows

    private func buildBuiltinWorkflows() -> [AIWorkflow] {
        [
            vulnerabilityAnalysis,
            exploitSuggestion,
            reportGeneration,
            wordlistGeneration,
            forensicTimeline
        ]
    }

    private var vulnerabilityAnalysis: AIWorkflow {
        AIWorkflow(
            name: "Vulnerability Analysis",
            description: "Analyzes scan results and tool outputs to identify vulnerabilities with confidence scoring",
            steps: [
                WorkflowStep(type: .promptBuilder, name: "Build Analysis Prompt", description: "Constructs a structured vulnerability analysis prompt", configuration: [
                    "template": "vulnerability_analysis",
                    "includeContext": "true"
                ]),
                WorkflowStep(type: .llmQuery, name: "LLM Vulnerability Assessment", description: "Queries the LLM for vulnerability assessment", configuration: [
                    "systemPrompt": "You are a cybersecurity expert performing vulnerability analysis. Identify all vulnerabilities, categorize by severity (Critical/High/Medium/Low), provide CVSS-style scoring rationale, and recommend remediations. Format findings as structured markdown."
                ]),
                WorkflowStep(type: .responseParser, name: "Parse Findings", description: "Parses the LLM response into structured vulnerability findings", configuration: [
                    "format": "markdown",
                    "extractSections": "true"
                ]),
                WorkflowStep(type: .confidenceScorer, name: "Score Confidence", description: "Scores confidence of each finding based on evidence and LLM certainty", configuration: [
                    "method": "evidence_based"
                ]),
                WorkflowStep(type: .knowledgeGraphUpdate, name: "Update Knowledge Graph", description: "Updates the knowledge graph with discovered vulnerabilities and relationships", configuration: [
                    "entityTypes": "vulnerability,asset,attack_vector,remediation"
                ])
            ],
            requiredModel: "mistral",
            category: .analysis
        )
    }

    private var exploitSuggestion: AIWorkflow {
        AIWorkflow(
            name: "Exploit Suggestion",
            description: "Suggests potential exploit paths based on identified vulnerabilities",
            steps: [
                WorkflowStep(type: .promptBuilder, name: "Build Exploit Prompt", description: "Constructs an exploit suggestion prompt with vulnerability context", configuration: [
                    "template": "exploit_suggestion",
                    "includeCVEs": "true"
                ]),
                WorkflowStep(type: .llmQuery, name: "LLM Exploit Analysis", description: "Queries the LLM for exploit path suggestions", configuration: [
                    "systemPrompt": "You are a penetration testing expert. Based on the identified vulnerabilities, suggest potential exploit paths, reference known CVEs where applicable, describe attack chains, and estimate complexity. Focus on educational and authorized testing contexts. Format as structured markdown with risk ratings."
                ]),
                WorkflowStep(type: .responseParser, name: "Parse Exploit Paths", description: "Parses exploit suggestions into structured data", configuration: [
                    "format": "markdown",
                    "extractAttackChains": "true"
                ]),
                WorkflowStep(type: .confidenceScorer, name: "Score Feasibility", description: "Scores the feasibility and reliability of each suggested exploit", configuration: [
                    "method": "feasibility_based"
                ]),
                WorkflowStep(type: .knowledgeGraphUpdate, name: "Update Knowledge Graph", description: "Updates relationships between vulnerabilities and exploit paths", configuration: [
                    "entityTypes": "exploit,vulnerability,attack_chain,technique"
                ])
            ],
            requiredModel: "codestral",
            category: .exploitation
        )
    }

    private var reportGeneration: AIWorkflow {
        AIWorkflow(
            name: "Report Generation",
            description: "Generates professional security assessment reports from scan and analysis data",
            steps: [
                WorkflowStep(type: .promptBuilder, name: "Build Report Prompt", description: "Assembles all findings into a report generation prompt", configuration: [
                    "template": "report_generation",
                    "includeExecutiveSummary": "true"
                ]),
                WorkflowStep(type: .llmQuery, name: "LLM Report Writing", description: "Generates the security assessment report", configuration: [
                    "systemPrompt": "You are a professional security consultant writing a formal penetration test report. Include: Executive Summary, Scope, Methodology, Findings (sorted by severity), Risk Ratings, Detailed Recommendations, and Appendix. Use professional language and clear formatting."
                ]),
                WorkflowStep(type: .responseParser, name: "Parse Report Sections", description: "Parses the report into structured sections", configuration: [
                    "format": "markdown",
                    "extractSections": "true"
                ]),
                WorkflowStep(type: .confidenceScorer, name: "Validate Completeness", description: "Validates report completeness and consistency", configuration: [
                    "method": "completeness_check"
                ]),
                WorkflowStep(type: .knowledgeGraphUpdate, name: "Archive Report", description: "Archives report metadata for future reference", configuration: [
                    "entityTypes": "report,finding,recommendation,asset"
                ])
            ],
            requiredModel: "mistral",
            category: .reporting
        )
    }

    private var wordlistGeneration: AIWorkflow {
        AIWorkflow(
            name: "Wordlist Generation",
            description: "Generates context-aware wordlists based on target intelligence",
            steps: [
                WorkflowStep(type: .promptBuilder, name: "Build Wordlist Prompt", description: "Constructs a wordlist generation prompt from target intelligence", configuration: [
                    "template": "wordlist_generation",
                    "includeTargetIntel": "true"
                ]),
                WorkflowStep(type: .llmQuery, name: "LLM Wordlist Creation", description: "Generates context-aware wordlists", configuration: [
                    "systemPrompt": "You are a security researcher generating targeted wordlists for authorized penetration testing. Based on the target intelligence provided, generate relevant passwords, usernames, subdomains, and API patterns. Consider: company name variations, industry-specific terms, common patterns, leaked credential formats, and cultural context. Output one entry per line."
                ]),
                WorkflowStep(type: .responseParser, name: "Parse Wordlist", description: "Parses the generated wordlist and deduplicates", configuration: [
                    "format": "line_separated",
                    "deduplicate": "true"
                ]),
                WorkflowStep(type: .confidenceScorer, name: "Score Relevance", description: "Scores the relevance of generated entries to the target", configuration: [
                    "method": "relevance_based"
                ]),
                WorkflowStep(type: .knowledgeGraphUpdate, name: "Store Patterns", description: "Stores successful wordlist patterns for future reference", configuration: [
                    "entityTypes": "wordlist,target,pattern,technique"
                ])
            ],
            requiredModel: "llama3",
            category: .generation
        )
    }

    private var forensicTimeline: AIWorkflow {
        AIWorkflow(
            name: "Forensic Timeline Reconstruction",
            description: "Reconstructs forensic timelines from log data and system artifacts",
            steps: [
                WorkflowStep(type: .promptBuilder, name: "Build Timeline Prompt", description: "Constructs a forensic timeline reconstruction prompt", configuration: [
                    "template": "forensic_timeline",
                    "chronologicalOrder": "true"
                ]),
                WorkflowStep(type: .llmQuery, name: "LLM Timeline Analysis", description: "Analyzes forensic data and reconstructs the timeline", configuration: [
                    "systemPrompt": "You are a digital forensics expert reconstructing a timeline of events. Analyze the provided logs, timestamps, and system artifacts. Produce a chronological timeline with: timestamp, event type, source, description, significance, and related indicators of compromise. Identify attack phases and pivot points. Format as structured markdown with timestamps."
                ]),
                WorkflowStep(type: .responseParser, name: "Parse Timeline Events", description: "Parses timeline events into structured data", configuration: [
                    "format": "timeline",
                    "extractTimestamps": "true"
                ]),
                WorkflowStep(type: .confidenceScorer, name: "Score Timeline Confidence", description: "Scores confidence of timeline reconstruction based on evidence", configuration: [
                    "method": "evidence_chain"
                ]),
                WorkflowStep(type: .knowledgeGraphUpdate, name: "Build Attack Graph", description: "Builds an attack graph from the reconstructed timeline", configuration: [
                    "entityTypes": "event,ioc,attack_phase,asset,technique"
                ])
            ],
            requiredModel: "mistral",
            category: .forensics
        )
    }

    // MARK: - Step Processors

    private func buildPrompt(from input: WorkflowInput, configuration: [String: String]) -> String {
        var prompt = ""

        if let toolContext = input.toolContext {
            prompt += "[Tool Context: \(toolContext)]\n"
        }

        if let projectContext = input.projectContext {
            prompt += "[Project Context: \(projectContext)]\n"
        }

        if !input.metadata.isEmpty {
            prompt += "[Metadata:\n"
            for (key, value) in input.metadata.sorted(by: { $0.key < $1.key }) {
                prompt += "  \(key): \(value)\n"
            }
            prompt += "]\n"
        }

        prompt += "\n[Data]\n\(input.rawData)"

        return prompt
    }

    private func parseResponse(_ response: String, configuration: [String: String]) -> String {
        var parsed = response

        if configuration["extractSections"] == "true" || configuration["extractAttackChains"] == "true" || configuration["extractTimestamps"] == "true" {
            parsed = parsed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if configuration["deduplicate"] == "true" {
            let lines = parsed.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let unique = NSOrderedSet(array: lines)
            parsed = unique.array.compactMap { $0 as? String }.joined(separator: "\n")
        }

        return parsed
    }

    private func scoreConfidence(_ text: String, configuration: [String: String]) -> (String, Double) {
        let method = configuration["method"] ?? "default"

        var confidence = 0.5

        let certaintyMarkers = ["confirmed", "verified", "certain", "definitive", "established"]
        let uncertaintyMarkers = ["possibly", "might", "could", "perhaps", "maybe", "potentially", "likely"]

        let lowerText = text.lowercased()

        for marker in certaintyMarkers {
            if lowerText.contains(marker) { confidence += 0.05 }
        }

        for marker in uncertaintyMarkers {
            if lowerText.contains(marker) { confidence -= 0.03 }
        }

        if text.contains("CVE-") { confidence += 0.1 }
        if text.contains("CVSS") { confidence += 0.05 }
        if text.contains("http") { confidence += 0.03 }

        confidence = max(0.0, min(1.0, confidence))

        let scored = text + "\n\n---\nConfidence Score: \(String(format: "%.2f", confidence)) (\(method))\n---"

        return (scored, confidence)
    }

    private func extractKnowledgeGraphEntries(_ text: String, configuration: [String: String]) -> String {
        return text
    }

    private func extractRecommendations(from text: String) -> [String] {
        var recommendations: [String] = []
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- Recommend") || trimmed.hasPrefix("* Recommend") ||
               trimmed.lowercased().hasPrefix("recommend:") || trimmed.lowercased().hasPrefix("remediation:") {
                recommendations.append(trimmed)
            }
        }

        return recommendations
    }

    private func systemPromptForCategory(_ category: WorkflowCategory) -> String {
        switch category {
        case .analysis: return "You are a cybersecurity expert performing analysis."
        case .exploitation: return "You are a penetration testing expert. Focus on authorized testing contexts only."
        case .reporting: return "You are a professional security consultant writing reports."
        case .generation: return "You are a security researcher generating targeted resources for authorized testing."
        case .forensics: return "You are a digital forensics expert analyzing evidence."
        }
    }
}

// MARK: - AIOrchestrator

@MainActor
final class AIOrchestrator: ObservableObject {
    static let shared = AIOrchestrator()

    @Published var currentState: AIState = .idle
    @Published var insights: [AIInsight] = []
    @Published var conversations: [AIConversation] = []
    @Published var activeModel: OllamaModel?
    @Published var availableModels: [OllamaModel] = []
    @Published var activeConversation: AIConversation?
    @Published var streamingContent: String = ""
    @Published var isStreaming: Bool = false

    private let ollamaService = OllamaService.shared
    private let coreMLManager = CoreMLModelManager.shared
    private let workflowEngine = AIWorkflowEngine.shared

    private var auditLog: [AIAuditEntry] = []
    private var streamingTask: Task<Void, Never>?

    private let systemPrompt: String = """
    You are the AI assistant for MacHackerToolkit, a macOS security testing suite. \
    You have expertise in: network security, wireless analysis, penetration testing, \
    vulnerability assessment, malware analysis, digital forensics, and security reporting. \
    Always operate within legal and ethical boundaries. Provide educational and authorized-testing context. \
    When analyzing tool outputs, provide actionable insights with confidence levels.
    """

    private init() {}

    // MARK: - Server & Model Management

    func checkServerStatus() async -> Bool {
        let running = await ollamaService.isServerRunning()
        if !running {
            currentState = .error
        }
        return running
    }

    func refreshModels() async {
        do {
            let models = try await ollamaService.listModels()
            availableModels = models
            if activeModel == nil, let first = models.first {
                activeModel = first
            }
        } catch {
            currentState = .error
        }
    }

    func selectModel(_ model: OllamaModel) {
        activeModel = model
        logAudit(action: "select_model", model: model.name, input: model.displayName)
    }

    func pullModel(name: String) async throws {
        currentState = .generating
        defer { currentState = .idle }

        do {
            try await ollamaService.pullModel(name: name)
            await refreshModels()
            logAudit(action: "pull_model", model: name, input: name)
        } catch {
            currentState = .error
            throw error
        }
    }

    // MARK: - Chat Interface

    func startConversation(title: String? = nil, toolContext: String? = nil, projectContext: String? = nil) -> AIConversation {
        let modelName = activeModel?.name ?? "mistral"
        let conversation = AIConversation(
            title: title ?? "New Conversation",
            model: modelName,
            toolContext: toolContext,
            projectContext: projectContext
        )
        conversations.append(conversation)
        activeConversation = conversation
        return conversation
    }

    func sendPrompt(_ prompt: String) async {
        currentState = .generating
        defer { currentState = .idle }
        let messages = [ChatMessage(role: .system, content: systemPrompt), ChatMessage(role: .user, content: prompt)]
        do {
            let modelName = activeConversation?.model ?? "llama3.2"
            let response = try await ollamaService.chat(model: modelName, messages: messages)
            streamingContent = response.message.content
        } catch {
            streamingContent = "Error: \(error.localizedDescription)"
        }
    }

    func sendMessage(_ content: String, to conversation: inout AIConversation, stream: Bool = true) async throws {
        currentState = .generating
        defer { currentState = .idle }

        let userMessage = ChatMessage(role: .user, content: content)
        conversation.addMessage(userMessage)

        var allMessages = [ChatMessage(role: .system, content: systemPrompt)]
        if let context = buildContextMessage(for: conversation) {
            allMessages.append(context)
        }

        allMessages.append(contentsOf: conversation.messages.filter { $0.role != .system })

        let modelName = conversation.model
        let convId = conversation.id
        let toolCtx = conversation.toolContext

        if stream {
            streamingContent = ""
            isStreaming = true

            let stream = ollamaService.streamingChat(model: modelName, messages: allMessages)

            streamingTask = Task {
                for await chunk in stream {
                    if Task.isCancelled { break }
                    streamingContent += chunk
                }
                isStreaming = false

                let assistantMessage = ChatMessage(role: .assistant, content: streamingContent)

                if let idx = conversations.firstIndex(where: { $0.id == convId }) {
                    conversations[idx].addMessage(assistantMessage)
                }

                processInsights(from: streamingContent, model: modelName, toolContext: toolCtx)

                logAudit(action: "streaming_chat", model: modelName, input: content, output: String(streamingContent.prefix(200)))
            }
        } else {
            let response = try await ollamaService.chat(model: modelName, messages: allMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response.message.content)
            conversation.addMessage(assistantMessage)

            processInsights(from: response.message.content, model: modelName, toolContext: toolCtx)

            logAudit(action: "chat", model: modelName, input: content, output: String(response.message.content.prefix(200)))
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        currentState = .idle
    }

    // MARK: - Context-Aware Features

    private func buildContextMessage(for conversation: AIConversation) -> ChatMessage? {
        var contextParts: [String] = []

        if let toolContext = conversation.toolContext {
            contextParts.append("Current Tool: \(toolContext)")
        }

        if let projectContext = conversation.projectContext {
            contextParts.append("Project: \(projectContext)")
        }

        if let scanResults = conversation.scanResultContext, !scanResults.isEmpty {
            contextParts.append("Recent Scan Results:\n" + scanResults.joined(separator: "\n"))
        }

        guard !contextParts.isEmpty else { return nil }

        return ChatMessage(role: .system, content: "Context Information:\n" + contextParts.joined(separator: "\n"))
    }

    func updateConversationContext(toolContext: String? = nil, projectContext: String? = nil, scanResults: [String]? = nil) {
        guard var conversation = activeConversation else { return }

        if let toolContext = toolContext {
            conversation.toolContext = toolContext
        }
        if let projectContext = projectContext {
            conversation.projectContext = projectContext
        }
        if let scanResults = scanResults {
            conversation.scanResultContext = scanResults
        }

        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            activeConversation = conversation
        }
    }

    // MARK: - AI-Powered Insights

    func generateInsights(from toolOutput: String, toolName: String) async throws -> [AIInsight] {
        currentState = .generating
        defer { currentState = .idle }

        let modelName = activeModel?.name ?? "mistral"

        let analysisPrompt = """
        Analyze the following output from the \(toolName) tool and provide security insights.
        Identify: vulnerabilities, anomalies, potential risks, recommended actions.
        Rate severity as: Critical, High, Medium, Low, or Informational.
        Provide confidence level (0.0 to 1.0).

        Tool Output:
        \(toolOutput)
        """

        let response = try await ollamaService.generate(
            model: modelName,
            prompt: analysisPrompt,
            system: "You are a cybersecurity expert. Analyze tool outputs and provide structured insights with severity ratings and confidence scores. Format each insight as: [SEVERITY] Title: Description (Confidence: X.XX)"
        )

        let parsedInsights = parseInsights(from: response.response, model: modelName, toolContext: toolName)
        insights.append(contentsOf: parsedInsights)

        logAudit(action: "generate_insights", model: modelName, input: String(toolOutput.prefix(200)), output: String(response.response.prefix(200)))

        return parsedInsights
    }

    private func processInsights(from response: String, model: String, toolContext: String?) {
        let parsedInsights = parseInsights(from: response, model: model, toolContext: toolContext)
        if !parsedInsights.isEmpty {
            insights.append(contentsOf: parsedInsights)
        }
    }

    private func parseInsights(from text: String, model: String, toolContext: String?) -> [AIInsight] {
        var parsedInsights: [AIInsight] = []
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            var severity: AIInsightSeverity = .informational
            var confidence = 0.5

            if trimmed.contains("[CRITICAL]") || trimmed.contains("Critical:") {
                severity = .critical
                confidence = 0.9
            } else if trimmed.contains("[HIGH]") || trimmed.contains("High:") {
                severity = .high
                confidence = 0.8
            } else if trimmed.contains("[MEDIUM]") || trimmed.contains("Medium:") {
                severity = .medium
                confidence = 0.7
            } else if trimmed.contains("[LOW]") || trimmed.contains("Low:") {
                severity = .low
                confidence = 0.6
            }

            if let range = trimmed.range(of: "Confidence:\\s*([0-9.]+)", options: .regularExpression) {
                let confidenceStr = trimmed[range].replacingOccurrences(of: "Confidence:", with: "").trimmingCharacters(in: .whitespaces)
                if let parsed = Double(confidenceStr) {
                    confidence = min(1.0, max(0.0, parsed))
                }
            }

            if severity != .informational || trimmed.hasPrefix("[") {
                let insight = AIInsight(
                    title: String(trimmed.prefix(100)),
                    description: trimmed,
                    severity: severity,
                    confidence: confidence,
                    source: "AI Analysis",
                    model: model,
                    toolContext: toolContext,
                    recommendations: extractActionItems(from: trimmed)
                )
                parsedInsights.append(insight)
            }
        }

        return parsedInsights
    }

    private func extractActionItems(from text: String) -> [String] {
        var actions: [String] = []
        let patterns = ["recommend", "should", "must", "action:", "remediate", "fix", "patch", "update"]

        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".\n"))
        for sentence in sentences {
            let lower = sentence.lowercased()
            if patterns.contains(where: { lower.contains($0) }) {
                let trimmed = sentence.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    actions.append(trimmed)
                }
            }
        }

        return actions
    }

    // MARK: - Workflow Execution

    func executeWorkflow(_ category: WorkflowCategory, input: WorkflowInput) async throws -> WorkflowOutput {
        guard let workflow = workflowEngine.workflow(for: category) else {
            throw AIOrchestratorError.workflowStepFailed("No workflow found for category: \(category.rawValue)")
        }
        return try await executeWorkflow(workflow, input: input)
    }

    func executeWorkflow(_ workflow: AIWorkflow, input: WorkflowInput) async throws -> WorkflowOutput {
        currentState = .generating
        defer { currentState = .idle }

        let output = try await workflowEngine.execute(workflow: workflow, input: input)

        if !output.insights.isEmpty {
            insights.append(contentsOf: output.insights)
        }

        logAudit(
            action: "execute_workflow",
            model: workflow.requiredModel ?? "unknown",
            input: String(input.rawData.prefix(200)),
            output: String(output.result.prefix(200)),
            duration: output.duration,
            metadata: ["workflow": workflow.name, "confidence": String(format: "%.2f", output.confidence)]
        )

        return output
    }

    // MARK: - CoreML Integration

    func coreMLPredict(model name: String, input: MLInput) async throws -> MLOutput {
        let output = try await coreMLManager.predict(model: name, input: input)

        logAudit(action: "coreml_predict", model: name, input: String(describing: input.asDictionary), output: String(describing: output.asDictionary))

        return output
    }

    func loadCoreMLModels() -> [CoreMLModel] {
        coreMLManager.loadAvailableModels()
    }

    // MARK: - Unified Query

    func unifiedQuery(prompt: String, preferLocal: Bool = false, coreMLModel: String? = nil, coreMLInput: MLInput? = nil) async throws -> String {
        if preferLocal, let modelName = coreMLModel, let input = coreMLInput {
            let output = try await coreMLPredict(model: modelName, input: input)
            return formatMLOutput(output)
        }

        let modelName = activeModel?.name ?? "mistral"
        let response = try await ollamaService.generate(model: modelName, prompt: prompt, system: systemPrompt)

        logAudit(action: "unified_query", model: modelName, input: String(prompt.prefix(200)), output: String(response.response.prefix(200)))

        return response.response
    }

    private func formatMLOutput(_ output: MLOutput) -> String {
        switch output {
        case .prediction(let label, let confidence):
            return "Prediction: \(label) (Confidence: \(String(format: "%.2f", confidence)))"
        case .dictionary(let dict):
            return dict.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        case .multiArray(let dict):
            return dict.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        case .single(let key, let value):
            return "\(key): \(value)"
        }
    }

    // MARK: - Audit Logging

    private func logAudit(action: String, model: String, input: String, output: String? = nil, duration: TimeInterval = 0, metadata: [String: String] = [:]) {
        let entry = AIAuditEntry(action: action, model: model, input: input, output: output, duration: duration, metadata: metadata)
        auditLog.append(entry)
    }

    func getAuditLog() -> [AIAuditEntry] {
        auditLog
    }

    func exportAuditLog() throws -> Data {
        try JSONEncoder().encode(auditLog)
    }

    // MARK: - Conversation Management

    func deleteConversation(_ conversation: AIConversation) {
        conversations.removeAll { $0.id == conversation.id }
        if activeConversation?.id == conversation.id {
            activeConversation = conversations.last
        }
    }

    func clearConversationHistory() {
        conversations.removeAll()
        activeConversation = nil
    }

    func searchConversations(query: String) -> [AIConversation] {
        let lowerQuery = query.lowercased()
        return conversations.filter { conversation in
            conversation.title.lowercased().contains(lowerQuery) ||
            conversation.messages.contains { $0.content.lowercased().contains(lowerQuery) }
        }
    }

    // MARK: - Insight Management

    func clearInsights() {
        insights.removeAll()
    }

    func insights(for severity: AIInsightSeverity) -> [AIInsight] {
        insights.filter { $0.severity == severity }
    }

    func insights(forTool tool: String) -> [AIInsight] {
        insights.filter { $0.toolContext == tool }
    }

    var criticalInsightCount: Int {
        insights.filter { $0.severity == .critical }.count
    }

    var highInsightCount: Int {
        insights.filter { $0.severity == .high }.count
    }
}
