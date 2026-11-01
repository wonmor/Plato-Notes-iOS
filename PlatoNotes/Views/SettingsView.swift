import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PlatoTheme.appearanceKey) private var appearance = PlatoTheme.Appearance.dark.rawValue

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlatoTheme.Palette.ground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: PlatoTheme.Space.l) {
                        Rule(height: PlatoTheme.Rule.heavy)

                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 1, title: "Appearance")
                            HStack(spacing: 0) {
                                ForEach(PlatoTheme.Appearance.allCases) { option in
                                    let selected = appearance == option.rawValue
                                    Button {
                                        appearance = option.rawValue
                                    } label: {
                                        Text(option.title)
                                            .font(PlatoTheme.Typo.button)
                                            .frame(maxWidth: .infinity, minHeight: 48)
                                            .background(selected ? PlatoTheme.Palette.ember : PlatoTheme.Palette.field)
                                            .foregroundStyle(selected ? PlatoTheme.Palette.onEmber : PlatoTheme.Palette.ink)
                                    }
                                    .accessibilityAddTraits(selected ? .isSelected : [])
                                }
                            }
                            .overlay(Rectangle().strokeBorder(PlatoTheme.Palette.ink, lineWidth: PlatoTheme.Rule.regular))
                            Text("Plato is designed dark first.")
                                .font(PlatoTheme.Typo.caption)
                                .foregroundStyle(PlatoTheme.Palette.inkMuted)
                        }

                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 2, title: "How it works")
                            Rule(height: PlatoTheme.Rule.regular)
                            row("timer", "Every note has a timer, from 5 minutes to 7 days.")
                            row("flame.fill", "When it runs out, the note is deleted for good. Burn it sooner from the note.")
                            row("lock.fill", "Notes stay on this device. No account, no sync, no tracking.")
                        }

                        VStack(alignment: .leading, spacing: PlatoTheme.Space.s) {
                            SectionLabel(number: 3, title: "About", trailing: version)
                            Rule(height: PlatoTheme.Rule.regular)
                            Link(destination: URL(string: "https://github.com/wonmor/Plato-Notes-iOS")!) {
                                HStack {
                                    Label("Source code", systemImage: "chevron.left.forwardslash.chevron.right")
                                        .font(PlatoTheme.Typo.body)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .accessibilityHidden(true)
                                }
                                .foregroundStyle(PlatoTheme.Palette.ink)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.horizontal, PlatoTheme.Space.m)
                    .padding(.bottom, PlatoTheme.Space.xl)
                    .frame(maxWidth: PlatoTheme.readableWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(PlatoTheme.Typo.button)
                        .foregroundStyle(PlatoTheme.Palette.ember)
                }
            }
        }
        .preferredColorScheme((PlatoTheme.Appearance(rawValue: appearance) ?? .dark).colorScheme)
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatoTheme.Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PlatoTheme.Palette.ember)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(PlatoTheme.Typo.body)
                .foregroundStyle(PlatoTheme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
