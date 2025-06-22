// 设置页面 - 用户可以管理应用设置和数据
import SwiftUI
import HealthKit
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    @Query private var records: [MoodRecord]
    @Query private var customMoodTags: [CustomMoodTag]
    @Query private var customActivityTags: [CustomActivityTag]
    
    // 控制是否显示文件选择器（导出）
    @State private var showingExportPicker = false
    // 控制是否显示文件选择器（导入）
    @State private var showingImportPicker = false
    // 控制是否显示操作结果提示
    @State private var showingAlert = false
    // 提示消息
    @State private var alertMessage = ""
    // 提示标题
    @State private var alertTitle = ""
    // HealthKit同步状态
    @State private var isSyncing = false
    // 导入预览相关
    @State private var showingImportPreview = false
    @State private var previewImportResult: (imported: [MoodRecord], skipped: Int)? = nil
    
    var body: some View {
        NavigationView {
            List {
                // 数据统计部分
                Section("数据统计") {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("总记录数")
                                .font(.headline)
                            Text("\(records.count) 条记录")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    if !records.isEmpty {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("总时长")
                                    .font(.headline)
                                Text(totalDurationString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 数据管理部分
                Section("数据管理") {
                    // 导出数据按钮
                    Button(action: {
                        showingExportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("导出数据")
                                    .foregroundColor(.primary)
                                Text("将记录导出为CSV文件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(records.isEmpty) // 没有数据时禁用
                    
                    // 导入数据按钮
                    Button(action: {
                        showingImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("导入数据")
                                    .foregroundColor(.primary)
                                Text("从CSV文件导入记录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 导入提示
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导入提示：")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("• 支持CSV和TXT格式文件")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 如遇权限问题，请将文件保存到\"文件\"应用中")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 确保文件格式正确且包含有效数据")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                // HealthKit集成部分
                Section("HealthKit同步") {
                    // HealthKit状态显示
                    HStack {
                        Image(systemName: healthKitManager.isHealthKitAvailable ? "heart.circle.fill" : "heart.circle")
                            .foregroundColor(healthKitManager.isHealthKitAvailable ? .red : .gray)
                        VStack(alignment: .leading) {
                            Text("HealthKit状态")
                                .font(.headline)
                            Text(healthKitManager.isHealthKitAvailable ? 
                                 (healthKitManager.isAuthorized ? "已授权" : "可用但未授权") : "不可用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // 请求HealthKit权限按钮
                    if healthKitManager.isHealthKitAvailable && !healthKitManager.isAuthorized {
                        Button(action: {
                            Task {
                                await healthKitManager.requestAuthorization()
                            }
                        }) {
                            HStack {
                                Image(systemName: "lock.open")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("请求HealthKit权限")
                                        .foregroundColor(.primary)
                                    Text("允许应用访问健康数据")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 同步到HealthKit按钮
                    if healthKitManager.isAuthorized {
                        Button(action: {
                            syncToHealthKit()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("同步到HealthKit")
                                        .foregroundColor(.primary)
                                    Text("将本地记录上传到健康app")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(isSyncing || records.isEmpty)
                        
                        // 从HealthKit导入按钮
                        Button(action: {
                            importFromHealthKit()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("从HealthKit导入")
                                        .foregroundColor(.primary)
                                    Text("导入健康app中的心情记录")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(isSyncing)
                    }
                    
                    // HealthKit提示
                    VStack(alignment: .leading, spacing: 4) {
                        Text("同步说明：")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("• 需要iOS 17.0或更高版本")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 同步后可在健康app中查看心情数据")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 数据将与其他健康数据统一管理")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                // 自定义标签管理部分
                Section("自定义标签管理") {
                    // 心情标签统计
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading) {
                            Text("心情标签")
                                .font(.headline)
                            Text("\(customMoodTags.count) 个自定义标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // 活动标签统计
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("活动标签")
                                .font(.headline)
                            Text("\(customActivityTags.count) 个自定义标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    // 清理未使用标签按钮
                    Button(action: {
                        cleanupUnusedTags()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("清理未使用标签")
                                    .foregroundColor(.primary)
                                Text("删除没有被记录使用的标签")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 应用信息部分
                Section("应用信息") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("版本")
                                .font(.headline)
                            Text("简化版 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("简单心情记录")
                                .font(.headline)
                            Text("为初学者设计的Swift应用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("设置")
        }
        // 导出文件选择器
        .fileExporter(
            isPresented: $showingExportPicker,
            document: CSVDocument(content: CSVHelper.exportToCSV(records: records)),
            contentType: .commaSeparatedText,
            defaultFilename: "心情记录_\(getCurrentDateString())"
        ) { result in
            handleExportResult(result)
        }
        // 导入文件选择器
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        // 结果提示对话框
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        // 导入预览对话框
        .sheet(isPresented: $showingImportPreview) {
            ImportPreviewView(
                importResult: previewImportResult ?? (imported: [], skipped: 0),
                onConfirm: {
                    performActualImport()
                },
                onCancel: {
                    previewImportResult = nil
                }
            )
        }
    }
    
    /// 执行实际导入
    private func performActualImport() {
        guard let importResult = previewImportResult else { return }
        
        do {
            // 将导入的记录添加到数据库
            for record in importResult.imported {
                modelContext.insert(record)
            }
            
            // 尝试保存到数据库
            try modelContext.save()
            
            // 构建导入结果消息
            var resultMessage = "✅ 成功导入 \(importResult.imported.count) 条新记录"
            if importResult.skipped > 0 {
                resultMessage += "\n\n⚠️ 智能跳过 \(importResult.skipped) 条重复记录"
                resultMessage += "\n\n重复检测帮助避免数据冗余，保持记录整洁。"
            }
            
            alertTitle = "导入成功"
            alertMessage = resultMessage
            showingAlert = true
            
            // 清理预览数据
            previewImportResult = nil
            
        } catch {
            alertTitle = "导入失败"
            alertMessage = "保存到数据库时出错: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // 计算总时长的字符串
    private var totalDurationString: String {
        let totalSeconds = records.reduce(0) { sum, record in
            sum + record.endTime.timeIntervalSince(record.startTime)
        }
        
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // 获取当前日期字符串（用于文件命名）
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 处理导出结果
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            alertTitle = "导出成功"
            alertMessage = "数据已成功导出到：\(url.lastPathComponent)"
            showingAlert = true
        case .failure(let error):
            alertTitle = "导出失败"
            alertMessage = "导出过程中出现错误：\(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // 处理导入结果
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { 
                alertTitle = "导入失败"
                alertMessage = "未选择文件"
                showingAlert = true
                return 
            }
            
            // 检查文件扩展名
            let fileExtension = url.pathExtension.lowercased()
            if !["csv", "txt"].contains(fileExtension) {
                alertTitle = "导入失败"
                alertMessage = "不支持的文件格式。请选择CSV或TXT文件。"
                showingAlert = true
                return
            }
            
            do {
                // 开始安全访问资源
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    // 结束安全访问资源
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if !hasAccess {
                    alertTitle = "导入失败"
                    alertMessage = "无法访问选择的文件。请确保文件没有被其他应用占用，并重新选择文件。"
                    showingAlert = true
                    return
                }
                
                // 检查文件是否存在和可读
                guard FileManager.default.fileExists(atPath: url.path) else {
                    alertTitle = "导入失败"
                    alertMessage = "文件不存在或已被删除。"
                    showingAlert = true
                    return
                }
                
                // 读取文件内容
                let csvContent = try String(contentsOf: url, encoding: .utf8)
                
                // 检查文件是否为空
                if csvContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    alertTitle = "导入失败"
                    alertMessage = "文件为空，没有可导入的内容。"
                    showingAlert = true
                    return
                }
                
                // 解析CSV数据，带重复检测
                print("🔍 开始导入验证，现有记录数量: \(records.count)")
                
                let importResult = CSVHelper.importFromCSVWithDuplicateCheck(
                    csvContent: csvContent,
                    existingRecords: records
                )
                
                let importedRecords = importResult.imported
                let skippedCount = importResult.skipped
                
                print("📊 导入结果: 新增 \(importedRecords.count) 条，跳过 \(skippedCount) 条重复")
                
                if importedRecords.isEmpty && skippedCount == 0 {
                    alertTitle = "导入完成"
                    alertMessage = "文件已处理，但没有找到有效的记录数据。请检查文件格式是否正确。"
                    showingAlert = true
                    return
                }
                
                if importedRecords.isEmpty && skippedCount > 0 {
                    alertTitle = "导入完成"
                    alertMessage = "文件中的 \(skippedCount) 条记录与现有数据重复，已智能跳过导入。\n\n重复检测标准:\n• 相同时间段（±1分钟）\n• 相同心情和活动\n• 相似备注内容"
                    showingAlert = true
                    return
                }
                
                // 显示导入预览
                previewImportResult = importResult
                showingImportPreview = true
                
            } catch let error as NSError {
                alertTitle = "导入失败"
                if error.domain == NSCocoaErrorDomain {
                    switch error.code {
                    case NSFileReadNoPermissionError:
                        alertMessage = "没有权限访问该文件。请确保文件不在受保护的位置，或尝试将文件复制到其他位置后重新导入。"
                    case NSFileReadNoSuchFileError:
                        alertMessage = "文件不存在或路径无效。"
                    case NSFileReadCorruptFileError:
                        alertMessage = "文件已损坏或格式错误。"
                    default:
                        alertMessage = "读取文件时出现错误：\(error.localizedDescription)"
                    }
                } else {
                    alertMessage = "读取文件时出现错误：\(error.localizedDescription)"
                }
                showingAlert = true
            }
            
        case .failure(let error):
            alertTitle = "导入失败"
            alertMessage = "选择文件时出现错误：\(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // 清理未使用的标签
    private func cleanupUnusedTags() {
        let usedMoods = Set(records.map { $0.mood })
        let usedActivities = Set(records.map { $0.activity })
        
        var deletedCount = 0
        
        // 删除未使用的心情标签（非默认标签）
        for tag in customMoodTags {
            if !tag.isDefault && !usedMoods.contains(tag.name) {
                modelContext.delete(tag)
                deletedCount += 1
            }
        }
        
        // 删除未使用的活动标签（非默认标签）
        for tag in customActivityTags {
            if !tag.isDefault && !usedActivities.contains(tag.name) {
                modelContext.delete(tag)
                deletedCount += 1
            }
        }
        
        alertTitle = "清理完成"
        alertMessage = "已删除 \(deletedCount) 个未使用的标签"
        showingAlert = true
    }
    
    // 同步到HealthKit
    private func syncToHealthKit() {
        isSyncing = true
        
        Task {
            let result = await healthKitManager.syncLocalRecordsToHealthKit(records: records)
            
            await MainActor.run {
                isSyncing = false
                alertTitle = "同步完成"
                alertMessage = "成功同步 \(result.success) 条记录到HealthKit"
                if result.failed > 0 {
                    alertMessage += "，\(result.failed) 条记录同步失败"
                }
                showingAlert = true
            }
        }
    }
    
    // 从HealthKit导入
    private func importFromHealthKit() {
        isSyncing = true
        
        Task {
            let importedRecords = await healthKitManager.importHealthKitRecordsToLocal()
            
            await MainActor.run {
                for record in importedRecords {
                    modelContext.insert(record)
                }
                
                isSyncing = false
                alertTitle = "导入完成"
                alertMessage = "成功从HealthKit导入 \(importedRecords.count) 条记录"
                showingAlert = true
            }
        }
    }
}


// CSV文档类型 - 用于文件导出
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

// MARK: - 导入预览视图

struct ImportPreviewView: View {
    let importResult: (imported: [MoodRecord], skipped: Int)
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 统计信息
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("新增记录")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(importResult.imported.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("跳过重复")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(importResult.skipped)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // 记录列表预览
                if !importResult.imported.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("即将导入的记录")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        List {
                            ForEach(Array(importResult.imported.prefix(10).enumerated()), id: \.offset) { index, record in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Circle()
                                            .fill(Color(record.moodColor))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(record.mood)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text(record.activity)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(record.timeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !record.note.isEmpty {
                                        Text(record.note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            
                            if importResult.imported.count > 10 {
                                Text("... 还有 \(importResult.imported.count - 10) 条记录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                if importResult.skipped > 0 {
                    Text("重复检测标准: 相同时间段（±1分钟）、相同心情和活动、相似备注内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确认导入") {
                        onConfirm()
                    }
                    .fontWeight(.semibold)
                    .disabled(importResult.imported.isEmpty)
                }
            }
        }
    }
}
