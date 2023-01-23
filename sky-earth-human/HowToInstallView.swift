//
//  HowToInstallView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct HowToInstallView: View {
  var body: some View {
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
}

struct HowToInstallView_Previews: PreviewProvider {
  static var previews: some View {
    HowToInstallView()
  }
}
