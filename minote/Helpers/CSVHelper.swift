// CSV数据处理辅助工具 - 用于导出和导入心情记录数据
import Foundation
import SwiftData

// CSV处理器 - 负责将心情记录转换为CSV格式，或从CSV格式读取数据
struct CSVHelper {
    
    // 将心情记录数组转换为CSV格式的字符串
    static func exportToCSV(records: [MoodRecord]) -> String {
        // CSV文件的标题行（第一行），包含时间段字段
        var csvContent = "记录时间,心情,活动,笔记,开始时间,结束时间,创建时间\n"
        
        // 日期格式化器 - 用于将日期转换为字符串
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 标准日期格式
        
        // 遍历每个记录，将其转换为CSV行
        for record in records {
            let eventTime = dateFormatter.string(from: record.eventTime)
            let mood = record.mood
            let activity = record.activity ?? ""
            // 清理笔记内容：移除换行符，替换逗号为分号（避免CSV格式冲突）
            let note = record.note.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ",", with: ";")
            
            // 时间段字段
            let startTime = record.startTime != nil ? dateFormatter.string(from: record.startTime!) : ""
            let endTime = record.endTime != nil ? dateFormatter.string(from: record.endTime!) : ""
            
            let createdAt = dateFormatter.string(from: record.createdAt)
            
            // 构建CSV行，包含时间段字段
            let csvRow = "\(eventTime),\(mood),\(activity),\(note),\(startTime),\(endTime),\(createdAt)\n"
            csvContent += csvRow
        }
        
        return csvContent
    }
    
    /// 从CSV格式的字符串解析心情记录数组，带重复检测
    static func importFromCSV(csvContent: String, existingRecords: [MoodRecord]) -> (imported: [MoodRecord], skipped: Int) {
        var newRecords: [MoodRecord] = []
        var skippedCount = 0
        
        // 将CSV内容按行分割
        let lines = csvContent.components(separatedBy: .newlines)
        
        // 日期格式化器 - 用于将字符串转换为日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 跳过第一行（标题行），从第二行开始处理数据
        for line in lines.dropFirst() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                continue
            }
            
            // 将行按逗号分割成字段
            let fields = trimmedLine.components(separatedBy: ",")
            
            // 支持新格式（7个字段）和旧格式（5个字段）
            let hasTimeRangeFields = fields.count >= 7
            let fieldsCount = hasTimeRangeFields ? 7 : 5
            
            // 确保有足够的字段
            if fields.count >= fieldsCount {
                // 解析基本字段
                let eventTimeField = fields[0]
                let moodField = fields[1]
                let activityField = fields[2]
                let noteField = fields[3]
                
                // 根据字段数量解析时间段和创建时间
                var startTimeField = ""
                var endTimeField = ""
                var createdAtField = ""
                
                if hasTimeRangeFields {
                    // 新格式: 记录时间,心情,活动,笔记,开始时间,结束时间,创建时间
                    startTimeField = fields[4]
                    endTimeField = fields[5]
                    createdAtField = fields[6]
                } else {
                    // 旧格式: 记录时间,心情,活动,笔记,创建时间
                    createdAtField = fields[4]
                }
                
                // 解析日期
                if let eventTime = dateFormatter.date(from: eventTimeField),
                   let createdAt = dateFormatter.date(from: createdAtField) {
                    
                    let mood = moodField
                    let activity = activityField
                    // 恢复笔记内容：将分号替换回逗号
                    let note = noteField.replacingOccurrences(of: ";", with: ",")
                    
                    // 解析时间段（如果有）
                    var startTime: Date? = nil
                    var endTime: Date? = nil
                    
                    if hasTimeRangeFields {
                        if !startTimeField.isEmpty {
                            startTime = dateFormatter.date(from: startTimeField)
                        }
                        if !endTimeField.isEmpty {
                            endTime = dateFormatter.date(from: endTimeField)
                        }
                    }
                    
                    // 检查是否与现有记录重复
                    let isDuplicate = existingRecords.contains { existingRecord in
                        return isDuplicateRecord(
                            existing: existingRecord,
                            newEventTime: eventTime,
                            newMood: mood,
                            newActivity: activity,
                            newNote: note
                        )
                    }
                    
                    if isDuplicate {
                        skippedCount += 1
                        continue // 跳过重复记录
                    }
                    
                    // 创建新的心情记录，包含时间段信息
                    let record = MoodRecord(
                        eventTime: eventTime,
                        note: note,
                        mood: mood,
                        activity: activity,
                        startTime: startTime,
                        endTime: endTime
                    )

                    // 设置创建时间（保持原始创建时间）
                    record.createdAt = createdAt
                    
                    newRecords.append(record)
                }
            }
        }
        
        return (imported: newRecords, skipped: skippedCount)
    }
    
    // 检查记录是否重复的辅助方法
    private static func isDuplicateRecord(
        existing: MoodRecord,
        newEventTime: Date,
        newMood: String,
        newActivity: String,
        newNote: String
    ) -> Bool {
        // 检查时间是否相同（允许1秒误差）
        let timeToleranceSeconds: TimeInterval = 1
        let eventTimeDiff = abs(existing.eventTime.timeIntervalSince(newEventTime))
        
        let timeMatches = eventTimeDiff <= timeToleranceSeconds
        
        // 检查内容是否相同
        let moodMatches = existing.mood == newMood
        let activityMatches = existing.activity == newActivity
        let noteMatches = existing.note.trimmingCharacters(in: .whitespacesAndNewlines) ==
                         newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果时间和所有内容都匹配，则认为是重复记录
        return timeMatches && moodMatches && activityMatches && noteMatches
    }
}
