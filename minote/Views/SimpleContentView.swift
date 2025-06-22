import SwiftUI
import SwiftData

/*
 主内容视图 - 应用的核心界面
 
 这个视图负责显示心情记录列表，是用户最常看到的界面
 主要功能：
 1. 显示所有心情记录
 2. 添加新的心情记录
 3. 编辑现有记录
 4. 使用本地心情记录功能
 */

// MARK: - StateOfMindRecordCard 组件

/// 心情记录卡片组件 - 专门展示单条记录的详细信息
struct StateOfMindRecordCard: View {
    let record: MoodRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息：时间和心情
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(record.eventTime))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if record.startTime != nil || record.endTime != nil {
                        Text(formatTimeRange(start: record.startTime, end: record.endTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 心情显示区域 - 重点突出 State of Mind
                VStack(alignment: .trailing, spacing: 4) {
                    Text("心情")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.mood)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(moodColor(for: record.mood))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(moodColor(for: record.mood).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // 活动信息
            if let activity = record.activity, !activity.isEmpty {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text("活动：\(activity)")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            // 笔记内容
            if !record.note.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    Text(record.note)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
            
            // HealthKit 同步状态指示
            HStack {
                Spacer()
                
                if record.healthKitUUID != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("已同步 HealthKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("未同步")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 辅助方法
    
    /// 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化时间段显示
    private func formatTimeRange(start: Date?, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        
        if let start = start, let end = end {
            return "时段：\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = start {
            return "开始：\(formatter.string(from: start))"
        } else if let end = end {
            return "结束：\(formatter.string(from: end))"
        }
        return ""
    }
    
    /// 根据心情返回对应的颜色
    private func moodColor(for mood: String) -> Color {
        switch mood.lowercased() {
        case let x where x.contains("开心") || x.contains("快乐") || x.contains("愉悦"):
            return .green
        case let x where x.contains("悲伤") || x.contains("难过") || x.contains("沮丧"):
            return .blue
        case let x where x.contains("愤怒") || x.contains("生气") || x.contains("恼怒"):
            return .red
        case let x where x.contains("焦虑") || x.contains("紧张") || x.contains("担心"):
            return .orange
        case let x where x.contains("平静") || x.contains("平和") || x.contains("宁静"):
            return .mint
        case let x where x.contains("兴奋") || x.contains("激动") || x.contains("亢奋"):
            return .yellow
        default:
            return .purple
        }
    }
}

// MARK: - SimpleContentView

struct SimpleContentView: View {
    // MARK: - 数据和状态
    
    /// SwiftData数据库上下文，用于数据操作
    @Environment(\.modelContext) private var modelContext
    
    /// HealthKit管理器
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    /// 从数据库查询所有心情记录，按创建时间倒序排列
    @Query(sort: \MoodRecord.createdAt, order: .reverse) private var records: [MoodRecord]
    
    /// 控制是否显示记录编辑页面
    @State private var showingRecordEditor = false
    
    /// 控制是否显示添加记录页面
    @State private var showingAddRecord = false
    
    /// 当前要编辑的记录
    @State private var recordToEdit: MoodRecord?
    
    // MARK: - 界面布局
    
    var body: some View {
        NavigationStack {
            VStack {
                // 记录列表区域
                recordsSection
                
                // 添加记录按钮
                addRecordButton
            }
            .navigationTitle("心情日记")
            // 记录编辑的弹窗
            .sheet(isPresented: $showingRecordEditor) {
                if let record = recordToEdit {
                    NavigationStack {
                        EditRecordView(record: record)
                            .environmentObject(healthKitManager)
                            .modelContainer(modelContext.container)
                    }
                }
            }
            // 添加记录的弹窗
            .sheet(isPresented: $showingAddRecord) {
                NavigationStack {
                    UnifiedRecordView()
                        .environmentObject(healthKitManager)
                        .modelContainer(modelContext.container)
                }
            }
        }
        .onAppear {
            // 页面出现时的初始化，SwiftData 会自动加载数据
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用重新激活时，SwiftData 会自动处理数据刷新
        }
    }
    
    // MARK: - 子视图组件
    
    /// 记录列表部分
    private var recordsSection: some View {
        Group {
            if records.isEmpty {
                // 空状态视图
                emptyStateView
            } else {
                // 记录列表
                List {
                    ForEach(records.sorted { $0.eventTime > $1.eventTime }) { record in
                        Button(action: {
                            recordToEdit = record
                            showingRecordEditor = true
                        }) {
                            StateOfMindRecordCard(record: record)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteRecords)  // 支持左滑删除
                }
            }
        }
    }
    
    /// 空状态视图 - 当没有记录时显示
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("还没有心情记录")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("点击下方按钮开始记录你的心情吧！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    /// 添加记录按钮
    private var addRecordButton: some View {
        Button(action: {
            showingAddRecord = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                Text("添加记录")
                    .font(.headline)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - 数据操作方法
    
    /// 删除记录
    private func deleteRecords(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let recordToDelete = records[index]
                
                // 如果记录有HealthKit UUID，先从HealthKit删除
                if let healthKitUUID = recordToDelete.healthKitUUID {
                    let deleted = await healthKitManager.deleteMoodRecord(uuid: healthKitUUID)
                    if deleted {
                        print("✅ 已从HealthKit删除记录: \(healthKitUUID)")
                    } else {
                        print("⚠️ 从HealthKit删除记录失败: \(healthKitUUID)")
                    }
                }
                
                // 从本地数据库删除
                await MainActor.run {
                    withAnimation {
                        modelContext.delete(recordToDelete)
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    SimpleContentView()
        .environmentObject(HealthKitMoodManager())
}
