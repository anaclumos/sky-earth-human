//
//  sky_earth_humanApp.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 12/19/22.
//

import SwiftUI

@main
struct sky_earth_humanApp: App {
  let persistenceController = PersistenceController.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}
