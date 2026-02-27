import SwiftUI

// MARK: - Template Picker
// Horizontal strip of theme swatches, embedded at the top of EditorView.

struct TemplatePickerView: View {
    @Binding var selected: ThemePreset

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ThemePreset.allCases.filter { $0 != .custom }) { preset in
                    ThemeSwatch(preset: preset, isSelected: selected == preset)
                        .onTapGesture { selected = preset }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - ThemeSwatch

private struct ThemeSwatch: View {
    let preset: ThemePreset
    let isSelected: Bool

    private var theme: TeamTheme { preset.theme }

    var body: some View {
        VStack(spacing: 6) {
            // Mini card preview
            ZStack {
                theme.backgroundColor
                    .frame(width: 52, height: 65)
                    .cornerRadius(6)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(preset.displayName.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                        .padding(.top, 5)
                    Text("XI")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(theme.accentColor)
                    Spacer()
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                .frame(width: 52, height: 65, alignment: .topTrailing)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            Text(preset.displayName)
                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .lineLimit(1)
        }
        .frame(width: 60)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
