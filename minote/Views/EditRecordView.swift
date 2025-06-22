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
    
    // 颜色辅助方法
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
    
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
        _startTime = State(initialValue: record.startTime ?? record.eventTime)
        _endTime = State(initialValue: record.endTime ?? record.eventTime)
        _note = State(initialValue: record.note)
        _selectedMood = State(initialValue: record.mood)
        _selectedMoodColor = State(initialValue: "") // 初始为空
        _selectedActivity = State(initialValue: record.activity ?? "其他")
        _selectedActivityIcon = State(initialValue: "") // 初始为空
    }
    
    var body: some View {
        NavigationStack {
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
            print("🔍 EditRecordView appeared")
            print("📝 Record to edit: mood=\(record.mood), activity=\(record.activity ?? "nil"), note=\(record.note)")
            // 当视图出现时，设置心情和活动的颜色/图标
            setupInitialState()
            checkHealthKitMoodStatus()
        }
        .onChange(of: customMoodTags) { oldValue, newValue in
            // 当自定义心情标签加载完成后，重新设置状态
            setupInitialState()
        }
        .onChange(of: customActivityTags) { oldValue, newValue in
            // 当自定义活动标签加载完成后，重新设置状态
            setupInitialState()
        }
        .onChange(of: showingMoodRecording) { oldValue, newValue in
            // 当心情记录界面关闭时，重新检查状态
            if oldValue && !newValue {
                checkHealthKitMoodStatus()
            }
        }
    }
    
    // 设置初始状态
    private func setupInitialState() {
        print("🔧 Setting up initial state...")
        print("📊 Available moods: \(moods.map { $0.0 })")
        print("📊 Custom mood tags count: \(customMoodTags.count)")
        print("📊 Available activities: \(activities.map { $0.0 })")
        print("📊 Custom activity tags count: \(customActivityTags.count)")
        
        // 查找并设置心情颜色
        if let mood = moods.first(where: { $0.0 == record.mood }) {
            selectedMoodColor = mood.1
            print("✅ Found mood color: \(mood.1) for mood: \(record.mood)")
        } else if let moodTag = customMoodTags.first(where: { $0.name == record.mood }) {
            selectedMoodColor = moodTag.color
            print("✅ Found custom mood color: \(moodTag.color) for mood: \(record.mood)")
        } else {
            selectedMoodColor = "blue" // 默认颜色
            print("⚠️ Using default color for mood: \(record.mood)")
        }
        
        // 查找并设置活动图标
        if let activity = activities.first(where: { $0.0 == record.activity }) {
            selectedActivityIcon = activity.1
            print("✅ Found activity icon: \(activity.1) for activity: \(record.activity ?? "nil")")
        } else if let activityTag = customActivityTags.first(where: { $0.name == record.activity }) {
            selectedActivityIcon = activityTag.icon
            print("✅ Found custom activity icon: \(activityTag.icon) for activity: \(record.activity ?? "nil")")
        } else {
            selectedActivityIcon = "star" // 默认图标
            print("⚠️ Using default icon for activity: \(record.activity ?? "nil")")
        }
        
        print("🎯 Final state: mood=\(selectedMood), color=\(selectedMoodColor), activity=\(selectedActivity), icon=\(selectedActivityIcon)")
    }

    // 保存修改的方法
    private func saveChanges() {
        // 更新记录的属性
        record.eventTime = startTime
        record.note = note
        record.mood = selectedMood
        record.activity = selectedActivity
        record.startTime = startTime
        record.endTime = endTime
        
        // 处理 HealthKit 同步：删除旧记录，创建新记录
        Task {
            // 如果原记录有 HealthKit UUID，先删除旧记录
            if let oldHealthKitUUID = record.healthKitUUID {
                let deleteSuccess = await healthKitManager.deleteMoodRecord(uuid: oldHealthKitUUID)
                if deleteSuccess {
                    print("✅ 已删除旧的 HealthKit 记录")
                } else {
                    print("⚠️ 删除旧 HealthKit 记录失败")
                }
            }
            
            // 创建新的 HealthKit 记录
            let newHealthKitUUID = await healthKitManager.saveMood(
                mood: selectedMood,
                startTime: startTime,
                endTime: endTime,
                note: note,
                tags: [selectedActivity]
            )
            
            await MainActor.run {
                if let uuid = newHealthKitUUID {
                    // 更新记录的 HealthKit UUID
                    record.healthKitUUID = uuid
                    print("✅ 已创建新的 HealthKit 记录，UUID: \(uuid)")
                } else {
                    // 清除 HealthKit UUID 因为同步失败
                    record.healthKitUUID = nil
                    print("⚠️ HealthKit 同步失败，但本地记录已更新")
                }
                
                // 关闭页面
                dismiss()
            }
        }
    }
    
    // 删除记录的方法
    private func deleteRecord() {
        Task {
            // 如果记录有HealthKit UUID，先从HealthKit删除
            if let healthKitUUID = record.healthKitUUID {
                let deleted = await healthKitManager.deleteMoodRecord(uuid: healthKitUUID)
                if deleted {
                    print("✅ 已从HealthKit删除记录: \(healthKitUUID)")
                } else {
                    print("⚠️ 从HealthKit删除记录失败: \(healthKitUUID)")
                }
            }
            
            // 从本地数据库删除记录
            await MainActor.run {
                modelContext.delete(record)
                dismiss()
            }
        }
    }
    
    // 检查HealthKit中是否有对应时间段的心情记录
    private func checkHealthKitMoodStatus() {
        isCheckingHealthKit = true
        
        Task {
            // 如果记录已经有 healthKitUUID，说明已经同步过了
            if record.healthKitUUID != nil {
                await MainActor.run {
                    healthKitMoodExists = true
                    isCheckingHealthKit = false
                }
                return
            }
            
            // 检查时间段内是否有心情记录
            let startTimeToCheck = record.startTime ?? record.eventTime
            let endTimeToCheck = record.endTime ?? record.eventTime
            
            let exists = await healthKitManager.checkMoodExistsInTimeRange(
                startTime: startTimeToCheck,
                endTime: endTimeToCheck
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
        
        private func colorFromString(_ colorString: String) -> Color {
            switch colorString.lowercased() {
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "yellow": return .yellow
            case "orange": return .orange
            case "purple": return .purple
            case "pink": return .pink
            case "gray": return .gray
            default: return .blue
            }
        }
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isSelected ? colorFromString(color) : Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(colorFromString(color), lineWidth: 1)
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
        
        private func colorFromString(_ colorString: String) -> Color {
            switch colorString.lowercased() {
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "yellow": return .yellow
            case "orange": return .orange
            case "purple": return .purple
            case "pink": return .pink
            case "gray": return .gray
            default: return .blue
            }
        }
        
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
                                    .fill(colorFromString(color))
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

