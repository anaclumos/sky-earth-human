import MessageUI
import StoreKit
import SwiftUI
import UIKit

struct HomeView: View {
  @Environment(\.requestReview) private var requestReview
  @State private var showingReviewAlert = false
  @State private var showingMailCompose = false

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading) {
          Text("하늘땅사람")
            .font(.title)
          HStack {
            Text("버전 \(appVersion)")
            Spacer()
            Link("조성현 제작", destination: AppURL.website)
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }

      Section("설정 및 설치") {
        NavigationLink(destination: SettingsView()) {
          Label("키보드 설정", systemImage: "keyboard")
        }
        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
          Label("설정 앱 열기", systemImage: "gear")
        }
        Link(destination: AppURL.installGuide) {
          Label("설치 방법 읽기", systemImage: "book.pages")
        }
      }

      Section("지원 및 공유") {
        ShareLink(
          item: AppURL.appStore,
          message: Text("이 키보드 보셨어요? 아이폰용 키보드인데 갤럭시 천지인이랑 똑같이 생겼어요!")
        ) {
          Label("친구에게 공유하기", systemImage: "square.and.arrow.up")
        }

        Button {
          showingReviewAlert = true
        } label: {
          Label("5점 리뷰 남기기", systemImage: "heart.fill")
        }

        Button {
          showingMailCompose = true
        } label: {
          Label("버그 제보 및 기능 제안하기", systemImage: "paperplane.fill")
        }
        .disabled(!MFMailComposeViewController.canSendMail())

        Link(destination: AppURL.repository) {
          Label("GitHub에서 보기", systemImage: "wrench.and.screwdriver")
        }
      }
    }
    .alert("5점 리뷰를 남겨주세요!", isPresented: $showingReviewAlert) {
      Button("다음에요...", role: .cancel) {}
      Button("네!") { requestReview() }
    } message: {
      Text("이 키보드는 무료입니다.\n5점 리뷰를 남겨주시면 큰 동기부여가 됩니다.\n앱스토어에 5점 리뷰를 남겨주시겠어요?")
    }
    .sheet(isPresented: $showingMailCompose) {
      MailComposeView()
    }
  }
}

private struct MailComposeView: UIViewControllerRepresentable {
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let controller = MFMailComposeViewController()
    controller.setToRecipients(["hey@cho.sh"])
    controller.setSubject("하늘땅사람 관련 문의")
    controller.setMessageBody(mailBody, isHTML: false)
    controller.mailComposeDelegate = context.coordinator
    return controller
  }

  func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

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

  @MainActor
  final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
    let parent: MailComposeView

    init(parent: MailComposeView) {
      self.parent = parent
    }

    func mailComposeController(
      _: MFMailComposeViewController,
      didFinishWith _: MFMailComposeResult,
      error _: (any Error)?
    ) {
      parent.dismiss()
    }
  }
}

#Preview {
  NavigationStack {
    HomeView()
  }
}
