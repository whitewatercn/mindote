import SwiftUI
import SwiftData

@Model
class MoodRecord {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var note: String
    // 心情（开心、难过等）
    var mood: String
    // 心情颜色
    var moodColor: String
    // 活动（工作、学习等）
    var activity: String
    // 活动图标
    var activityIcon: String
    // 创建时间
    var createdAt: Date
    
    // 初始化方法 - 创建新记录时调用
    init(startTime: Date, endTime: Date, note: String, mood: String, moodColor: String, activity: String, activityIcon: String) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.note = note
        self.mood = mood
        self.moodColor = moodColor
        self.activity = activity
        self.activityIcon = activityIcon
        self.createdAt = Date()
    }
    
    // 计算持续时间的方法
    var duration: String {
        let timeInterval = endTime.timeIntervalSince(startTime)
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // 格式化时间显示
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        let startString = formatter.string(from: startTime)
        
        formatter.dateFormat = "HH:mm"
        let endString = formatter.string(from: endTime)
        
        return "\(startString)-\(endString)"
    }
}

// 自定义心情标签模型 - 存储用户创建的心情标签
@Model
class CustomMoodTag {
    // 标签的唯一标识
    var id: UUID
    // 标签名称
    var name: String
    // 标签颜色（十六进制格式）
    var color: String
    // 是否为预设标签
    var isDefault: Bool
    // 创建时间
    var createdAt: Date
    
    // 初始化方法
    init(name: String, color: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

// 自定义活动标签模型 - 存储用户创建的活动标签
@Model
class CustomActivityTag {
    // 标签的唯一标识
    var id: UUID
    // 标签名称
    var name: String
    // 标签图标（SF Symbol名称）
    var icon: String
    // 是否为预设标签
    var isDefault: Bool
    // 创建时间
    var createdAt: Date
    
    // 初始化方法
    init(name: String, icon: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
