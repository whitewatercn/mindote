import SwiftUI
import SwiftData
import Foundation
import HealthKit

/*
 应用的主入口文件
 
 这个文件定义了整个iOS应用的启动点和基本配置
 主要功能：
 1. 创建应用的主窗口
 2. 设置数据存储（SwiftData）
 3. 初始化HealthKit管理器
 */

@main
struct SimpleMoodApp: App {
    /*
     @StateObject 用于创建和管理一个在应用生命周期内持续存在的对象
     这里创建HealthKit管理器，用于与苹果健康应用交互
     */
    @StateObject private var healthKitManager = HealthKitMoodManager()
    
    init() {
        // 删除旧的数据库文件以避免迁移问题
        cleanupOldDatabase()
    }
    
    var body: some Scene {
        WindowGroup {
            // 主界面 - 包含Tab导航的根视图
            MainTabView()
                // 将HealthKit管理器传递给所有子视图
                .environmentObject(healthKitManager)
        }
        // 配置SwiftData数据存储，指定要存储的数据模型
        .modelContainer(for: [
            MoodRecord.self,        // 心情记录
            CustomMoodTag.self,     // 自定义心情标签
            CustomActivityTag.self  // 自定义活动标签
        ]) { result in
            do {
                let container = try result.get()
                // 强制删除旧数据库并使用新的数据库文件
                container.mainContext.autosaveEnabled = true
                print("✅ 数据库容器创建成功")
            } catch {
                print("❌ 创建数据库容器失败: \(error)")
            }
        }
    }
    
    // 清理旧数据库文件
    private func cleanupOldDatabase() {
        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldDatabaseURL = applicationSupport.appendingPathComponent("default.store")
        
        if fileManager.fileExists(atPath: oldDatabaseURL.path) {
            do {
                try fileManager.removeItem(at: oldDatabaseURL)
                print("✅ 已删除旧数据库文件")
            } catch {
                print("⚠️ 删除旧数据库文件失败: \(error)")
            }
        }
    }
}
