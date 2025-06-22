import SwiftUI
import SwiftData

struct RecordEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var record: MoodRecord?

    @State private var eventTime: Date
    @State private var mood: String
    @State private var activity: String
    @State private var note: String
    
    private let moodOptions = LocalMoodManager.moodOptions
    private let activityOptions = LocalMoodManager.activityOptions

    init(record: MoodRecord? = nil) {
        self.record = record
        _eventTime = State(initialValue: record?.eventTime ?? Date())
        _mood = State(initialValue: record?.mood ?? moodOptions.first!)
        _activity = State(initialValue: record?.activity ?? activityOptions.first!)
        _note = State(initialValue: record?.note ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("时间")) {
                    DatePicker("记录时间", selection: $eventTime)
                }
                
                Section(header: Text("标签")) {
                    Picker("心情", selection: $mood) {
                        ForEach(moodOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("事件", selection: $activity) {
                        ForEach(activityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section(header: Text("笔记")) {
                    TextEditor(text: $note)
                        .frame(height: 150)
                }
            }
            .navigationTitle(record == nil ? "添加记录" : "编辑记录")
            .navigationBarItems(leading: Button("取消") {
                dismiss()
            }, trailing: Button("保存") {
                saveRecord()
                dismiss()
            })
        }
    }

    private func saveRecord() {
        if let record = record {
            record.eventTime = eventTime
            record.mood = mood
            record.activity = activity
            record.note = note
        } else {
            let newRecord = MoodRecord(eventTime: eventTime, note: note, mood: mood, activity: activity)
            modelContext.insert(newRecord)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save record: \(error.localizedDescription)")
        }
    }
}
