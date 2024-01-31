//
//  HowToInstallView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct HowToInstallView: View {
  var body: some View {
    Button(action: {
      UIApplication.shared.open(URL(string: "https://cho.sh/ko/r/BA36FC")!)
    }) {
      Image(systemName: "book.pages").frame(width: 20, alignment: .center)
      Text("설치 방법 읽기").frame(alignment: .center).frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    Divider()
  }
}

#Preview {
  HowToInstallView()
}
