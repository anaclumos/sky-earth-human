//
//  SendEmailView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import MessageUI
import SwiftUI

struct SendEmailView: View {
  @State var result: Result<MFMailComposeResult, Error>? = nil
  @State var isShowingMailView = false
  var body: some View {
    Button(action: {
      self.isShowingMailView.toggle()
    }) {
      Image(systemName: "paperplane.fill").frame(width: 20, alignment: .center)
      Text("버그 제보 및 기능 제안하기")
    }
    .disabled(!MFMailComposeViewController.canSendMail())
    .sheet(isPresented: $isShowingMailView) {
      MailView(result: self.$result)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    Divider()
  }
}

struct SendEmailView_Previews: PreviewProvider {
  static var previews: some View {
    SendEmailView()
  }
}
