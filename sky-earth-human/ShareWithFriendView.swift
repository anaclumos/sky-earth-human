//
//  ShareWithFriendView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct ShareWithFriendView: View {
  let url = URL(string: "https://apps.apple.com/app/id/1666355842")!
  let text = "이 키보드 보셨어요? 아이폰용 키보드인데 갤럭시 천지인이랑 똑같이 생겼어요!"
  let displayText = "친구에게 공유하기"
  var body: some View {
    if #available(iOS 16.0, *) {
      ShareLink(
        item: url,
        message:
          Text(text)
      ) {
        Image(systemName: "square.and.arrow.up").frame(width: 20, alignment: .center)
        Text(displayText).frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(10)
      Divider()
    } else {
      // Fallback on earlier versions
      Button(action: deprecatedShare) {
        Image(systemName: "square.and.arrow.up").frame(width: 20, alignment: .center)
        Text(displayText)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(10)
      Divider()
    }
  }

  func deprecatedShare() {
    let activityViewController = UIActivityViewController(
      activityItems: [url, text], applicationActivities: nil)

    // Iterate over connected scenes to find an active window scene
    if let windowScene = UIApplication.shared.connectedScenes.first(where: {
      $0.activationState == .foregroundActive
    }) as? UIWindowScene {
      // Find a window that is currently being used
      if let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?
        .rootViewController
      {
        rootViewController.present(activityViewController, animated: true, completion: nil)
      }
    }
  }

}

struct ShareWithFriendView_Previews: PreviewProvider {
  static var previews: some View {
    ShareWithFriendView()
  }
}
