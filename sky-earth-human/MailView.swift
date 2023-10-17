//
//  MailView.swift
//  sky-earth-human
//
//  Source: https://stackoverflow.com/a/58693164/9568307
//

import MessageUI
import SwiftUI
import UIKit
import Darwin

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
    return Coordinator(
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

      하늘땅사람 버전: \((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
      iOS 버전: \(UIDevice.current.systemVersion)
      기기: \(deviceModelIdentifier())

      """, isHTML: false)
    vc.mailComposeDelegate = context.coordinator
    return vc
  }

  func updateUIViewController(
    _: MFMailComposeViewController,
    context _: UIViewControllerRepresentableContext<MailView>
  ) {}
  
  func deviceModelIdentifier() -> String {
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineMirror = Mirror(reflecting: systemInfo.machine)
      let identifier = machineMirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
      }
      return identifier
  }
  
  func deviceModelReadable() -> String {
      let identifier = deviceModelIdentifier()
      switch identifier {
      case "iPhone9,1" : return "iPhone 7"
      case "iPhone9,2" : return "iPhone 7 Plus"
      case "iPhone9,3" : return "iPhone 7"
      case "iPhone9,4" : return "iPhone 7 Plus"
      case "iPhone10,1" : return "iPhone 8"
      case "iPhone10,2" : return "iPhone 8 Plus"
      case "iPhone10,3" : return "iPhone X Global"
      case "iPhone10,4" : return "iPhone 8"
      case "iPhone10,5" : return "iPhone 8 Plus"
      case "iPhone10,6" : return "iPhone X GSM"
      case "iPhone11,2" : return "iPhone XS"
      case "iPhone11,4" : return "iPhone XS Max"
      case "iPhone11,6" : return "iPhone XS Max Global"
      case "iPhone11,8" : return "iPhone XR"
      case "iPhone12,1" : return "iPhone 11"
      case "iPhone12,3" : return "iPhone 11 Pro"
      case "iPhone12,5" : return "iPhone 11 Pro Max"
      case "iPhone12,8" : return "iPhone SE 2nd Gen"
      case "iPhone13,1" : return "iPhone 12 Mini"
      case "iPhone13,2" : return "iPhone 12"
      case "iPhone13,3" : return "iPhone 12 Pro"
      case "iPhone13,4" : return "iPhone 12 Pro Max"
      case "iPhone14,2" : return "iPhone 13 Pro"
      case "iPhone14,3" : return "iPhone 13 Pro Max"
      case "iPhone14,4" : return "iPhone 13 Mini"
      case "iPhone14,5" : return "iPhone 13"
      case "iPhone14,6" : return "iPhone SE 3rd Gen"
      case "iPhone14,7" : return "iPhone 14"
      case "iPhone14,8" : return "iPhone 14 Plus"
      case "iPhone15,2" : return "iPhone 14 Pro"
      case "iPhone15,3" : return "iPhone 14 Pro Max"
      case "iPhone15,4" : return "iPhone 15"
      case "iPhone15,5" : return "iPhone 15 Plus"
      case "iPhone16,1" : return "iPhone 15 Pro"
      case "iPhone16,2" : return "iPhone 15 Pro Max"
      case "iPod7,1" : return "6th Gen iPod"
      case "iPod9,1" : return "7th Gen iPod"
      case "iPad4,1" : return "iPad Air (WiFi)"
      case "iPad4,2" : return "iPad Air (GSM+CDMA)"
      case "iPad4,3" : return "1st Gen iPad Air (China)"
      case "iPad4,4" : return "iPad mini Retina (WiFi)"
      case "iPad4,5" : return "iPad mini Retina (GSM+CDMA)"
      case "iPad4,6" : return "iPad mini Retina (China)"
      case "iPad4,7" : return "iPad mini 3 (WiFi)"
      case "iPad4,8" : return "iPad mini 3 (GSM+CDMA)"
      case "iPad4,9" : return "iPad Mini 3 (China)"
      case "iPad5,1" : return "iPad mini 4 (WiFi)"
      case "iPad5,2" : return "4th Gen iPad mini (WiFi+Cellular)"
      case "iPad5,3" : return "iPad Air 2 (WiFi)"
      case "iPad5,4" : return "iPad Air 2 (Cellular)"
      case "iPad6,3" : return "iPad Pro (9.7 inch, WiFi)"
      case "iPad6,4" : return "iPad Pro (9.7 inch, WiFi+LTE)"
      case "iPad6,7" : return "iPad Pro (12.9 inch, WiFi)"
      case "iPad6,8" : return "iPad Pro (12.9 inch, WiFi+LTE)"
      case "iPad6,11" : return "iPad (2017)"
      case "iPad6,12" : return "iPad (2017)"
      case "iPad7,1" : return "iPad Pro 2nd Gen (WiFi)"
      case "iPad7,2" : return "iPad Pro 2nd Gen (WiFi+Cellular)"
      case "iPad7,3" : return "iPad Pro 10.5-inch 2nd Gen"
      case "iPad7,4" : return "iPad Pro 10.5-inch 2nd Gen"
      case "iPad7,5" : return "iPad 6th Gen (WiFi)"
      case "iPad7,6" : return "iPad 6th Gen (WiFi+Cellular)"
      case "iPad7,11" : return "iPad 7th Gen 10.2-inch (WiFi)"
      case "iPad7,12" : return "iPad 7th Gen 10.2-inch (WiFi+Cellular)"
      case "iPad8,1" : return "iPad Pro 11 inch 3rd Gen (WiFi)"
      case "iPad8,2" : return "iPad Pro 11 inch 3rd Gen (1TB, WiFi)"
      case "iPad8,3" : return "iPad Pro 11 inch 3rd Gen (WiFi+Cellular)"
      case "iPad8,4" : return "iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)"
      case "iPad8,5" : return "iPad Pro 12.9 inch 3rd Gen (WiFi)"
      case "iPad8,6" : return "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)"
      case "iPad8,7" : return "iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)"
      case "iPad8,8" : return "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)"
      case "iPad8,9" : return "iPad Pro 11 inch 4th Gen (WiFi)"
      case "iPad8,10" : return "iPad Pro 11 inch 4th Gen (WiFi+Cellular)"
      case "iPad8,11" : return "iPad Pro 12.9 inch 4th Gen (WiFi)"
      case "iPad8,12" : return "iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)"
      case "iPad11,1" : return "iPad mini 5th Gen (WiFi)"
      case "iPad11,2" : return "iPad mini 5th Gen"
      case "iPad11,3" : return "iPad Air 3rd Gen (WiFi)"
      case "iPad11,4" : return "iPad Air 3rd Gen"
      case "iPad11,6" : return "iPad 8th Gen (WiFi)"
      case "iPad11,7" : return "iPad 8th Gen (WiFi+Cellular)"
      case "iPad12,1" : return "iPad 9th Gen (WiFi)"
      case "iPad12,2" : return "iPad 9th Gen (WiFi+Cellular)"
      case "iPad14,1" : return "iPad mini 6th Gen (WiFi)"
      case "iPad14,2" : return "iPad mini 6th Gen (WiFi+Cellular)"
      case "iPad13,1" : return "iPad Air 4th Gen (WiFi)"
      case "iPad13,2" : return "iPad Air 4th Gen (WiFi+Cellular)"
      case "iPad13,4" : return "iPad Pro 11 inch 5th Gen"
      case "iPad13,5" : return "iPad Pro 11 inch 5th Gen"
      case "iPad13,6" : return "iPad Pro 11 inch 5th Gen"
      case "iPad13,7" : return "iPad Pro 11 inch 5th Gen"
      case "iPad13,8" : return "iPad Pro 12.9 inch 5th Gen"
      case "iPad13,9" : return "iPad Pro 12.9 inch 5th Gen"
      case "iPad13,10" : return "iPad Pro 12.9 inch 5th Gen"
      case "iPad13,11" : return "iPad Pro 12.9 inch 5th Gen"
      case "iPad13,16" : return "iPad Air 5th Gen (WiFi)"
      case "iPad13,17" : return "iPad Air 5th Gen (WiFi+Cellular)"
      case "iPad13,18" : return "iPad 10th Gen"
      case "iPad13,19" : return "iPad 10th Gen"
      case "iPad14,3" : return "iPad Pro 11 inch 4th Gen"
      case "iPad14,4" : return "iPad Pro 11 inch 4th Gen"
      case "iPad14,5" : return "iPad Pro 12.9 inch 6th Gen"
      case "iPad14,6" : return "iPad Pro 12.9 inch 6th Gen"
      default: return identifier
      }
  }

}
