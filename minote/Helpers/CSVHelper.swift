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
    
    // 从CSV格式的字符串解析心情记录数组，带重复检测
    static func importFromCSVWithDuplicateCheck(csvContent: String, existingRecords: [MoodRecord]) -> (imported: [MoodRecord], skipped: Int) {
        var newRecords: [MoodRecord] = []
        var skippedCount = 0
        
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
                    
                    // 检查是否与现有记录重复
                    let isDuplicate = existingRecords.contains { existingRecord in
                        return isDuplicateRecord(
                            existing: existingRecord,
                            newStartTime: startTime,
                            newEndTime: endTime,
                            newMood: mood,
                            newActivity: activity,
                            newNote: note
                        )
                    }
                    
                    if isDuplicate {
                        skippedCount += 1
                        continue // 跳过重复记录
                    }
                    
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
                    
                    newRecords.append(record)
                }
            }
        }
        
        return (imported: newRecords, skipped: skippedCount)
    }
    
    // 从CSV格式的字符串解析心情记录数组
    static func importFromCSV(csvContent: String) -> [MoodRecord] {
        let result = importFromCSVWithDuplicateCheck(csvContent: csvContent, existingRecords: [])
        return result.imported
    }
    
    // 检查记录是否重复的辅助方法
    private static func isDuplicateRecord(
        existing: MoodRecord,
        newStartTime: Date,
        newEndTime: Date,
        newMood: String,
        newActivity: String,
        newNote: String
    ) -> Bool {
        // 方案1：精确匹配 - 检查时间是否相同（允许1分钟误差）
        let timeToleranceSeconds: TimeInterval = 60 // 1分钟
        let startTimeDiff = abs(existing.startTime.timeIntervalSince(newStartTime))
        let endTimeDiff = abs(existing.endTime.timeIntervalSince(newEndTime))
        
        let timeMatches = startTimeDiff <= timeToleranceSeconds && endTimeDiff <= timeToleranceSeconds
        
        // 检查内容是否相同
        let moodMatches = existing.mood == newMood
        let activityMatches = existing.activity == newActivity
        let noteMatches = existing.note.trimmingCharacters(in: .whitespacesAndNewlines) == 
                         newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果时间和所有内容都匹配，则认为是重复记录
        if timeMatches && moodMatches && activityMatches && noteMatches {
            return true
        }
        
        // 方案2：宽松匹配 - 相同时间段内的相似记录
        let extendedTimeToleranceSeconds: TimeInterval = 300 // 5分钟
        let extendedStartTimeDiff = abs(existing.startTime.timeIntervalSince(newStartTime))
        let extendedEndTimeDiff = abs(existing.endTime.timeIntervalSince(newEndTime))
        
        let extendedTimeMatches = extendedStartTimeDiff <= extendedTimeToleranceSeconds && 
                                 extendedEndTimeDiff <= extendedTimeToleranceSeconds
        
        // 如果时间相近且心情和活动都相同，认为是可能的重复记录
        if extendedTimeMatches && moodMatches && activityMatches {
            // 检查备注相似度（如果都为空或者内容相似）
            let existingNoteClean = existing.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let newNoteClean = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if existingNoteClean.isEmpty && newNoteClean.isEmpty {
                return true // 都为空备注
            }
            
            if !existingNoteClean.isEmpty && !newNoteClean.isEmpty {
                // 计算文本相似度（简单版本）
                let similarity = calculateTextSimilarity(existingNoteClean, newNoteClean)
                if similarity > 0.8 { // 80%相似度
                    return true
                }
            }
        }
        
        return false
    }
    
    // 计算两个字符串的相似度（简单版本）
    private static func calculateTextSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.isEmpty {
            return shorter.isEmpty ? 1.0 : 0.0
        }
        
        // 计算编辑距离
        let distance = levenshteinDistance(str1, str2)
        let similarity = 1.0 - Double(distance) / Double(longer.count)
        
        return max(0.0, similarity)
    }
    
    // 计算编辑距离（Levenshtein距离）
    private static func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let len1 = arr1.count
        let len2 = arr2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 {
            matrix[i][0] = i
        }
        for j in 0...len2 {
            matrix[0][j] = j
        }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = arr1[i-1] == arr2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // 删除
                    matrix[i][j-1] + 1,      // 插入
                    matrix[i-1][j-1] + cost  // 替换
                )
            }
        }
        
        return matrix[len1][len2]
    }
    
    // 根据心情名称获取对应的颜色 - 使用系统颜色名称
    private static func getMoodColor(for mood: String) -> String {
        let moodColors = [
            "开心": "yellow",
            "平静": "blue", 
            "难过": "gray",
            "生气": "red",
            "焦虑": "purple",
            "兴奋": "pink"
        ]
        return moodColors[mood] ?? "yellow" // 默认黄色
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
