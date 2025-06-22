// 添加记录界面 - 用户添加新的心情记录
import SwiftUI
import SwiftData

struct AddRecordView: View {
    // 数据库上下文
    @Environment(\.modelContext) private var modelContext
    // 关闭页面的方法
    @Environment(\.dismiss) private var dismiss
    // HealthKit管理器
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    // 查询自定义标签
    @Query private var customMoodTags: [CustomMoodTag]
    @Query private var customActivityTags: [CustomActivityTag]
    
    // 表单数据
    @State private var startTime = Date() // 开始时间
    @State private var endTime = Date() // 结束时间
    @State private var note = "" // 笔记
    @State private var selectedMood = "开心" // 选择的心情
    @State private var selectedMoodColor = "#FFD700" // 选择的心情颜色
    @State private var selectedActivity = "学习" // 选择的活动
    @State private var selectedActivityIcon = "book.fill" // 选择的活动图标
    
    // 弹窗状态
    @State private var showingAddMoodTag = false // 显示添加心情标签弹窗
    @State private var showingAddActivityTag = false // 显示添加活动标签弹窗
    
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
                    // State of Mind 原生界面按钮
                    if #available(iOS 16.0, *) {
                        Button(action: {
                            if let healthKitManager = healthKitManager as? HealthKitMoodManager {
                                healthKitManager.presentStateOfMindLogger()
                            }
                        }) {
                            HStack {
                                Image(systemName: "heart.text.square")
                                    .foregroundColor(.blue)
                                Text("使用系统心情记录")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderless)
                    }
                    
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
            }
            .navigationTitle("添加记录")
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
                        saveRecord()
                    }
                    .disabled(endTime <= startTime) // 时间无效时禁用
                }
            }
        }
        .onAppear {
            // 页面出现时设置默认结束时间（开始时间后1小时）
            endTime = startTime.addingTimeInterval(3600)
            // 初始化默认选择的颜色和图标
            selectedMoodColor = moods.first { $0.0 == selectedMood }?.1 ?? "#FFD700"
            selectedActivityIcon = activities.first { $0.0 == selectedActivity }?.1 ?? "book.fill"
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
    
    // 保存记录的方法
    private func saveRecord() {
        // 创建新记录
        let newRecord = MoodRecord(
            startTime: startTime,
            endTime: endTime,
            note: note,
            mood: selectedMood,
            moodColor: selectedMoodColor,
            activity: selectedActivity,
            activityIcon: selectedActivityIcon
        )
        
        // 保存到数据库
        modelContext.insert(newRecord)
        
        // 保存到HealthKit（异步操作）
        Task {
            if #available(iOS 16.0, *),
               let manager = healthKitManager as? HealthKitMoodManager {
                let success = await manager.saveMoodToHealthKit(
                    mood: selectedMood,
                    startTime: startTime,
                    endTime: endTime,
                    note: note
                )
                if success {
                    print("心情数据已同步到HealthKit")
                } else {
                    print("HealthKit同步失败")
                }
            }
        }
        
        // 关闭页面
        dismiss()
    }
}

// 心情选择按钮
struct MoodButton: View {
    let title: String // 按钮标题
    let color: String // 按钮颜色
    let isSelected: Bool // 是否被选中
    let action: () -> Void // 点击操作
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(isSelected ? .white : Color(hex: color))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(hex: color) : Color(hex: color).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: color), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 活动选择按钮
struct ActivityButton: View {
    let title: String // 按钮标题
    let icon: String // 按钮图标
    let isSelected: Bool // 是否被选中
    let action: () -> Void // 点击操作
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.body)
            }
            .foregroundColor(isSelected ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 添加心情标签视图
struct AddMoodTagView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColor = "#FFD700"
    
    let onTagAdded: (CustomMoodTag) -> Void
    
    // 预定义颜色选项
    private let availableColors = [
        "#FFD700", "#FF6347", "#87CEEB", "#DDA0DD", 
        "#98FB98", "#F0E68C", "#FFA07A", "#20B2AA",
        "#FF69B4", "#8A2BE2", "#00CED1", "#FF4500"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("标签名称") {
                    TextField("输入心情标签名称", text: $name)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                            Button(action: { 
                                print("选择颜色: \(color)")
                                selectedColor = color 
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 1 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("添加心情标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTag = CustomMoodTag(name: name, color: selectedColor)
                        modelContext.insert(newTag)
                        onTagAdded(newTag)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// 添加活动标签视图
struct AddActivityTagView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    
    let onTagAdded: (CustomActivityTag) -> Void
    
    // 预定义图标选项
    private let availableIcons = [
        "star.fill", "heart.fill", "music.note", "camera.fill",
        "gamecontroller.fill", "book.fill", "pencil", "paintbrush.fill",
        "car.fill", "airplane", "bicycle", "figure.walk",
        "house.fill", "building.2.fill", "cart.fill", "phone.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("标签名称") {
                    TextField("输入活动标签名称", text: $name)
                }
                
                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(Array(availableIcons.enumerated()), id: \.offset) { index, icon in
                            Button(action: { 
                                print("选择图标: \(icon)")
                                selectedIcon = icon 
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.3), lineWidth: selectedIcon == icon ? 2 : 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("添加活动标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newTag = CustomActivityTag(name: name, icon: selectedIcon)
                        modelContext.insert(newTag)
                        onTagAdded(newTag)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
