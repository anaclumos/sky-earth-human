//
//  MailView.swift
//  sky-earth-human
//
//  Source: https://stackoverflow.com/a/58693164/9568307
//

import Darwin
import MessageUI
import SwiftUI
import UIKit

struct MailView: UIViewControllerRepresentable {
  @Environment(\.presentationMode) var presentation
  @Binding var result: Result<MFMailComposeResult, Error>?

  class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    @Binding var presentation: PresentationMode
    @Binding var result: Result<MFMailComposeResult, Error>?

    init(
      presentation: Binding<PresentationMode>,
      result: Binding<Result<MFMailComposeResult, Error>?>
    ) {
      _presentation = presentation
      _result = result
    }

    func mailComposeController(
      _: MFMailComposeViewController,
      didFinishWith result: MFMailComposeResult,
      error: Error?
    ) {
      defer {
        $presentation.wrappedValue.dismiss()
      }

      guard error == nil else {
        self.result = .failure(error!)
        return
      }

      self.result = .success(result)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      presentation: presentation,
      result: $result)
  }

  func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>)
    -> MFMailComposeViewController
  {
    let vc = MFMailComposeViewController()
    vc.setToRecipients(["hey@cho.sh"])
    vc.setSubject("하늘땅사람 관련 문의")
    vc.setMessageBody(
      """

      문의 내용을 여기에 입력해주세요.

      --------------------

      하늘땅사람 버전: \(appVersion)
      iOS 버전: \(UIDevice.current.systemVersion)
      기기: \(deviceSummary())

      """, isHTML: false)
    vc.mailComposeDelegate = context.coordinator
    return vc
  }

  func updateUIViewController(
    _: MFMailComposeViewController,
    context _: UIViewControllerRepresentableContext<MailView>
  ) {}

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
  }

  private func deviceModelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)

    return machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else {
        return identifier
      }

      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }

  private func deviceSummary() -> String {
    "\(UIDevice.current.model) (\(deviceModelIdentifier()))"
  }
}
