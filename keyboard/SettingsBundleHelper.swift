import Foundation
import UIKit

import Foundation
class SettingsBundleHelper {
  enum SettingsBundleKeys {
    static let BuildVersionKey = "build"
    static let AppVersionKey = "version"
  }

  class func setVersionAndBuildNumber() {
    let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    UserDefaults.standard.set(version, forKey: SettingsBundleKeys.AppVersionKey)
    let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    UserDefaults.standard.set(build, forKey: SettingsBundleKeys.BuildVersionKey)
  }
}
