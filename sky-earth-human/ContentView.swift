//
//  ContentView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 12/19/22.
//

import CoreData
import SwiftUI

struct ContentView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)
          .font(.title).padding(5)
        HStack {
          Text("버전 " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
          Spacer()
          Text("LA, 서울, 그리고 대전")
        }.padding(5)
          .font(.subheadline)
          .foregroundColor(.secondary)
        Divider()
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
        )
        .font(.body).padding(5)
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
