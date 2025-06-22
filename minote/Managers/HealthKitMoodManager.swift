import Foundation
import HealthKit
import SwiftUI

@available(iOS 16.0, *)
class HealthKitMoodManager: BaseHealthKitManager {
    private let healthStore = HKHealthStore()
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    
    // 使用State of Mind类型 (iOS 16+)
    private let stateOfMindType = HKCategoryType(.stateOfMind)
    
    init() {
        checkHealthKitAvailability()
    }
    
    // 检查HealthKit是否可用
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    // 请求HealthKit权限
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            print("HealthKit不可用")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stateOfMindType]
        let typesToWrite: Set<HKSampleType> = [stateOfMindType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
            }
            print("HealthKit权限授权成功")
        } catch {
            print("HealthKit权限请求失败: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }
    
    // 将心情记录保存到HealthKit（使用State of Mind）
    func saveMoodToHealthKit(mood: String, startTime: Date, endTime: Date, note: String) async -> Bool {
        guard isAuthorized else {
            print("HealthKit未授权")
            return false
        }
        
        // 将心情字符串转换为State of Mind值
        let (valence, labels) = mapMoodToStateOfMind(mood: mood)
        
        // 创建metadata，包含note和标签信息
        var metadata: [String: Any] = [:]
        if !note.isEmpty {
            metadata[HKMetadataKeyUserMotivatedPeriod] = note
        }
        
        // 添加State of Mind标签
        if !labels.isEmpty {
            metadata[HKMetadataKeyStateOfMindLabels] = labels
        }
        
        // 创建State of Mind样本
        let moodSample = HKCategorySample(
            type: stateOfMindType,
            value: valence.rawValue,
            start: startTime,
            end: endTime,
            metadata: metadata.isEmpty ? nil : metadata
        )
        
        do {
            try await healthStore.save(moodSample)
            print("心情数据已保存到HealthKit")
            return true
        } catch {
            print("保存心情数据到HealthKit失败: \(error.localizedDescription)")
            return false
        }
    }
    
    
    // 将心情字符串映射到HealthKit State of Mind值和标签
    private func mapMoodToStateOfMind(mood: String) -> (HKCategoryValueStateOfMind, [Int]) {
        switch mood.lowercased() {
        case "非常积极", "很开心", "极好":
            return (.veryPleasant, [HKStateOfMindLabel.happy.rawValue, HKStateOfMindLabel.joyful.rawValue])
        case "积极", "开心", "好":
            return (.pleasant, [HKStateOfMindLabel.happy.rawValue, HKStateOfMindLabel.content.rawValue])
        case "有点积极", "还行", "不错":
            return (.slightlyPleasant, [HKStateOfMindLabel.content.rawValue])
        case "中性", "一般", "平静":
            return (.neutral, [HKStateOfMindLabel.peaceful.rawValue])
        case "有点消极", "不太好", "烦躁":
            return (.slightlyUnpleasant, [HKStateOfMindLabel.irritated.rawValue])
        case "消极", "难过", "不好":
            return (.unpleasant, [HKStateOfMindLabel.sad.rawValue])
        case "非常消极", "很难过", "极差":
            return (.veryUnpleasant, [HKStateOfMindLabel.sad.rawValue, HKStateOfMindLabel.depressed.rawValue])
        default:
            return (.neutral, [])
        }
    }
    
    // 将HealthKit State of Mind值映射回心情字符串
    private func mapStateOfMindToMood(value: HKCategoryValueStateOfMind) -> String {
        switch value {
        case .veryUnpleasant:
            return "非常消极"
        case .unpleasant:
            return "消极"
        case .slightlyUnpleasant:
            return "有点消极"
        case .neutral:
            return "中性"
        case .slightlyPleasant:
            return "有点积极"
        case .pleasant:
            return "积极"
        case .veryPleasant:
            return "非常积极"
        @unknown default:
            return "中性"
        }
    }
    
    // 获取State of Mind标签的描述
    private func getStateOfMindLabelDescription(_ labelValue: Int) -> String {
        guard let label = HKStateOfMindLabel(rawValue: labelValue) else {
            return "未知"
        }
        
        switch label {
        case .joyful: return "快乐"
        case .happy: return "开心"
        case .content: return "满足"
        case .peaceful: return "平静"
        case .grateful: return "感激"
        case .hopeful: return "充满希望"
        case .confident: return "自信"
        case .energetic: return "精力充沛"
        case .focused: return "专注"
        case .calm: return "冷静"
        case .restful: return "休息"
        case .comfortable: return "舒适"
        case .proud: return "自豪"
        case .amazed: return "惊讶"
        case .amused: return "愉快"
        case .excited: return "兴奋"
        case .loved: return "被爱"
        case .thankful: return "感谢"
        case .optimistic: return "乐观"
        case .pleased: return "满意"
        case .blissful: return "幸福"
        case .ecstatic: return "狂喜"
        case .elated: return "高兴"
        case .euphoric: return "愉悦"
        case .cheerful: return "愉快"
        case .delighted: return "高兴"
        case .overjoyed: return "非常高兴"
        case .passionate: return "热情"
        case .serene: return "安详"
        case .tranquil: return "宁静"
        case .carefree: return "无忧无虑"
        case .relaxed: return "放松"
        case .relieved: return "放心"
        case .satisfied: return "满足"
        case .blessed: return "幸运"
        case .fulfilled: return "满意"
        case .neutral: return "中性"
        case .indifferent: return "冷漠"
        case .bored: return "无聊"
        case .tired: return "疲倦"
        case .drained: return "筋疲力尽"
        case .apathetic: return "冷漠"
        case .listless: return "无精打采"
        case .restless: return "不安"
        case .unsettled: return "不安定"
        case .stressed: return "压力"
        case .anxious: return "焦虑"
        case .worried: return "担心"
        case .overwhelmed: return "不知所措"
        case .nervous: return "紧张"
        case .irritated: return "烦躁"
        case .annoyed: return "恼怒"
        case .frustrated: return "沮丧"
        case .angry: return "生气"
        case .livid: return "愤怒"
        case .furious: return "狂怒"
        case .outraged: return "愤慨"
        case .bitter: return "痛苦"
        case .sad: return "难过"
        case .disappointed: return "失望"
        case .discouraged: return "气馁"
        case .hopeless: return "绝望"
        case .dejected: return "沮丧"
        case .heartbroken: return "心碎"
        case .grief: return "悲伤"
        case .despair: return "绝望"
        case .depressed: return "抑郁"
        case .lonely: return "孤独"
        case .isolated: return "孤立"
        case .empty: return "空虚"
        case .guilty: return "内疚"
        case .ashamed: return "羞愧"
        case .regretful: return "后悔"
        case .remorseful: return "懊悔"
        case .disgusted: return "厌恶"
        case .horrified: return "恐惧"
        case .scared: return "害怕"
        case .terrified: return "恐怖"
        case .panicked: return "恐慌"
        @unknown default: return "未知"
        }
    }
    private func mapStateOfMindToMood(value: HKCategoryValueStateOfMind) -> String {
        switch value {
        case .veryUnpleasant:
            return "非常消极"
        case .unpleasant:
            return "消极"
        case .slightlyUnpleasant:
            return "有点消极"
        case .neutral:
            return "中性"
        case .slightlyPleasant:
            return "有点积极"
        case .pleasant:
            return "积极"
        case .veryPleasant:
            return "非常积极"
        @unknown default:
            return "中性"
        }
    }
    
    // 从HealthKit读取心情记录
    func fetchMoodFromHealthKit(startDate: Date, endDate: Date) async -> [HKCategorySample] {
        guard isAuthorized else {
            print("HealthKit未授权")
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stateOfMindType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("读取HealthKit心情数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    let moodSamples = samples as? [HKCategorySample] ?? []
                    continuation.resume(returning: moodSamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // 从State of Mind样本解析心情信息
    private func parseMoodFromStateOfMind(sample: HKCategorySample) -> (mood: String, labels: [String]) {
        guard let stateOfMindValue = HKCategoryValueStateOfMind(rawValue: sample.value) else {
            return (mood: "中性", labels: [])
        }
        
        let mood = mapStateOfMindToMood(value: stateOfMindValue)
        
        // 解析标签
        var labels: [String] = []
        if let metadata = sample.metadata,
           let labelValues = metadata[HKMetadataKeyStateOfMindLabels] as? [Int] {
            labels = labelValues.map { getStateOfMindLabelDescription($0) }
        }
        
        return (mood: mood, labels: labels)
    }
    
    // 从元数据中提取备注
    private func extractNoteFromMetadata(metadata: [String: Any]?) -> String {
        guard let metadata = metadata,
              let note = metadata[HKMetadataKeyUserMotivatedPeriod] as? String else {
            return ""
        }
        return note
    }
    
    // 获取心情颜色
    func getMoodColor(for mood: String) -> String {
        switch mood {
        case "非常积极", "狂欢", "兴奋":
            return "yellow"
        case "积极", "愉快", "满足":
            return "green"
        case "中性", "平静", "一般":
            return "blue"
        case "有点消极", "失落", "沮丧":
            return "orange"
        case "消极", "非常消极", "绝望", "抑郁":
            return "red"
        default:
            return "blue"
        }
    }
    
    // 同步本地记录到HealthKit
    func syncLocalRecordsToHealthKit(records: [MoodRecord]) async -> (success: Int, failed: Int) {
        var successCount = 0
        var failedCount = 0
        
        for record in records {
            let success = await saveMoodToHealthKit(
                mood: record.mood,
                startTime: record.startTime,
                endTime: record.endTime,
                note: record.note
            )
            
            if success {
                successCount += 1
            } else {
                failedCount += 1
            }
        }
        
        return (success: successCount, failed: failedCount)
    }
    
    // 从HealthKit导入心情记录到本地
    func importHealthKitRecordsToLocal() async -> [MoodRecord] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let healthKitSamples = await fetchMoodFromHealthKit(startDate: thirtyDaysAgo, endDate: Date())
        
        var localRecords: [MoodRecord] = []
        
        for sample in healthKitSamples {
            let (mood, labels) = parseMoodFromStateOfMind(sample: sample)
            let moodColor = getMoodColor(for: mood)
            let note = extractNoteFromMetadata(metadata: sample.metadata)
            
            // 如果有标签，将其添加到备注中
            let finalNote = labels.isEmpty ? note : 
                note.isEmpty ? "标签: \(labels.joined(separator: ", "))" :
                "\(note)\n标签: \(labels.joined(separator: ", "))"
            
            let record = MoodRecord(
                startTime: sample.startDate,
                endTime: sample.endDate,
                note: finalNote,
                mood: mood,
                moodColor: moodColor,
                activity: "日常", // 默认活动
                activityIcon: "figure.walk"
            )
            
            localRecords.append(record)
        }
        
        return localRecords
    }
}
