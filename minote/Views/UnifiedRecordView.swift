import SwiftUI
import SwiftData
import HealthKit

/*
 统一记录视图 - 合并时间记录和心情记录功能
 
 主要功能：
 1. 记录时间段（开始时间和结束时间）
 2. 选择事件标签（活动类型）
 3. 添加备注
 4. 点击心情选择时调用原生 State of Mind 功能
 */
struct UnifiedRecordView: View {
    // MARK: - 环境和数据
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    // 查询自定义标签
    @Query private var customActivityTags: [CustomActivityTag]
    
    // MARK: - 状态变量
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var note = ""
    @State private var selectedActivity = "学习"
    @State private var selectedActivityIcon = "book.fill"
    @State private var selectedMood = "开心"
    @State private var selectedMoodColor = "yellow"
    
    // 弹窗控制
    @State private var showingAddActivityTag = false
    @State private var showingAlert = false
    @State private var showingInAppMoodRecording = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // 预定义活动选项
    private let activities = [
        ("工作", "briefcase.fill"),
        ("学习", "book.fill"),
        ("运动", "figure.run"),
        ("休息", "bed.double.fill"),
        ("娱乐", "gamecontroller.fill"),
        ("社交", "person.2.fill"),
        ("吃饭", "fork.knife"),
        ("通勤", "car.fill"),
        ("购物", "cart.fill"),
        ("阅读", "book.closed.fill")
    ]
    
    // MARK: - 主视图
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题区域
                    headerSection
                    
                    // 时间选择区域
                    timeSelectionSection
                    
                    // 事件标签选择区域
                    activitySelectionSection
                    
                    // 心情选择区域
                    moodSelectionSection
                    
                    // 备注区域
                    noteSection
                    
                    // 保存按钮
                    saveButton
                }
                .padding()
            }
            .navigationTitle("记录心情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingAddActivityTag) {
            UnifiedAddActivityTagView()
        }
        .sheet(isPresented: $showingInAppMoodRecording) {
            InAppMoodRecordingView()
        }
    }
    
    // MARK: - 子视图组件
    
    /// 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("记录你的心情时光")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("记录时间段和事件，点击心情按钮在应用内记录")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// 时间选择区域
    private var timeSelectionSection: some View {
        VStack(spacing: 16) {
            Text("时间段")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Text("开始时间")
                        .frame(width: 80, alignment: .leading)
                    DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                HStack {
                    Text("结束时间")
                        .frame(width: 80, alignment: .leading)
                    DatePicker("", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    /// 事件标签选择区域
    private var activitySelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("事件标签")
                    .font(.headline)
                
                Spacer()
                
                Button("添加") {
                    showingAddActivityTag = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // 预定义活动选项
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(allActivities, id: \.0) { activity in
                    UnifiedActivityButton(
                        title: activity.0,
                        icon: activity.1,
                        isSelected: selectedActivity == activity.0,
                        action: {
                            selectedActivity = activity.0
                            selectedActivityIcon = activity.1
                        }
                    )
                }
            }
        }
    }
    
    /// 心情选择区域
    private var moodSelectionSection: some View {
        VStack(spacing: 16) {
            Text("心情标签")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                Text("点击下方按钮在应用内记录心情")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    openInAppMoodRecording()
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                        Text("记录心情状态")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(!healthKitManager.isAuthorized)
                
                if !healthKitManager.isAuthorized {
                    Text("需要先授权 HealthKit 才能记录心情")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    /// 备注区域
    private var noteSection: some View {
        VStack(spacing: 16) {
            Text("备注")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $note)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    /// 保存按钮
    private var saveButton: some View {
        Button(action: saveRecord) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("保存记录")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(!isFormValid)
    }
    
    // MARK: - 计算属性
    
    /// 所有活动选项（预定义 + 自定义）
    private var allActivities: [(String, String)] {
        var result = activities
        for customTag in customActivityTags {
            result.append((customTag.name, customTag.icon))
        }
        return result
    }
    
    /// 表单验证
    private var isFormValid: Bool {
        !selectedActivity.isEmpty && startTime <= endTime
    }
    
    // MARK: - 方法
    
    /// 打开应用内心情记录
    private func openInAppMoodRecording() {
        if healthKitManager.openInAppMoodRecording() {
            showingInAppMoodRecording = true
        } else {
            alertTitle = "无法记录心情"
            alertMessage = "请确保已授权 HealthKit 访问权限"
            showingAlert = true
        }
    }
    
    /// 保存记录
    private func saveRecord() {
        // 验证时间
        guard startTime <= endTime else {
            alertTitle = "时间错误"
            alertMessage = "结束时间不能早于开始时间"
            showingAlert = true
            return
        }
        
        // 创建新记录（不包含心情，因为心情通过原生功能记录）
        let newRecord = MoodRecord(
            startTime: startTime,
            endTime: endTime,
            note: note,
            mood: "待记录", // 占位符，提醒用户使用原生功能
            moodColor: "gray",
            activity: selectedActivity,
            activityIcon: selectedActivityIcon
        )
        
        // 保存到数据库
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertTitle = "保存失败"
            alertMessage = "无法保存记录: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - 活动按钮组件

struct UnifiedActivityButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
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

// MARK: - 添加活动标签视图

struct UnifiedAddActivityTagView: View {
    @Environment(\.modelContext) private var modelContext
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
                TextField("标签名称", text: $tagName)
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
                        saveTag()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
    
    private func saveTag() {
        let newTag = CustomActivityTag(name: tagName, icon: selectedIcon)
        modelContext.insert(newTag)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("保存标签失败: \(error)")
        }
    }
}

// MARK: - 预览

#Preview {
    UnifiedRecordView()
        .environmentObject(HealthKitMoodManager())
}
