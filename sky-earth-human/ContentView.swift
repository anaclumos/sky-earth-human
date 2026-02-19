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
      VStack(alignment: .leading, spacing: 24) {
        TitleView()

        AppSection(title: "설정 및 설치") {
          GoToSettingsView()
          HowToInstallView()
          QuickSettingsView()
        }

        AppSection(title: "지원 및 공유") {
          ShareWithFriendView()
          StoreReviewButtonView()
          SendEmailView()
          GoToGitHubView()
        }
      }
      .padding()
    }
    .navigationTitle("하늘땅사람")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

private struct AppSection<Content: View>: View {
  let title: String
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundColor(.secondary)
      content
    }
  }
}
