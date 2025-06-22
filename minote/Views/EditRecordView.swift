// 编辑记录界面 - 用户编辑已有的心情记录
import SwiftUI
import SwiftData

struct EditRecordView: View {
    // 数据库上下文
    @Environment(\.modelContext) private var modelContext
    // 关闭页面的方法
    @Environment(\.dismiss) private var dismiss
    // HealthKit管理器
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
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
    
    // HealthKit状态检查
    @State private var healthKitMoodExists = false
    @State private var isCheckingHealthKit = true
    
    // 控制删除确认对话框和添加标签弹窗
    @State private var showingDeleteAlert = false
    @State private var showingAddMoodTag = false
    @State private var showingAddActivityTag = false
    @State private var showingMoodRecording = false
    
    // 预定义的心情选项 - 使用系统颜色名称
    private let moods = [
        ("开心", "yellow"),
        ("平静", "blue"),
        ("难过", "gray"),
        ("生气", "red"),
        ("焦虑", "purple"),
        ("兴奋", "pink")
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
                // HealthKit 心情记录状态
                Section {
                    if isCheckingHealthKit {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("检查 HealthKit 心情记录...")
                                .foregroundColor(.secondary)
                        }
                    } else if healthKitMoodExists {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("HealthKit 心情已记录")
                                    .font(.body)
                                Text("时间段内已有心情数据")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("HealthKit 心情未记录")
                                        .font(.body)
                                    Text("建议记录心情到 HealthKit 以保持数据同步")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                showingMoodRecording = true
                            }) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("记录心情到 HealthKit")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                } header: {
                    Text("HealthKit 同步状态")
                }
                
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
        // 心情记录弹窗
        .sheet(isPresented: $showingMoodRecording) {
            InAppMoodRecordingView()
                .environmentObject(healthKitManager)
        }
        .onAppear {
            checkHealthKitMoodStatus()
        }
        .onChange(of: showingMoodRecording) { oldValue, newValue in
            // 当心情记录界面关闭时，重新检查状态
            if oldValue && !newValue {
                checkHealthKitMoodStatus()
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
    
    // 检查HealthKit中是否有对应时间段的心情记录
    private func checkHealthKitMoodStatus() {
        isCheckingHealthKit = true
        
        Task {
            let exists = await healthKitManager.checkMoodExistsInTimeRange(
                startTime: record.startTime,
                endTime: record.endTime
            )
            
            await MainActor.run {
                healthKitMoodExists = exists
                isCheckingHealthKit = false
            }
        }
    }
}

// MARK: - 组件定义

/// 心情按钮组件
struct MoodButton: View {
    let title: String
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color(color) : Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(color), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 活动按钮组件
struct ActivityButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.body)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 添加心情标签视图
struct AddMoodTagView: View {
    let onSave: (CustomMoodTag) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tagName = ""
    @State private var selectedColor = "blue"
    
    private let colorOptions = ["red", "blue", "green", "yellow", "orange", "purple", "pink", "gray"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("心情名称", text: $tagName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("选择颜色")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(colorOptions, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(Color(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加心情标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTag = CustomMoodTag(name: tagName, color: selectedColor)
                        onSave(newTag)
                        dismiss()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
}

/// 添加活动标签视图
struct AddActivityTagView: View {
    let onSave: (CustomActivityTag) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tagName = ""
    @State private var selectedIcon = "star.fill"
    
    private let iconOptions = [
        "star.fill", "heart.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "flame.fill", "drop.fill", "leaf.fill",
        "music.note", "camera.fill", "paintbrush.fill", "hammer.fill"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("活动名称", text: $tagName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("选择图标")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : .blue)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.blue : Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加活动标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTag = CustomActivityTag(name: tagName, icon: selectedIcon)
                        onSave(newTag)
                        dismiss()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
}
