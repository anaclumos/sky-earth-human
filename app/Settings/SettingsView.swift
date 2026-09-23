import SwiftUI

struct SettingsView: View {
  @State private var model = SettingsModel()

  var body: some View {
    Form {
      Section("자판") {
        Picker("키 크기", selection: $model.keySize) {
          ForEach(KeySize.allCases) { size in
            Text(size.label).tag(size)
          }
        }
        .pickerStyle(.segmented)
      }

      Section("피드백") {
        Toggle("햅틱 피드백", isOn: $model.isHapticFeedbackEnabled)
        Toggle("예측", isOn: $model.isPredictionEnabled)
      }

      Section {
        Stepper(value: $model.cycleLockSeconds, in: SettingsModel.cycleLockRange, step: SettingsModel.cycleLockStep) {
          Text("자음 순환 시간: \(model.cycleLockSeconds, specifier: "%.2f")초")
        }
      } header: {
        Text("입력")
      } footer: {
        Text("키보드는 다음에 나타날 때부터 변경 사항을 적용합니다.")
      }
    }
    .navigationTitle("키보드 설정")
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
}
