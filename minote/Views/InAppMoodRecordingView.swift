import SwiftUI
import HealthKit

/*
 应用内心情记录视图 - 参考 Dairy 应用的两步式心情记录
 
 主要功能：
 1. 第一步：拖拽滑块选择心情程度（Pleasant/Unpleasant）
 2. 第二步：选择具体的情绪标签
 3. 可选的反思文本输入
 4. 直接保存到 HealthKit 的 State of Mind
 */
struct InAppMoodRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    @State private var currentStep = 1 // 1: 选择心情程度, 2: 选择情绪标签, 3: 显示成功状态
    @State private var valence: Double = 0.0 // -1.0 (Unpleasant) 到 1.0 (Pleasant)
    @State private var selectedEmotion: String = ""
    @State private var selectedEmotionColor: Color = .gray
    @State private var reflection: String = ""
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var savedMoodDescription = "" // 保存成功的心情描述
    
    // 情绪标签数据 - 根据 valence 值动态显示不同的情绪选项
    private var emotionOptions: [String] {
        if valence > 0.5 {
            // 非常愉快的情绪
            return ["Amazed", "Excited", "Surprised", "Passionate", "Happy", "Joyful", "Brave", "Proud", "Confident"]
        } else if valence > 0.0 {
            // 比较愉快的情绪
            return ["Hopeful", "Amused", "Satisfied", "Relieved", "Grateful", "Content", "Calm", "Peaceful"]
        } else if valence > -0.5 {
            // 比较不愉快的情绪
            return ["Content", "Calm", "Peaceful", "Indifferent", "Drained", "Tired", "Bored"]
        } else {
            // 非常不愉快的情绪
            return ["Sad", "Angry", "Anxious", "Frustrated", "Overwhelmed", "Lonely", "Stressed", "Disappointed"]
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if currentStep == 1 {
                    step1_MoodSelection
                } else if currentStep == 2 {
                    step2_EmotionSelection
                } else {
                    step3_SuccessStatus
                }
            }
            .navigationTitle("记录心情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == 3 {
                        // 成功状态不显示取消按钮
                        EmptyView()
                    } else {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
                
                if currentStep == 2 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            saveMood()
                        }) {
                            if isSaving {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("保存中")
                                        .font(.body)
                                }
                            } else {
                                Text("完成")
                            }
                        }
                        .disabled(selectedEmotion.isEmpty || isSaving)
                    }
                } else if currentStep == 3 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 第一步：心情程度选择
    
    private var step1_MoodSelection: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 标题区域
            VStack(spacing: 12) {
                Text("How do I feel?")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 心情显示
            VStack(spacing: 20) {
                // 心情图标和文字
                HStack(spacing: 12) {
                    Image(systemName: moodIcon)
                        .font(.system(size: 40))
                        .foregroundColor(moodColor)
                    
                    Text(moodDescription)
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(moodColor)
                }
                
                // 心情滑块
                VStack(spacing: 20) {
                    Slider(value: $valence, in: -1.0...1.0, step: 0.1)
                        .accentColor(moodColor)
                        .frame(height: 44)
                    
                    // 滑块标签
                    HStack {
                        Text("Unpleasant")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Pleasant")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // 继续按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 2
                }
            }) {
                Text("继续")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(moodColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - 第二步：情绪标签选择
    
    private var step2_EmotionSelection: some View {
        VStack(spacing: 30) {
            // 顶部心情显示
            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    Image(systemName: moodIcon)
                        .font(.system(size: 30))
                        .foregroundColor(moodColor)
                    
                    Text(moodDescription)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(moodColor)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 1
                    }
                }) {
                    Text("调整心情程度")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top)
            
            // 问题标题
            Text("What best describes this feeling?")
                .font(.title3)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            // 情绪标签网格
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(emotionOptions, id: \.self) { emotion in
                        EmotionButton(
                            title: emotion,
                            isSelected: selectedEmotion == emotion,
                            action: {
                                selectedEmotion = emotion
                                selectedEmotionColor = moodColor
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 反思输入（可选）
            if !selectedEmotion.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("反思 (可选)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $reflection)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - 计算属性
    
    /// 根据 valence 值返回心情描述
    private var moodDescription: String {
        switch valence {
        case 0.6...1.0:
            return "Pleasant"
        case 0.2..<0.6:
            return "Slightly Pleasant"
        case -0.2..<0.2:
            return "Neutral"
        case -0.6..<(-0.2):
            return "Slightly Unpleasant"
        case -1.0..<(-0.6):
            return "Unpleasant"
        default:
            return "Neutral"
        }
    }
    
    /// 根据 valence 值返回对应的颜色
    private var moodColor: Color {
        switch valence {
        case 0.6...1.0:
            return Color(red: 0.2, green: 0.8, blue: 0.2) // 绿色
        case 0.2..<0.6:
            return Color(red: 0.4, green: 0.7, blue: 0.9) // 蓝色
        case -0.2..<0.2:
            return Color(red: 0.4, green: 0.8, blue: 0.9) // 青色
        case -0.6..<(-0.2):
            return Color(red: 1.0, green: 0.6, blue: 0.2) // 橙色
        case -1.0..<(-0.6):
            return Color(red: 0.9, green: 0.3, blue: 0.3) // 红色
        default:
            return .gray
        }
    }
    
    /// 根据 valence 值返回对应的图标
    private var moodIcon: String {
        switch valence {
        case 0.6...1.0:
            return "face.smiling"
        case 0.2..<0.6:
            return "face.smiling"
        case -0.2..<0.2:
            return "minus.circle"
        case -0.6..<(-0.2):
            return "face.dashed"
        case -1.0..<(-0.6):
            return "face.dashed"
        default:
            return "minus.circle"
        }
    }
    
    // MARK: - 方法
    
    /// 保存心情到 HealthKit
    private func saveMood() {
        isSaving = true
        
        Task {
            // 构建完整的心情描述，包含程度和具体情绪
            let fullMoodDescription = "\(moodDescription) - \(selectedEmotion)"
            
            let success = await healthKitManager.saveInAppMood(
                valence: valence,
                reflection: reflection.isEmpty ? fullMoodDescription : "\(fullMoodDescription)\n\n\(reflection)"
            )
            
            await MainActor.run {
                isSaving = false
                
                if success {
                    // 心情保存成功，显示成功状态
                    savedMoodDescription = "\(moodDescription) - \(selectedEmotion)"
                    currentStep = 3
                } else {
                    alertMessage = "保存失败，请检查 HealthKit 权限设置。"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - 第三步：成功状态显示
    
    private var step3_SuccessStatus: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 成功图标
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("心情已记录")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // 记录的心情信息
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("已同步到 HealthKit")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Text(savedMoodDescription)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if !reflection.isEmpty {
                    Text("\"\(reflection)\"")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 情绪按钮组件

struct EmotionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.primary : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览

#Preview {
    InAppMoodRecordingView()
        .environmentObject(HealthKitMoodManager())
}
