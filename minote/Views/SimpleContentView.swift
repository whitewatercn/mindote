import SwiftUI
import SwiftData

struct SimpleContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodRecord.createdAt, order: .reverse) private var records: [MoodRecord]
    @Query private var customMoodTags: [CustomMoodTag]
    @Query private var customActivityTags: [CustomActivityTag]
    
    @State private var showingAddRecord = false
    @State private var showingEditRecord = false
    @State private var recordToEdit: MoodRecord?
    
    var body: some View {
        // 导航视图 - 提供导航功能
        NavigationView {
            VStack {
                // 如果没有记录，显示空状态
                if records.isEmpty {
                    EmptyView()
                } else {
                    // 显示记录列表
                    List {
                        ForEach(records) { record in
                            // 每个记录的显示行
                            RecordRow(record: record) {
                                // 点击记录时的操作
                                recordToEdit = record
                                showingEditRecord = true
                            }
                        }
                        // 支持左滑删除
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .navigationTitle("心情记录") // 导航栏标题
            .toolbar {
                // 右上角添加按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingAddRecord = true
                    }
                }
            }
        }
        // 添加记录页面的弹窗
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView()
        }
        // 编辑记录页面的弹窗
        .sheet(isPresented: $showingEditRecord) {
            if let record = recordToEdit {
                EditRecordView(record: record)
            }
        }
        .onAppear {
            // 页面出现时创建默认数据
            createDefaultData()
        }
    }
    
    // 删除记录的方法
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
    
    // 创建默认数据的方法
    private func createDefaultData() {
        // 如果数据库为空，创建一些示例数据
        if records.isEmpty {
            let sampleRecord = MoodRecord(
                startTime: Date().addingTimeInterval(-3600), // 1小时前
                endTime: Date(),
                note: "这是一个示例记录",
                mood: "开心",
                moodColor: "#FFD700",
                activity: "学习",
                activityIcon: "book.fill"
            )
            modelContext.insert(sampleRecord)
        }
        
        // 创建默认的自定义标签（如果不存在）
        createDefaultCustomTags()
    }
    
    // 创建默认自定义标签的方法
    private func createDefaultCustomTags() {
        // 如果没有自定义心情标签，创建一些默认的
        if customMoodTags.isEmpty {
            let defaultMoodTags = [
                CustomMoodTag(name: "感激", color: "#32CD32", isDefault: true),
                CustomMoodTag(name: "疲惫", color: "#8B4513", isDefault: true),
                CustomMoodTag(name: "满足", color: "#FFB6C1", isDefault: true),
                CustomMoodTag(name: "迷茫", color: "#9370DB", isDefault: true)
            ]
            
            for tag in defaultMoodTags {
                modelContext.insert(tag)
            }
        }
        
        // 如果没有自定义活动标签，创建一些默认的
        if customActivityTags.isEmpty {
            let defaultActivityTags = [
                CustomActivityTag(name: "冥想", icon: "leaf.fill", isDefault: true),
                CustomActivityTag(name: "购物", icon: "bag.fill", isDefault: true),
                CustomActivityTag(name: "清洁", icon: "sparkles", isDefault: true),
                CustomActivityTag(name: "旅行", icon: "suitcase.fill", isDefault: true)
            ]
            
            for tag in defaultActivityTags {
                modelContext.insert(tag)
            }
        }
    }
}

// 空状态视图 - 当没有记录时显示
struct EmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 心形图标
            Image(systemName: "heart.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            // 提示文字
            Text("还没有记录")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("点击右上角的\"添加\"按钮开始记录你的心情")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// 记录行视图 - 显示单个记录的信息
struct RecordRow: View {
    let record: MoodRecord // 要显示的记录
    let onTap: () -> Void // 点击时的操作
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 时间和持续时间
                HStack {
                    Text(record.timeString)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(record.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // 笔记内容
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 心情和活动标签
                HStack {
                    // 心情标签
                    HStack {
                        Text(record.mood)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: record.moodColor))
                            .cornerRadius(8)
                    }
                    
                    // 活动标签
                    HStack {
                        Image(systemName: record.activityIcon)
                            .font(.caption)
                        Text(record.activity)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 颜色扩展 - 支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
