//
//  GoToGitHubView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct GoToGitHubView: View {
  var body: some View {
    Button(action: { UIApplication.shared.open(URL(string: "https://github.com/anaclumos/sky-earth-human")!) }) {
      Image(systemName: "wrench.and.screwdriver").frame(width: 20, alignment: .center)
      Text("GitHub에서 보기").frame(alignment: .center)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    Divider()
  }
}

struct GoToGitHubView_Previews: PreviewProvider {
  static var previews: some View {
    GoToGitHubView()
  }
}
