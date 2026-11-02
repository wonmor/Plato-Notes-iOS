import SwiftUI

/// The tip jar sheet, opened from "Support Plato" in Settings. Prices come from the App Store;
/// nothing here unlocks anything. No banners, badges or prompts anywhere else in the app.
struct TipJarView: View {
    @Environment(TipJarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if store.status == .thanked {
                    thanks
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                            Text("Support Plato")
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text(TipJar.pitch)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                    }

                    Section {
                        choices
                    } header: {
                        Text("Leave a tip")
                    } footer: {
                        Text(TipJar.disclaimer)
                    }
                }

                switch store.status {
                case .pending:
                    Section { message(TipJar.pending, glyph: "hourglass", tint: .orange) }
                case .failed(let text):
                    Section { message(text, glyph: "exclamationmark.triangle.fill", tint: .red) }
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Tip Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.default, value: store.status)
            .task { await store.loadIfNeeded() }
        }
    }

    @ViewBuilder private var choices: some View {
        switch store.load {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading prices").foregroundStyle(.secondary)
            }
        case .unavailable:
            Text(TipJar.unavailable).foregroundStyle(.secondary)
            Button {
                Task { await store.loadProducts() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
        case .ready:
            ForEach(store.options) { option in tipRow(option) }
        }
    }

    private func tipRow(_ option: TipOption) -> some View {
        let busy = store.status == .purchasing(option.id)
        return Button {
            Task { await store.tip(option) }
        } label: {
            HStack {
                Label(option.name, systemImage: glyph(for: option.id))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if busy {
                    ProgressView()
                } else {
                    Text(option.displayPrice)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .disabled(store.isPurchasing)
        .accessibilityLabel("\(option.name), \(option.displayPrice)")
        .accessibilityHint("Leaves a tip. Unlocks nothing.")
    }

    private func glyph(for id: String) -> String {
        switch id {
        case "plato.tip.1": return "cup.and.saucer"
        case "plato.tip.5": return "takeoutbag.and.cup.and.straw"
        case "plato.tip.20": return "fork.knife"
        default: return "gift"
        }
    }

    private var thanks: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.bounce, value: store.status == .thanked)
                    .accessibilityHidden(true)
                Text("Thank You")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(TipJar.thanks)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Done") { store.dismissMessage(); dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private func message(_ text: String, glyph: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: glyph)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                store.dismissMessage()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
    }
}
