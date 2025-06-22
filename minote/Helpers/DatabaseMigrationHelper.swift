import SwiftUI
import SwiftData
import Foundation

/// 数据库迁移助手
class DatabaseMigrationHelper {
    
    /// 检查并处理数据库迁移
    static func handleMigrationIfNeeded() {
        // 获取应用支持目录的数据库文件路径
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("无法获取应用支持目录")
            return
        }
        
        let databaseURL = appSupportURL.appendingPathComponent("default.store")
        
        // 检查是否存在旧的数据库文件
        if fileManager.fileExists(atPath: databaseURL.path) {
            print("检测到现有数据库文件")
            
            // 检查版本兼容性
            if needsMigration() {
                print("需要数据库迁移，正在备份并重置...")
                backupAndResetDatabase(at: databaseURL)
            }
        }
    }
    
    /// 检查是否需要迁移
    private static func needsMigration() -> Bool {
        // 检查用户默认设置中的数据库版本
        let currentVersion = "2.0" // 新版本包含时间段字段
        let storedVersion = UserDefaults.standard.string(forKey: "DatabaseVersion") ?? "1.0"
        
        return storedVersion != currentVersion
    }
    
    /// 备份并重置数据库
    private static func backupAndResetDatabase(at databaseURL: URL) {
        let fileManager = FileManager.default
        
        do {
            // 创建备份
            let backupURL = databaseURL.appendingPathExtension("backup.\(Date().timeIntervalSince1970)")
            try fileManager.copyItem(at: databaseURL, to: backupURL)
            print("数据库已备份到: \(backupURL.lastPathComponent)")
            
            // 删除原数据库文件
            try fileManager.removeItem(at: databaseURL)
            print("原数据库已删除")
            
            // 删除相关文件
            let walURL = databaseURL.appendingPathExtension("wal")
            let shmURL = databaseURL.appendingPathExtension("shm")
            
            if fileManager.fileExists(atPath: walURL.path) {
                try fileManager.removeItem(at: walURL)
            }
            if fileManager.fileExists(atPath: shmURL.path) {
                try fileManager.removeItem(at: shmURL)
            }
            
            // 更新版本号
            UserDefaults.standard.set("2.0", forKey: "DatabaseVersion")
            print("数据库迁移完成")
            
        } catch {
            print("数据库迁移失败: \(error)")
        }
    }
    
    /// 首次启动时设置版本号
    static func setInitialVersionIfNeeded() {
        if UserDefaults.standard.string(forKey: "DatabaseVersion") == nil {
            UserDefaults.standard.set("2.0", forKey: "DatabaseVersion")
            print("设置初始数据库版本: 2.0")
        }
    }
}
