// 编辑记录界面 - 用户编辑已有的心情记录
import SwiftUI
import SwiftData

struct EditRecordView: View {
    // 数据库上下文
    @Environment(\.modelContext) private var modelContext
    // 关闭页面的方法
    @Environment(\.dismiss) private var dismiss
    
    // 查询自定义标签
    @Query private var customMoodTags: [CustomMoodTag]
    @Query private var customActivityTags: [CustomActivityTag]
    
    let record: MoodRecord // 要编辑的记录
    
    // 表单数据（用原记录的数据初始化）
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note: String
    @State private var selectedMood: String
    @State private var selectedMoodColor: String
    @State private var selectedActivity: String
    @State private var selectedActivityIcon: String
    
    // 控制删除确认对话框和添加标签弹窗
    @State private var showingDeleteAlert = false
    @State private var showingAddMoodTag = false
    @State private var showingAddActivityTag = false
    
    // 预定义的心情选项
    private let moods = [
        ("开心", "#FFD700"),
        ("平静", "#87CEEB"),
        ("难过", "#708090"),
        ("生气", "#FF6347"),
        ("焦虑", "#DDA0DD"),
        ("兴奋", "#FF69B4")
    ]
    
    // 预定义的活动选项
    private let activities = [
        ("工作", "briefcase.fill"),
        ("学习", "book.fill"),
        ("运动", "figure.run"),
        ("休息", "bed.double.fill"),
        ("娱乐", "gamecontroller.fill"),
        ("社交", "person.2.fill"),
        ("吃饭", "fork.knife"),
        ("通勤", "car.fill")
    ]
    
    // 初始化方法 - 用现有记录的数据填充表单
    init(record: MoodRecord) {
        self.record = record
        _startTime = State(initialValue: record.startTime)
        _endTime = State(initialValue: record.endTime)
        _note = State(initialValue: record.note)
        _selectedMood = State(initialValue: record.mood)
        _selectedMoodColor = State(initialValue: record.moodColor)
        _selectedActivity = State(initialValue: record.activity)
        _selectedActivityIcon = State(initialValue: record.activityIcon)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 时间设置部分
                Section("时间设置") {
                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("结束时间", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                    
                    // 时间验证提示
                    if endTime <= startTime {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("结束时间必须晚于开始时间")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // 笔记部分
                Section("笔记") {
                    TextField("记录你的心情和想法...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // 心情选择部分
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        // 预定义心情
                        ForEach(moods, id: \.0) { mood, color in
                            MoodButton(
                                title: mood,
                                color: color,
                                isSelected: selectedMood == mood
                            ) {
                                selectedMood = mood
                                selectedMoodColor = color
                            }
                        }
                        
                        // 自定义心情标签
                        ForEach(customMoodTags) { tag in
                            MoodButton(
                                title: tag.name,
                                color: tag.color,
                                isSelected: selectedMood == tag.name
                            ) {
                                selectedMood = tag.name
                                selectedMoodColor = tag.color
                            }
                        }
                        
                        // 添加自定义心情标签按钮
                        Button(action: { showingAddMoodTag = true }) {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                Text("添加")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("选择心情")
                }
                
                // 活动选择部分
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        // 预定义活动
                        ForEach(activities, id: \.0) { activity, icon in
                            ActivityButton(
                                title: activity,
                                icon: icon,
                                isSelected: selectedActivity == activity
                            ) {
                                selectedActivity = activity
                                selectedActivityIcon = icon
                            }
                        }
                        
                        // 自定义活动标签
                        ForEach(customActivityTags) { tag in
                            ActivityButton(
                                title: tag.name,
                                icon: tag.icon,
                                isSelected: selectedActivity == tag.name
                            ) {
                                selectedActivity = tag.name
                                selectedActivityIcon = tag.icon
                            }
                        }
                        
                        // 添加自定义活动标签按钮
                        Button(action: { showingAddActivityTag = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .font(.body)
                                    .frame(width: 16, height: 16)
                                Text("添加标签")
                                    .font(.body)
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("选择活动")
                }
                
                // 删除部分
                Section {
                    Button("删除这条记录") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 取消按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                // 保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(endTime <= startTime) // 时间无效时禁用
                }
            }
        }
        // 删除确认对话框
        .alert("删除记录", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条记录吗？此操作不可撤销。")
        }
        // 添加心情标签弹窗
        .sheet(isPresented: $showingAddMoodTag) {
            AddMoodTagView { newTag in
                selectedMood = newTag.name
                selectedMoodColor = newTag.color
            }
        }
        // 添加活动标签弹窗
        .sheet(isPresented: $showingAddActivityTag) {
            AddActivityTagView { newTag in
                selectedActivity = newTag.name
                selectedActivityIcon = newTag.icon
            }
        }
    }
    
    // 保存修改的方法
    private func saveChanges() {
        // 更新记录的属性
        record.startTime = startTime
        record.endTime = endTime
        record.note = note
        record.mood = selectedMood
        record.moodColor = selectedMoodColor
        record.activity = selectedActivity
        record.activityIcon = selectedActivityIcon
        
        // 关闭页面
        dismiss()
    }
    
    // 删除记录的方法
    private func deleteRecord() {
        // 从数据库删除记录
        modelContext.delete(record)
        // 关闭页面
        dismiss()
    }
}

// 添加心情标签视图（在EditRecordView中重复使用AddRecordView中的组件）
// 这里可以直接使用AddRecordView中定义的AddMoodTagView和AddActivityTagView
