import SwiftUI
import SwiftData

/*
 本地心情管理器 - 完全基于应用内部实现
 
 主要功能：
 1. 本地心情记录存储和管理
 2. 提供心情记录界面和逻辑
 3. 不依赖 HealthKit，完全独立运行
 4. 支持 iOS 17.6+
 */

@MainActor
class LocalMoodManager: ObservableObject {
    
    // MARK: - 单例
    static let shared = LocalMoodManager()
    
    private init() {}
    
    // MARK: - 预定义标签
    
    /// 预定义的心情选项
    static let moodOptions = [
        "开心", "平静", "难过", "激动", "疲惫", "其他"
    ]
    
    /// 预定义的事件选项
    static let activityOptions = [
        "工作", "学习", "休息", "娱乐", "家务", "运动", "餐饮", "旅行", "其他"
    ]
}
