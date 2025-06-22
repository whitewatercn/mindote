# MinNote - 简单的心情追踪应用

一个专为Swift学习者设计的简单iOS心情追踪应用，集成了HealthKit的State of Mind功能。

## 🎯 项目目标

这个项目专为Swift编程新手设计，帮助你学习：
- Swift语言基础
- SwiftUI界面开发
- SwiftData数据存储
- HealthKit系统集成
- iOS应用架构

## ✨ 功能特性

### 当前功能
- 📝 **心情记录** - 记录不同时间段的心情状态
- 💚 **HealthKit集成** - 调用系统原生的心情记录界面
- 📱 **简洁界面** - 直观易用的用户界面
- 💾 **本地存储** - 使用SwiftData进行数据持久化

### 计划功能
- 📊 心情数据分析和图表
- 🔄 完整的HealthKit双向同步
- 🏷️ 自定义标签和分类
- 📈 心情趋势分析

## 🚀 快速开始

### 系统要求
- iOS 16.0+ (推荐iOS 17.0+以获得完整HealthKit支持)
- Xcode 15.0+
- Swift 5.9+

### 运行步骤
1. 使用Xcode打开项目
2. 选择目标设备（真机设备以测试HealthKit功能）
3. 点击运行按钮（⌘+R）

### HealthKit配置
应用会自动请求HealthKit权限，在iOS 17+设备上可以：
1. 点击"记录心情"按钮
2. 系统会打开健康应用
3. 在健康应用中记录你的心情状态

## 📁 项目结构

```
minote/
├── SimpleMoodApp.swift          # 应用入口
├── Models/
│   └── SimpleModels.swift       # 数据模型
├── Views/
│   ├── MainTabView.swift        # 主标签页
│   ├── SimpleContentView.swift  # 主界面
│   ├── AddRecordView.swift      # 添加记录页面
│   ├── EditRecordView.swift     # 编辑记录页面
│   └── SettingsView.swift       # 设置页面
├── Managers/
│   └── HealthKitMoodManager.swift # HealthKit管理器
└── Documentation/
    └── Swift学习指南_简化版.md    # 详细学习指南
```

## 🧠 学习重点

### 初学者关注点
1. **SwiftUI基础**
   - 视图组合和布局
   - 状态管理(@State, @StateObject)
   - 数据绑定

2. **Swift语言特性**
   - 可选类型(Optionals)
   - 异步编程(async/await)
   - 属性包装器(Property Wrappers)

3. **iOS开发概念**
   - 应用生命周期
   - 导航和界面设计
   - 数据持久化

### 代码注释说明
所有代码都包含详细的中文注释，解释：
- 每个类和方法的作用
- 重要概念的解释
- Swift语法特性的说明
- iOS开发最佳实践

## 🛠️ 开发技巧

### 调试建议
1. 使用Xcode控制台查看打印信息
2. 设置断点来观察数据流
3. 使用预览功能快速调试界面

### 学习建议
1. 先阅读`Documentation/Swift学习指南_简化版.md`
2. 从简单的UI修改开始
3. 逐步理解数据流和状态管理
4. 尝试添加新功能来练习

## 📚 相关资源

### 官方文档
- [Swift官方文档](https://docs.swift.org/swift-book/)
- [SwiftUI教程](https://developer.apple.com/tutorials/swiftui)
- [HealthKit开发指南](https://developer.apple.com/documentation/healthkit)

### 学习建议
1. 每次只关注一个概念
2. 多实践，少理论
3. 善用Xcode的预览功能
4. 加入iOS开发社区

## ⚠️ 注意事项

1. **HealthKit权限**: 需要在真机上测试HealthKit功能
2. **iOS版本**: State of Mind功能需要iOS 17.0+
3. **设备支持**: HealthKit不支持iPad

## 🎯 下一步学习

完成基础功能后，可以尝试：
1. 添加数据可视化（图表）
2. 实现数据导出功能
3. 添加推送通知提醒
4. 集成更多HealthKit数据类型
5. 实现云同步功能

## 🤝 贡献

这是一个学习项目，欢迎提出改进建议！

## 📄 许可证

此项目仅用于学习目的。
