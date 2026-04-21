//
//  QuickActionButton.swift
//  MacHackerToolkit
//
//  Quick Action Button Component
//

import SwiftUI

struct QuickActionButton: View {
    let action: QuickAction
    let actionHandler: () -> Void
    
    var body: some View {
        Button(action: actionHandler) {
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text(action.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        #if os(iOS)
        #if os(iOS)
        .hoverEffect(.lift)
        #endif
        #endif
        }
        .buttonStyle(.plain)
    }
}

struct QuickAction: Identifiable {
    let id: UUID = UUID()
    let title: String
    let icon: String
    let description: String
    
    static let allActions: [QuickAction] = [
        QuickAction(title: "Network Scan", icon: "network", description: "Scan local network for devices"),
        QuickAction(title: "Wi-Fi Scan", icon: "wifi", description: "Discover Wi-Fi networks"),
        QuickAction(title: "Bluetooth Scan", icon: "dot.radiowaves.left.and.right", description: "Discover Bluetooth devices"),
        QuickAction(title: "Vuln Scan", icon: "shield.lefthalf.filled", description: "Scan for vulnerabilities"),
        QuickAction(title: "Password Audit", icon: "key", description: "Test password strength"),
        QuickAction(title: "Exploit Search", icon: "magnifyingglass", description: "AI-powered exploit search")
    ]
}

struct ActiveToolRow: View {
    let job: ToolJob
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.toolName)
                    .font(.headline)
                
                Text(job.parameters.map { $0 }.joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                ProgressView(value: job.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(job.status.displayText)
                    .font(.caption)
                    .foregroundColor(job.status.color)
                
                Text((job.elapsedTime ?? 0).formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if job.status == .running {
                    Button(action: { job.cancel() }) {
                        Image(systemName: "stop.circle")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        #if os(iOS)
        .hoverEffect(.lift)
        #endif
    }
}
struct ToolStatus {
    enum StatusValue {
        case pending, running, completed, failed, cancelled
        
        var displayText: String {
            switch self {
            case .pending: return "Pending"
            case .running: return "Running"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .gray
            case .running: return .blue
            case .completed: return .green
            case .failed: return .red
            case .cancelled: return .orange
            }
        }
    }
}
