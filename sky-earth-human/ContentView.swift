//
//  ContentView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 12/19/22.
//

import CoreData
import MessageUI
import StoreKit
import SwiftUI

struct ContentView: View {
  @State var result: Result<MFMailComposeResult, Error>? = nil
  @State var isShowingMailView = false
  @State private var showingAlert = false
  @State var sounds = false
  @State var haptics = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Group {
          Text((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)
            .font(.title).padding(5)
          HStack {
            Text("버전 " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
            Spacer()
            Text("by Sunghyun Cho")
          }.padding(5)
            .font(.subheadline)
            .foregroundColor(.secondary)
          Divider()
        }
        Group {
          Text("설치 방법")
            .font(.title2).padding(5)
          Text(
            """
            1. **설정** 앱 열기
            2. **일반** 탭으로 이동
            3. **키보드** 탭으로 이동
            4. **키보드** 탭으로 다시 한 번 이동
            5. **새로운 키보드 추가...** 버튼 누르기
            6. 타사 키보드 중 **\((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)** 선택!
            """
          ).frame(alignment: .center)
            .font(.body).padding(5)
          Divider()
          Text("소리 및 진동 피드백 사용 방법")
            .font(.title2).padding(5)
          Text(
            """
            진동 피드백을 사용하기 위해서는 **전체 접근 허용**이 활성화되어 있어야 합니다.

            1. 아래 **설정** 버튼 누르기
            2. **키보드** 탭으로 이동
            3. **전체 접근 허용** 켜기
            """
          ).frame(alignment: .center)
            .font(.body).padding(5)
          Divider()
        }
        Group {
          Button(action: { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }) {
            Image(systemName: "gear").frame(alignment: .center)
            Text("설정").frame(alignment: .center)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(5)
          Divider()
        }

        Group {
          Button(action: {
            showingAlert = true
          }) {
            Image(systemName: "heart.fill").frame(alignment: .center)
            Text("5점 리뷰 남기기").frame(alignment: .center)
          }
          .alert(isPresented: $showingAlert) {
            Alert(title:
              Text("5점 리뷰를 남겨주세요!"),
              message: Text("이 키보드는 무료입니다.\n5점 리뷰를 남겨주시면 큰 동기부여가 됩니다.\n앱스토어에 5점 리뷰를 남겨주시겠어요?"),
              primaryButton: .cancel(Text("다음에요...")),
              secondaryButton: .default(Text("네!")) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                  SKStoreReviewController.requestReview(in: windowScene)
                }
                else {
                  UIApplication.shared.open(URL(string: "https://apps.apple.com/app/id/1666355842?action=write-review")!)
                }
              })
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(5)
          Divider()
        }
        Group {
          Button(action: {
            self.isShowingMailView.toggle()
          }) {
            Image(systemName: "paperplane.fill").frame(alignment: .center)
            Text("버그 제보 및 기능 제안하기")
          }
          .disabled(!MFMailComposeViewController.canSendMail())
          .sheet(isPresented: $isShowingMailView) {
            MailView(result: self.$result)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(5)
          Divider()
        }
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
