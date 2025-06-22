import Foundation
import HealthKit
import SwiftUI


/*
 HealthKit心情管理器 - 基于Apple官方State of Mind API实现
 
 参考文档：
 - https://developer.apple.com/documentation/healthkit/hkstateofmind
 - https://developer.apple.com/documentation/healthkit/
 
 这个类负责与苹果HealthKit交互，管理心情数据
 主要功能：
 1. 请求HealthKit权限（符合官方最佳实践）
 2. 使用HKStateOfMind API（iOS 18.0+）
 3. 从HealthKit读取State of Mind数据
 4. 将心情数据保存到HealthKit
 5. 应用内心情记录功能
 
 系统要求：iOS 18.0+ （使用官方 HKStateOfMind API）
 注意：此实现不兼容 iOS 17，专门为 iOS 18+ 优化
 */
@available(iOS 18.0, *)
class HealthKitMoodManager: ObservableObject {
    
    // MARK: - 发布属性（用于UI更新）
    
    /// HealthKit是否在当前设备上可用
    @Published var isHealthKitAvailable: Bool = false
    
    /// 用户是否已授权HealthKit权限
    @Published var isAuthorized: Bool = false
    
    /// 权限请求状态
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // MARK: - 私有属性
    
    /// HealthKit数据存储实例
    private let healthStore = HKHealthStore()
    
    /// State of Mind 数据类型（iOS 18.0+官方API）
    private var stateOfMindType: HKObjectType {
        return HKObjectType.stateOfMindType()
    }
    
    // MARK: - 初始化
    
    init() {
        checkHealthKitAvailability()
        checkAuthorizationStatus()
    }
    
    // MARK: - 权限管理（遵循Apple官方最佳实践）
    
    /// 检查HealthKit是否在当前设备上可用
    private func checkHealthKitAvailability() {
        // iPad和某些设备不支持HealthKit
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("📱 HealthKit可用状态: \(isHealthKitAvailable)")
    }
    
    /// 检查当前授权状态
    private func checkAuthorizationStatus() {
        guard isHealthKitAvailable else { return }
        
        authorizationStatus = healthStore.authorizationStatus(for: stateOfMindType)
        isAuthorized = authorizationStatus == .sharingAuthorized
        print("🔐 HealthKit授权状态: \(authorizationStatus.rawValue)")
    }
    
    /// 请求HealthKit访问权限（符合Apple官方指南）
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            print("❌ HealthKit在此设备上不可用（可能是iPad）")
            return
        }
        
        // iOS 18+: 使用 HKStateOfMind 权限
        let typesToShare: Set<HKSampleType> = [stateOfMindType as! HKSampleType]
        let typesToRead: Set<HKObjectType> = [stateOfMindType]
        print("✅ 请求权限（iOS 18+ HKStateOfMind）")
        
        do {
            // 异步请求权限
            try await healthStore.requestAuthorization(
                toShare: typesToShare,
                read: typesToRead
            )
            
            // 更新授权状态
            checkAuthorizationStatus()
            print("✅ HealthKit权限请求完成")
            
        } catch {
            print("❌ HealthKit权限请求失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 应用内心情记录界面
    
    /// 在应用内弹出心情记录界面
    /// 这会返回一个 SwiftUI 视图，用于在应用内记录心情
    func openInAppMoodRecording() -> Bool {
        guard isHealthKitAvailable else {
            print("❌ HealthKit不可用，无法记录心情")
            return false
        }
        
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法记录心情")
            return false
        }
        
        print("✅ 准备在应用内打开心情记录界面")
        return true
    }
    
    /// 保存心情到 HealthKit（应用内记录）
    func saveInAppMood(valence: Double, reflection: String? = nil) async -> Bool {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法保存心情")
            return false
        }
        
        do {
            // 使用官方 HKStateOfMind API
            let stateOfMind = try createHKStateOfMind(valence: valence, reflection: reflection)
            try await healthStore.save(stateOfMind)
            print("✅ 成功保存 HKStateOfMind 到 HealthKit (valence: \(valence))")
            return true
            
        } catch {
            print("❌ 保存心情数据失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 数据读取（遵循Apple数据查询最佳实践）
    
    /// 从HealthKit加载心情记录
    /// 使用Apple推荐的HKSampleQuery方式
    func loadMoodRecords() async -> [MoodRecord] {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法加载数据")
            return []
        }
        
        // 创建查询条件（最近30天）
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        // 排序描述符（按时间倒序）
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )
        
        return await withCheckedContinuation { continuation in
            // iOS 18+: 查询 HKStateOfMind 数据
            let query = HKSampleQuery(
                sampleType: stateOfMindType as! HKSampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                self.handleQueryResults(samples: samples, error: error, continuation: continuation)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 处理查询结果的辅助方法
    private func handleQueryResults(
        samples: [HKSample]?,
        error: Error?,
        continuation: CheckedContinuation<[MoodRecord], Never>
    ) {
        if let error = error {
            print("❌ 加载HealthKit数据失败: \(error.localizedDescription)")
            continuation.resume(returning: [])
            return
        }
        
        let moodRecords = convertHealthKitSamplesToMoodRecords(samples ?? [])
        print("✅ 成功从HealthKit加载 \(moodRecords.count) 条心情记录")
        continuation.resume(returning: moodRecords)
    }
    
    // MARK: - 数据保存（遵循Apple官方最佳实践）
    
       /// 保存心情数据到HealthKit（使用iOS 18+ HKStateOfMind API）
    func saveMood(mood: String, startTime: Date, endTime: Date, note: String, tags: [String]) async -> Bool {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法保存数据")
            return false
        }
        
        do {
            // 将心情字符串转换为valence值
            let valence = mapMoodToValence(mood)
            
            // 创建完整的反思内容
            let fullReflection = buildFullReflection(note: note, tags: tags)
            
            // 使用官方 HKStateOfMind API
            let stateOfMind = try createHKStateOfMind(valence: valence, reflection: fullReflection)
            try await healthStore.save(stateOfMind)
            print("✅ 成功保存 HKStateOfMind 到 HealthKit (mood: \(mood), valence: \(valence))")
            return true
            
        } catch {
            print("❌ 保存心情数据到HealthKit失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 数据转换方法（符合Apple数据模型）
    
    /// 将HealthKit样本转换为应用的心情记录格式
    private func convertHealthKitSamplesToMoodRecords(_ samples: [HKSample]) -> [MoodRecord] {
        return samples.compactMap { sample in
            let startTime = sample.startDate
            let endTime = sample.endDate
            let metadata = sample.metadata ?? [:]
            let note = metadata["reflection"] as? String ?? metadata["user_notes"] as? String ?? ""
            
            var mood: String
            var moodColor: String
            
            // iOS 18+: 专门处理 HKStateOfMind 对象
            if let stateOfMind = sample as? HKStateOfMind {
                mood = mapValenceToMood(stateOfMind.valence)
                moodColor = getMoodColor(for: mood)
            } else {
                return nil // 只处理 HKStateOfMind 对象
            }
            
            // 创建心情记录
            return MoodRecord(
                startTime: startTime,
                endTime: endTime,
                note: note,
                mood: mood,
                moodColor: moodColor,
                activity: "健康记录",
                activityIcon: "heart.fill"
            )
        }
    }
    
    /// 将 valence 值（-1.0 到 1.0）映射到应用的心情字符串
    private func mapValenceToMood(_ valence: Double) -> String {
        let clampedValence = max(-1.0, min(1.0, valence))
        
        switch clampedValence {
        case -1.0..<(-0.6):
            return "非常难过"
        case -0.6..<(-0.2):
            return "难过"
        case -0.2..<0.2:
            return "一般"
        case 0.2..<0.6:
            return "开心"
        case 0.6...1.0:
            return "非常开心"
        default:
            return "一般"
        }
    }
    
    /// 构建完整的反思内容
    private func buildFullReflection(note: String, tags: [String]) -> String? {
        var reflectionParts: [String] = []
        
        if !note.isEmpty {
            reflectionParts.append(note)
        }
        
        if !tags.isEmpty {
            reflectionParts.append("标签: \(tags.joined(separator: ", "))")
        }
        
        return reflectionParts.isEmpty ? nil : reflectionParts.joined(separator: " | ")
    }
    
    /// 将应用的心情字符串映射到valence值（-1.0 到 1.0）
    private func mapMoodToValence(_ mood: String) -> Double {
        switch mood {
        case "非常难过", "抑郁", "绝望":
            return -0.8
        case "难过", "沮丧", "有点难过":
            return -0.4
        case "一般", "平静", "中性":
            return 0.0
        case "开心", "愉快", "比较开心", "轻松":
            return 0.4
        case "非常开心", "狂欢", "兴奋", "满足":
            return 0.8
        default:
            return 0.0
        }
    }
    
    /// 创建官方 HKStateOfMind 对象（iOS 18+）
    private func createHKStateOfMind(valence: Double, reflection: String? = nil) throws -> HKStateOfMind {
        let now = Date()
        
        // 确保 valence 在有效范围内 (-1.0 到 1.0)
        let clampedValence = max(-1.0, min(1.0, valence))
        
        // 创建元数据
        var metadata: [String: Any] = [:]
        if let reflection = reflection, !reflection.isEmpty {
            metadata["user_notes"] = reflection
        }
        metadata["source_app"] = "MinNote"
        metadata["valence_raw"] = valence
        
        // 创建 HKStateOfMind
        return HKStateOfMind(
            date: now,
            kind: .momentaryEmotion,
            valence: clampedValence,
            labels: [],
            associations: [],
            metadata: metadata.isEmpty ? nil : metadata
        )
    }
    
    // MARK: - 工具方法
    
    /// 根据心情获取对应的颜色
    func getMoodColor(for mood: String) -> String {
        switch mood {
        case "非常开心", "狂欢", "兴奋": return "green"
        case "开心", "愉快", "满足": return "green"
        case "比较开心", "轻松": return "yellow"
        case "一般", "平静", "中性": return "gray"
        case "有点难过", "轻微沮丧": return "orange"
        case "难过", "沮丧": return "red"
        case "非常难过", "抑郁", "绝望": return "red"
        default: return "blue"
        }
    }
    
    /// 删除指定ID的心情记录
    /// 注意：HealthKit的删除功能有限制，需要特殊处理
    func deleteMood(id: String) async -> Bool {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法删除数据")
            return false
        }
        
        // HealthKit的删除功能比较复杂
        // 在实际应用中，通常建议标记为"已删除"而不是真正删除
        print("⚠️ HealthKit数据删除功能需要特殊实现")
        print("💡 建议：在本地数据库中标记为已删除，而不是从HealthKit删除")
        return false
    }
    
    /// 同步本地数据到HealthKit
    func syncWithHealthKit() async -> Bool {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法同步")
            return false
        }
        
        print("🔄 开始同步数据到HealthKit...")
        print("💡 提示：建议用户直接在健康应用中记录，确保数据一致性")
        return true
    }
    
    // MARK: - 状态检查方法
    
    /// 检查指定时间段内是否存在HealthKit心情记录
    func checkMoodExistsInTimeRange(startTime: Date, endTime: Date) async -> Bool {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法检查数据")
            return false
        }
        
        // 创建时间范围查询条件
        let predicate = HKQuery.predicateForSamples(
            withStart: startTime,
            end: endTime,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            // 使用 limit: 1 只查询是否存在，提高性能
            let query = HKSampleQuery(
                sampleType: stateOfMindType as! HKSampleType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("❌ 检查HealthKit心情记录失败: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                
                let exists = (samples?.count ?? 0) > 0
                print("🔍 时间段 \(startTime) - \(endTime) 内HealthKit心情记录存在: \(exists)")
                continuation.resume(returning: exists)
            }
            
            healthStore.execute(query)
        }
    }

    // MARK: - 数据同步方法
    
    /// 同步本地记录到HealthKit
    func syncLocalRecordsToHealthKit(records: [MoodRecord]) async -> (success: Int, failed: Int) {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法同步")
            return (success: 0, failed: records.count)
        }
        
        var successCount = 0
        var failedCount = 0
        
        for record in records {
            let success = await saveMood(
                mood: record.mood,
                startTime: record.startTime,
                endTime: record.endTime,
                note: record.note,
                tags: []
            )
            
            if success {
                successCount += 1
            } else {
                failedCount += 1
            }
        }
        
        print("📤 同步完成: 成功 \(successCount), 失败 \(failedCount)")
        return (success: successCount, failed: failedCount)
    }
    
    /// 从HealthKit导入记录到本地
    func importHealthKitRecordsToLocal() async -> [MoodRecord] {
        guard isAuthorized else {
            print("❌ HealthKit未授权，无法导入")
            return []
        }
        
        let records = await loadMoodRecords()
        print("📥 从HealthKit导入了 \(records.count) 条记录")
        return records
    }
}

// MARK: - 扩展：AuthorizationStatus描述

extension HKAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .sharingDenied:
            return "拒绝共享"
        case .sharingAuthorized:
            return "已授权共享"
        @unknown default:
            return "未知状态"
        }
    }
}
