import SwiftUI
import HealthKit

/*
 应用的主标签页界面
 
 这个视图包含应用的主要导航结构：
 1. 主页标签 - 显示心情记录列表
 2. 设置标签 - 应用设置和HealthKit配置
 
 使用TabView创建底部标签栏导航
 */
struct MainTabView: View {
    /*
     @EnvironmentObject 用于接收从父视图传递下来的共享对象
     这里接收HealthKit管理器，所有子视图都可以访问它
     */
    @EnvironmentObject var healthKitManager: HealthKitMoodManager
    
    var body: some View {
        TabView {
            // 第一个标签：主页
            SimpleContentView()
                .tabItem {
                    // 设置标签页的图标和文字
                    Image(systemName: "house.fill")  // 使用SF Symbol图标
                    Text("主页")
                }
                .tag(0)  // 给标签页一个唯一标识
            
            // 第二个标签：设置页面
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(1)
        }
        .accentColor(.blue)  // 设置选中标签的颜色
        .onAppear {
            /*
             当视图出现时执行的代码
             检查HealthKit是否可用，如果可用但未授权，则请求权限
             */
            if healthKitManager.isHealthKitAvailable && !healthKitManager.isAuthorized {
                // 异步请求HealthKit权限
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }
        }
    }
}

// 预览功能 - 用于Xcode中预览界面效果
#Preview {
    MainTabView()
        .environmentObject(HealthKitMoodManager())  // 预览时提供一个模拟的管理器
}
