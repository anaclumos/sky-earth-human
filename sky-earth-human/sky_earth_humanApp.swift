import MessageUI
import StoreKit
import SwiftUI

// MARK: - App

@main
struct SkyEarthHumanApp: App {
  var body: some Scene {
    WindowGroup {
      MainView()
    }
  }
}

// MARK: - Main View

private struct MainView: View {
  @Environment(\.scenePhase) private var scenePhase

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        settingsSection
        supportSection
      }
      .padding()
    }
    .task { Self.syncSettingsToAppGroup() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { Self.syncSettingsToAppGroup() }
    }
  }

  private var header: some View {
    VStack(alignment: .leading) {
      Text("하늘땅사람")
        .font(.title)
        .padding(10)
      HStack {
        Text("버전 \(appVersion)")
        Spacer()
        Link("조성현 제작", destination: AppURL.website)
      }
      .padding(10)
      .font(.subheadline)
      .foregroundStyle(.secondary)
      Divider()
    }
  }

  private var settingsSection: some View {
    AppSection(title: "설정 및 설치") {
      Row("설정 앱 열기", systemImage: "gear", url: URL(string: UIApplication.openSettingsURLString)!)
      Row("설치 방법 읽기", systemImage: "book.pages", url: AppURL.installGuide)
    }
  }

  private var supportSection: some View {
    AppSection(title: "지원 및 공유") {
      ShareRow()
      ReviewRow()
      FeedbackRow()
      Row("GitHub에서 보기", systemImage: "wrench.and.screwdriver", url: AppURL.repository)
    }
  }

  static func syncSettingsToAppGroup() {
    let defaults = Dictionary(
      uniqueKeysWithValues: AppSettingKey.allCases.map { ($0.rawValue, $0.defaultValue) }
    )
    UserDefaults.standard.register(defaults: defaults)
    guard let appGroup = UserDefaults(suiteName: AppGroup.suiteName)
    else { return }
    for key in AppSettingKey.allCases {
      appGroup.set(UserDefaults.standard.bool(forKey: key.rawValue), forKey: key.rawValue)
    }
  }
}

// MARK: - Components

private struct AppSection<Content: View>: View {
  let title: String
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundStyle(.secondary)
      content
    }
  }
}

private struct Row: View {
  let label: String
  let systemImage: String
  let url: URL

  init(_ label: String, systemImage: String, url: URL) {
    self.label = label
    self.systemImage = systemImage
    self.url = url
  }

  var body: some View {
    Link(destination: url) {
      Label(label, systemImage: systemImage)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(10)
    Divider()
  }
}

private struct ShareRow: View {
  var body: some View {
    ShareLink(
      item: AppURL.appStore,
      message: Text("이 키보드 보셨어요? 아이폰용 키보드인데 갤럭시 천지인이랑 똑같이 생겼어요!")
    ) {
      Label("친구에게 공유하기", systemImage: "square.and.arrow.up")
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(10)
    Divider()
  }
}

private struct ReviewRow: View {
  @Environment(\.requestReview) private var requestReview
  @State private var showingAlert = false

  var body: some View {
    Button { showingAlert = true } label: {
      Label("5점 리뷰 남기기", systemImage: "heart.fill")
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .alert("5점 리뷰를 남겨주세요!", isPresented: $showingAlert) {
      Button("다음에요...", role: .cancel) {}
      Button("네!") { requestReview() }
    } message: {
      Text("이 키보드는 무료입니다.\n5점 리뷰를 남겨주시면 큰 동기부여가 됩니다.\n앱스토어에 5점 리뷰를 남겨주시겠어요?")
    }
    .padding(10)
    Divider()
  }
}

private struct FeedbackRow: View {
  @State private var showingMailCompose = false

  var body: some View {
    Button { showingMailCompose = true } label: {
      Label("버그 제보 및 기능 제안하기", systemImage: "paperplane.fill")
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .disabled(!MFMailComposeViewController.canSendMail())
    .sheet(isPresented: $showingMailCompose) {
      MailComposeView()
    }
    .padding(10)
    Divider()
  }
}

// MARK: - Mail Compose

private struct MailComposeView: UIViewControllerRepresentable {
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.setToRecipients(["hey@cho.sh"])
    vc.setSubject("하늘땅사람 관련 문의")
    vc.setMessageBody(mailBody, isHTML: false)
    vc.mailComposeDelegate = context.coordinator
    return vc
  }

  func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

  private var mailBody: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    var systemInfo = utsname()
    uname(&systemInfo)
    let model = Mirror(reflecting: systemInfo.machine).children.reduce("") { result, element in
      guard let value = element.value as? Int8, value != 0 else { return result }
      return result + String(UnicodeScalar(UInt8(value)))
    }
    return """

    문의 내용을 여기에 입력해주세요.

    --------------------

    하늘땅사람 버전: \(version)
    iOS 버전: \(UIDevice.current.systemVersion)
    기기: \(UIDevice.current.model) (\(model))

    """
  }

  final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    let parent: MailComposeView

    init(parent: MailComposeView) { self.parent = parent }

    func mailComposeController(
      _: MFMailComposeViewController,
      didFinishWith _: MFMailComposeResult,
      error _: Error?
    ) {
      parent.dismiss()
    }
  }
}

#Preview {
  MainView()
}
