import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = UIColor(Theme.border)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            BoardView()
                .tabItem { Label("Board", systemImage: "rectangle.split.3x1") }

            IdeaVaultView()
                .tabItem { Label("Ideas", systemImage: "lightbulb") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Post.self, ChecklistItem.self], inMemory: true)
}
