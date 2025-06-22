import SwiftUI
import SwiftData
import HealthKit

/*
 主内容视图 - 应用的核心界面
 
 这个视图负责显示心情记录列表，是用户最常看到的界面
 主要功能：
 1. 显示所有心情记录
 2. 添加新的心情记录
 3. 编辑现有记录
 4. 调用HealthKit的State of Mind功能
 */
struct SimpleContentView: View {
    // MARK: - 数据和状态
    
    /// SwiftData数据库上下文，用于数据操作
    @Environment(\.modelContext) private var modelContext
    
    /// 从数据库查询所有心情记录，按创建时间倒序排列
    @Query(sort: \MoodRecord.createdAt, order: .reverse) private var records: [MoodRecord]
    
    /// HealthKit管理器，用于与苹果健康应用交互
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    /// 控制是否显示添加记录页面
    @State private var showingAddRecord = false
    
    /// 控制是否显示编辑记录页面
    @State private var showingEditRecord = false
    
    /// 当前要编辑的记录
    @State private var recordToEdit: MoodRecord?
    
    // MARK: - 界面布局
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 记录按钮区域
                recordButtonSection
                
                // 记录列表区域
                recordsSection
            }
            .navigationTitle("心情记录")
        }
        // 记录界面的弹窗
        .sheet(isPresented: $showingAddRecord) {
            UnifiedRecordView()
        }
        .onChange(of: showingAddRecord) { oldValue, newValue in
            // 当记录界面关闭时，刷新数据
            if oldValue && !newValue {
                refreshData()
            }
        }
        // 编辑记录的弹窗
        .sheet(isPresented: $showingEditRecord) {
            if let record = recordToEdit {
                EditRecordView(record: record)
            }
        }
        .onAppear {
            // 视图出现时加载数据
            loadDataFromHealthKit()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用重新激活时刷新数据
            refreshData()
        }
    }
    
    // MARK: - 子视图组件
    
    /// 记录按钮区域
    private var recordButtonSection: some View {
        VStack(spacing: 12) {
            Text("记录你的心情")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button(action: {
                showingAddRecord = true
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                    Text("开始记录")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Text("记录时间段和事件，点击心情按钮在应用内记录")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    /// 记录列表部分
    private var recordsSection: some View {
        Group {
            if records.isEmpty {
                // 空状态视图
                emptyStateView
            } else {
                // 记录列表
                List {
                    ForEach(records) { record in
                        RecordRow(record: record) {
                            // 点击记录时进入编辑模式
                            recordToEdit = record
                            showingEditRecord = true
                        }
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
            
            Text("点击上方按钮开始记录你的心情吧！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 数据操作方法
    
    /// 删除记录
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let recordToDelete = records[index]
                
                // 如果这个记录关联了HealthKit数据，也尝试删除
                Task {
                    await healthKitManager.deleteMood(id: recordToDelete.id.uuidString)
                }
                
                // 从本地数据库删除
                modelContext.delete(recordToDelete)
            }
        }
    }
    
    /// 从HealthKit加载数据
    private func loadDataFromHealthKit() {
        // 如果HealthKit已授权，尝试加载数据
        if healthKitManager.isAuthorized {
            Task {
                let healthKitRecords = await healthKitManager.loadMoodRecords()
                print("从HealthKit加载了 \(healthKitRecords.count) 条记录")
                
                await MainActor.run {
                    // 将HealthKit记录合并到本地数据库
                    for healthKitRecord in healthKitRecords {
                        // 检查是否已经存在相同时间的记录，避免重复
                        let existingRecord = records.first { record in
                            abs(record.startTime.timeIntervalSince(healthKitRecord.startTime)) < 60 // 1分钟内认为是同一条记录
                        }
                        
                        if existingRecord == nil {
                            // 创建新的本地记录
                            let newRecord = MoodRecord(
                                startTime: healthKitRecord.startTime,
                                endTime: healthKitRecord.endTime,
                                note: healthKitRecord.note,
                                mood: healthKitRecord.mood,
                                moodColor: healthKitRecord.moodColor,
                                activity: healthKitRecord.activity,
                                activityIcon: healthKitRecord.activityIcon
                            )
                            
                            modelContext.insert(newRecord)
                        }
                    }
                    
                    // 保存上下文
                    try? modelContext.save()
                }
            }
        }
    }
    
    /// 刷新数据 - 在记录保存后调用
    private func refreshData() {
        Task {
            // 重新从HealthKit加载最新数据
            if healthKitManager.isAuthorized {
                let healthKitRecords = await healthKitManager.loadMoodRecords()
                print("刷新：从HealthKit加载了 \(healthKitRecords.count) 条记录")
                
                await MainActor.run {
                    // 将新的HealthKit记录合并到本地数据库
                    for healthKitRecord in healthKitRecords {
                        // 检查是否已经存在相同时间的记录，避免重复
                        let existingRecord = records.first { record in
                            abs(record.startTime.timeIntervalSince(healthKitRecord.startTime)) < 60
                        }
                        
                        if existingRecord == nil {
                            // 创建新的本地记录
                            let newRecord = MoodRecord(
                                startTime: healthKitRecord.startTime,
                                endTime: healthKitRecord.endTime,
                                note: healthKitRecord.note,
                                mood: healthKitRecord.mood,
                                moodColor: healthKitRecord.moodColor,
                                activity: healthKitRecord.activity,
                                activityIcon: healthKitRecord.activityIcon
                            )
                            
                            modelContext.insert(newRecord)
                        }
                    }
                    
                    // 保存上下文
                    try? modelContext.save()
                    print("数据已刷新和同步")
                }
            }
        }
    }
}

// MARK: - 记录行视图

/// 单个心情记录的显示行
struct RecordRow: View {
    let record: MoodRecord
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // 心情图标和颜色
            Circle()
                .fill(Color(record.moodColor))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // 心情和活动
                HStack {
                    Text(record.mood)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(record.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 备注（如果有）
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 活动和持续时间
                HStack {
                    Image(systemName: record.activityIcon)
                        .foregroundColor(.blue)
                    Text(record.activity)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(record.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())  // 让整行都可以点击
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 预览

#Preview {
    SimpleContentView().environmentObject(HealthKitMoodManager())
}
