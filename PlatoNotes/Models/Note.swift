import Foundation
import SwiftData

enum ExpirationDuration: Int, Codable, CaseIterable, Identifiable {
    case fiveMinutes = 300
    case oneHour = 3600
    case twentyFourHours = 86400
    case threeDays = 259200
    case sevenDays = 604800

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 Minutes"
        case .oneHour: return "1 Hour"
        case .twentyFourHours: return "24 Hours"
        case .threeDays: return "3 Days"
        case .sevenDays: return "7 Days"
        }
    }

    var shortName: String {
        switch self {
        case .fiveMinutes: return "5m"
        case .oneHour: return "1h"
        case .twentyFourHours: return "24h"
        case .threeDays: return "3d"
        case .sevenDays: return "7d"
        }
    }
}

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var expiresAt: Date
    var expirationDuration: ExpirationDuration

    var isExpired: Bool {
        Date.now >= expiresAt
    }

    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date.now))
    }

    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "Expired" }

        let days = Int(remaining) / 86400
        let hours = Int(remaining) % 86400 / 3600
        let minutes = Int(remaining) % 3600 / 60
        let seconds = Int(remaining) % 60

        if days > 0 {
            return "\(days)d \(hours)h remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }

    var progressRemaining: Double {
        let total = expirationDuration.rawValue
        let remaining = timeRemaining
        return min(1.0, max(0.0, remaining / Double(total)))
    }

    init(
        title: String = "",
        content: String = "",
        expirationDuration: ExpirationDuration = .twentyFourHours
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date.now
        self.expirationDuration = expirationDuration
        self.expiresAt = Date.now.addingTimeInterval(TimeInterval(expirationDuration.rawValue))
    }
}
