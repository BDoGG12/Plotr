import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var allPosts: [Post]
    @State private var showTrialExpiry: Bool = false
    @State private var showPaywall: Bool = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: subscriptionManager.hasJustExpired) { _, hasJustExpired in
            if hasJustExpired {
                showTrialExpiry = true
            }
        }
        .sheet(isPresented: $showTrialExpiry) {
            TrialExpirySheet(
                postCount: allPosts.count,
                onSubscribe: {
                    showTrialExpiry = false
                    showPaywall = true
                },
                onRemindLater: {
                    subscriptionManager.markExpiredSeen()
                    showTrialExpiry = false
                }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                dismiss: { showPaywall = false },
                postCount: allPosts.count
            )
            .presentationDetents([.large])
            .interactiveDismissDisabled(false)
        }
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
        .environment(SubscriptionManager())
}
