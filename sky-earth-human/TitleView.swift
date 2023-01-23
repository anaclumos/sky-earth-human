//
//  TitleView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct TitleView: View {
  var body: some View {
    Text((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)
      .font(.title).padding(10)
    HStack {
      Text("버전 " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
      Spacer()
      Button(action: {
        UIApplication.shared.open(URL(string: "https://cho.sh/ko")!)
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
