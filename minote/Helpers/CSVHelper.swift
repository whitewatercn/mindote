// CSV数据处理辅助工具 - 用于导出和导入心情记录数据
import Foundation

// CSV处理器 - 负责将心情记录转换为CSV格式，或从CSV格式读取数据
struct CSVHelper {
    
    // 将心情记录数组转换为CSV格式的字符串
    static func exportToCSV(records: [MoodRecord]) -> String {
        // CSV文件的标题行（第一行）
        var csvContent = "开始时间,结束时间,心情,活动,笔记,创建时间\n"
        
        // 日期格式化器 - 用于将日期转换为字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 标准日期格式
        
        // 遍历每个记录，将其转换为CSV行
        for record in records {
            let startTime = dateFormatter.string(from: record.startTime)
            let endTime = dateFormatter.string(from: record.endTime)
            let mood = record.mood
            let activity = record.activity
            // 清理笔记内容：移除换行符，替换逗号为分号（避免CSV格式冲突）
            let note = record.note.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ",", with: ";")
            let createdAt = dateFormatter.string(from: record.createdAt)
            
            // 构建CSV行
            let csvRow = "\(startTime),\(endTime),\(mood),\(activity),\(note),\(createdAt)\n"
            csvContent += csvRow
        }
        
        return csvContent
    }
    
    // 从CSV格式的字符串解析心情记录数组
    static func importFromCSV(csvContent: String) -> [MoodRecord] {
        var records: [MoodRecord] = []
        
        // 将CSV内容按行分割
        let lines = csvContent.components(separatedBy: .newlines)
        
        // 日期格式化器 - 用于将字符串转换为日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 跳过第一行（标题行），从第二行开始处理数据
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if line.isEmpty {
                continue
            }
            
            // 将行按逗号分割成字段
            let fields = line.components(separatedBy: ",")
            
            // 确保有足够的字段（至少6个）
            if fields.count >= 6 {
                // 解析各个字段
                if let startTime = dateFormatter.date(from: fields[0]),
                   let endTime = dateFormatter.date(from: fields[1]),
                   let createdAt = dateFormatter.date(from: fields[5]) {
                    
                    let mood = fields[2]
                    let activity = fields[3]
                    // 恢复笔记内容：将分号替换回逗号
                    let note = fields[4].replacingOccurrences(of: ";", with: ",")
                    
                    // 根据心情名称获取颜色（包括自定义标签）
                    let moodColor = getMoodColor(for: mood)
                    // 根据活动名称获取图标（包括自定义标签）
                    let activityIcon = getActivityIcon(for: activity)
                    
                    // 创建新的心情记录
                    let record = MoodRecord(
                        startTime: startTime,
                        endTime: endTime,
                        note: note,
                        mood: mood,
                        moodColor: moodColor,
                        activity: activity,
                        activityIcon: activityIcon
                    )
                    
                    // 设置创建时间（保持原始创建时间）
                    record.createdAt = createdAt
                    
                    records.append(record)
                }
            }
        }
        
        return records
    }
    
    // 根据心情名称获取对应的颜色
    private static func getMoodColor(for mood: String) -> String {
        // 使用预定义颜色
        let moodColors = [
            "开心": "#FFD700",
            "平静": "#87CEEB", 
            "难过": "#708090",
            "生气": "#FF6347",
            "焦虑": "#DDA0DD",
            "兴奋": "#FF69B4"
        ]
        return moodColors[mood] ?? "#FFD700" // 默认金色
    }
    
    // 根据活动名称获取对应的图标
    private static func getActivityIcon(for activity: String) -> String {
        // 使用预定义图标
        let activityIcons = [
            "工作": "briefcase.fill",
            "学习": "book.fill",
            "运动": "figure.run",
            "休息": "bed.double.fill",
            "娱乐": "gamecontroller.fill",
            "社交": "person.2.fill",
            "吃饭": "fork.knife",
            "通勤": "car.fill"
        ]
        return activityIcons[activity] ?? "star.fill" // 默认星形图标
    }
}
