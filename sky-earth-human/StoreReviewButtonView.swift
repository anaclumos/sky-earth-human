//
//  StoreReviewButtonView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import StoreKit
import SwiftUI

struct StoreReviewButtonView: View {
  @State private var showingAlert = false
  var body: some View {
    Button(action: {
      showingAlert = true
    }) {
      Image(systemName: "heart.fill").frame(width: 20, alignment: .center)
      Text("5점 리뷰 남기기").frame(alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .alert(isPresented: $showingAlert) {
      Alert(
        title:
          Text("5점 리뷰를 남겨주세요!"),
        message: Text("이 키보드는 무료입니다.\n5점 리뷰를 남겨주시면 큰 동기부여가 됩니다.\n앱스토어에 5점 리뷰를 남겨주시겠어요?"),
        primaryButton: .cancel(Text("다음에요...")),
        secondaryButton: .default(Text("네!")) {
          if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)

          }
          UIApplication.shared.open(
            URL(string: "https://apps.apple.com/app/id/1666355842?action=write-review")!)
        })
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    Divider()
  }
}

struct StoreReviewButtonView_Previews: PreviewProvider {
  static var previews: some View {
    StoreReviewButtonView()
  }
}
