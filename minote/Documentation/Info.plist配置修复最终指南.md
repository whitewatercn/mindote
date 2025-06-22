# Info.plist配置修复最终指南

## 问题现状
Info.plist文件格式问题已修复，但仍存在"Multiple commands produce"错误，这是因为Info.plist被错误地添加到了Copy Bundle Resources构建阶段。

## 立即需要在Xcode中执行的操作

### 1. 删除Copy Bundle Resources中的Info.plist
1. 在Xcode中打开项目
2. 选择项目根目录中的"minote"项目
3. 选择"minote" target
4. 点击"Build Phases"选项卡
5. 展开"Copy Bundle Resources"部分
6. 找到"Info.plist"项目
7. 选中它并按Delete键删除
8. **重要**: 确保Info.plist仍然在Project Navigator中可见，我们只是从Copy Bundle Resources中移除它

### 2. 验证Info.plist配置
1. 在Project Navigator中选择Info.plist文件
2. 确保在右侧面板的"Target Membership"中，minote target是**未选中**的
3. Info.plist应该作为项目配置文件存在，而不是作为资源文件

### 3. 检查项目设置
1. 选择项目根目录中的"minote"项目
2. 选择"minote" target
3. 在"Info"选项卡中确认"Info.plist File"设置指向正确的路径: `minote/Info.plist`

## 文件状态确认
- ✅ Info.plist文件格式正确（通过plutil验证）
- ✅ 包含所有必需的HealthKit权限说明
- ✅ 包含CSV文件导入/导出配置
- ❌ 需要从Copy Bundle Resources中移除以解决构建冲突

## 预期结果
执行上述操作后，项目应该能够成功构建，并且：
1. 不再出现"Multiple commands produce"错误
2. Info.plist被正确处理为项目配置文件
3. 应用能正常运行并访问HealthKit功能

## 验证步骤
完成修复后，请在Xcode中：
1. Clean Build Folder (⌘+⇧+K)
2. Build项目 (⌘+B)
3. 确认构建成功
4. 在模拟器或真机上运行应用

## 如果问题持续
如果仍有问题，请检查：
1. 确保没有其他文件冲突
2. 检查.xcodeproj文件是否损坏
3. 重启Xcode
4. 必要时重新创建Xcode项目

最后更新：2025-06-22 10:18
