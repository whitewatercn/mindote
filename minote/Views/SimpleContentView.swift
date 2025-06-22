import SwiftUI
import SwiftData

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
                // HealthKit集成区域
                healthKitSection
                
                // 记录列表区域
                recordsSection
            }
            .navigationTitle("心情记录")
            .toolbar {
                // 导航栏右上角的添加按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加记录") {
                        showingAddRecord = true
                    }
                }
            }
        }
        // 添加记录的弹窗
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView()
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
    }
    
    // MARK: - 子视图组件
    
    /// HealthKit集成部分的界面
    private var healthKitSection: some View {
        VStack(spacing: 12) {
            Text("健康应用集成")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // HealthKit状态指示器
                healthKitStatusView
                
                Spacer()
                
                // 打开健康应用按钮
                Button(action: {
                    healthKitManager.openHealthApp()
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("记录心情")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!healthKitManager.isAuthorized)
            }
            
            Text("点击上方按钮打开健康应用，使用系统原生的心情记录功能")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    /// HealthKit状态显示
    private var healthKitStatusView: some View {
        HStack {
            // 状态图标
            Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
            
            // 状态文字
            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit状态")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(healthKitStatusText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
            }
        }
    }
    
    /// HealthKit状态文字
    private var healthKitStatusText: String {
        if !healthKitManager.isHealthKitAvailable {
            return "不可用"
        } else if healthKitManager.isAuthorized {
            return "已授权"
        } else {
            return "需要授权"
        }
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
                
                // 在主线程更新UI（如果需要）
                await MainActor.run {
                    // 这里可以处理从HealthKit加载的数据
                    // 比如合并到本地数据库或显示同步状态
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
    SimpleContentView()
        .environmentObject(HealthKitMoodManager())
}
