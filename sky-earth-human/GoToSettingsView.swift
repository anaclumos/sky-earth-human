//
//  GoToSettingsView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2023-01-22.
//

import SwiftUI

struct GoToSettingsView: View {
  var body: some View {
    Button(action: { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) })
    {
      Image(systemName: "gear").frame(width: 20, alignment: .center)
      Text("설정").frame(alignment: .center)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    Divider()
  }
}

struct GoToSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    GoToSettingsView()
  }
}
