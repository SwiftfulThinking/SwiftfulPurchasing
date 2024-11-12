//
//  PurchaseLogger.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 11/11/24.
//
@MainActor
public protocol PurchaseLogger {
    func trackEvent(event: PurchaseLogEvent)
    func addUserProperties(dict: [String: Any], isHighPriority: Bool)
}

public protocol PurchaseLogEvent {
    var eventName: String { get }
    var parameters: [String: Any]? { get }
    var type: PurchaseLogType { get }
}

public enum PurchaseLogType: Int, CaseIterable, Sendable {
    case info // 0
    case analytic // 1
    case warning // 2
    case severe // 3

    var emoji: String {
        switch self {
        case .info:
            return "👋"
        case .analytic:
            return "📈"
        case .warning:
            return "⚠️"
        case .severe:
            return "🚨"
        }
    }

    var asString: String {
        switch self {
        case .info: return "info"
        case .analytic: return "analytic"
        case .warning: return "warning"
        case .severe: return "severe"
        }
    }
}
