import SwiftUI
import SwiftData

// 基类定义HealthKit管理器的通用接口
class BaseHealthKitManager: ObservableObject {
    @Published var isHealthKitAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    
    func requestAuthorization() async {}
    func saveMoodToHealthKit(mood: String, startTime: Date, endTime: Date, note: String) async -> Bool { return false }
    func syncLocalRecordsToHealthKit(records: [MoodRecord]) async -> (success: Int, failed: Int) { return (0, 0) }
    func importHealthKitRecordsToLocal() async -> [MoodRecord] { return [] }
    func getMoodColor(for mood: String) -> String { return "blue" }
}

@main
struct SimpleMoodApp: App {
    @StateObject private var healthKitManager: BaseHealthKitManager = {
        if #available(iOS 16.0, *) {
            return HealthKitMoodManager()
        } else {
            return BaseHealthKitManager()
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(healthKitManager)
        }
        .modelContainer(for: [MoodRecord.self, CustomMoodTag.self, CustomActivityTag.self])
    }
}
