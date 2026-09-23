import SwiftUI

@main
struct SkyEarthHumanApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

struct RootView: View {
  var body: some View {
    NavigationStack {
      HomeView()
    }
  }
}
