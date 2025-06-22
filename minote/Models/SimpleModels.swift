import SwiftUI
import SwiftData

@Model
class MoodRecord {
    var id: UUID
    var eventTime: Date
    var note: String
    var mood: String
    var activity: String?
    var startTime: Date?  // 时间段开始时间
    var endTime: Date?    // 时间段结束时间
    var healthKitUUID: UUID?  // HealthKit 记录的 UUID，用于编辑时删除
    var createdAt: Date
    
    init(eventTime: Date, note: String, mood: String, activity: String?, startTime: Date? = nil, endTime: Date? = nil, healthKitUUID: UUID? = nil) {
        self.id = UUID()
        self.eventTime = eventTime
        self.note = note
        self.mood = mood
        self.activity = activity
        self.startTime = startTime
        self.endTime = endTime
        self.healthKitUUID = healthKitUUID
        self.createdAt = Date()
    }
    
    // 格式化时间显示
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: eventTime)
    }
    
    // 格式化时间段显示
    var timeRangeString: String {
        guard let start = startTime, let end = endTime else {
            return "无时间段"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// 自定义心情标签模型
@Model
class CustomMoodTag {
    var id: UUID
    var name: String
    var color: String // 存储颜色的十六进制值
    var isDefault: Bool // 是否为默认标签
    var createdAt: Date
    
    init(name: String, color: String = "#007AFF", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

// 自定义活动标签模型
@Model
class CustomActivityTag {
    var id: UUID
    var name: String
    var icon: String // SF Symbol名称
    var isDefault: Bool // 是否为默认标签
    var createdAt: Date
    
    init(name: String, icon: String = "star", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
