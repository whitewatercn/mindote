// 主要的Tab界面 - 包含主页和设置两个Tab
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: BaseHealthKitManager
    
    var body: some View {
        TabView {
            // 主页 - 心情记录列表
            SimpleContentView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("主页")
                }
                .tag(0)
            
            // 设置页面
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(1)
        }
        .accentColor(.blue) // Tab选中时的颜色
        .onAppear {
            // 应用启动时检查HealthKit权限
            if healthKitManager.isHealthKitAvailable && !healthKitManager.isAuthorized {
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
