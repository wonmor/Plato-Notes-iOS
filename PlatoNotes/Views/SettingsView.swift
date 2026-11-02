import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PlatoTheme.appearanceKey) private var appearance = PlatoTheme.Appearance.light.rawValue

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        BrandMark(size: 60)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Plato")
                                .font(.title3.weight(.semibold))
                            Text("Notes that vanish.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(PlatoTheme.Appearance.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("How It Works") {
                    Label("Every note has a timer, from 5 minutes to 7 days.", systemImage: "timer")
                    Label("When it runs out, the note is deleted for good. Burn it sooner from the note or with a swipe.", systemImage: "flame")
                    Label("Notes stay on this device. No account, no sync, no tracking.", systemImage: "lock")
                }

                Section {
                    LabeledContent("Version", value: version)
                    Link(destination: URL(string: "https://github.com/wonmor/Plato-Notes-iOS")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(PlatoTheme.scheme(appearance))
    }
}
