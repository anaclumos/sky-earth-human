//
//  TitleView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct TitleView: View {
  private var appName: String {
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "하늘땅사람"
  }

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
  }

  var body: some View {
    Text(appName)
      .font(.title).padding(10)
    HStack {
      Text("버전 " + appVersion)
      Spacer()
      Button(action: {
        UIApplication.shared.open(AppURL.website)
      }) {
        Text("조성현 제작")
      }
    }.padding(10)
      .font(.subheadline)
      .foregroundColor(.secondary)
    Divider()
  }
}

struct TitleView_Previews: PreviewProvider {
  static var previews: some View {
    TitleView()
  }
}
