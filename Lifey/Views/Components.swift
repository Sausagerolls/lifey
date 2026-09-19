import SwiftUI

/// A titled block on the setup screen and in the menu sheet.
struct SectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.tally(13, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(Theme.textSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.tally(13, weight: .regular))
                        .foregroundStyle(Theme.textSecondary.opacity(0.75))
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        )
    }
}

/// A selectable pill used for player counts, life presets and counter toggles.
struct SelectPill: View {
    let title: String
    var symbol: String? = nil
    let isSelected: Bool
    var tint: Color = Color(hex: 0x4CC9F0)
    let action: () -> Void

    var body: some View {
        Button {
            Feedback.shared.select()
            action()
        } label: {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(.tally(16, weight: .bold))
            }
            .foregroundStyle(isSelected ? .black : Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint : Theme.surfaceHigh)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? .clear : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A full-width switch row.
struct SettingToggle: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.tally(16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.tally(12, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .tint(Color(hex: 0x3DDC97))
    }
}

/// The big action button at the bottom of the setup screen.
struct PrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = Color(hex: 0x3DDC97)
    let action: () -> Void

    var body: some View {
        Button {
            Feedback.shared.select()
            action()
        } label: {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .black))
                }
                Text(title)
                    .font(.tally(20, weight: .heavy))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint)
                    .shadow(color: tint.opacity(0.35), radius: 16, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = Theme.textPrimary
    let action: () -> Void

    var body: some View {
        Button {
            Feedback.shared.select()
            action()
        } label: {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.tally(16, weight: .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surfaceHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
