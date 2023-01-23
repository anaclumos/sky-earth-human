//
//  ContentView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 12/19/22.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        TitleView()
        GoToSettingsView()
        ShareWithFriendView()
        StoreReviewButtonView()
        SendEmailView()
        GoToGitHubView()
        HowToInstallView()
      }
    }
    .padding()
    .navigationTitle("하늘땅사람")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
