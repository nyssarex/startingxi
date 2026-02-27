import SwiftUI

// MARK: - Card Canvas View
// Renders a 1080:1350 (4:5) portrait card. All layout uses proportional sizing
// relative to the view's actual geometry, so it scales correctly from tiny
// thumbnails up to full 1080×1350 export.

struct CardCanvasView: View {
    let card: LineupCard

    // Resolve images lazily
    private var playerPhoto: UIImage? { card.playerPhotoData.flatMap(UIImage.init(data:)) }
    private var badge1: UIImage?      { card.badge1Data.flatMap(UIImage.init(data:)) }
    private var badge2: UIImage?      { card.badge2Data.flatMap(UIImage.init(data:)) }
    private var bgPhoto: UIImage?     { card.backgroundImageData.flatMap(UIImage.init(data:)) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let theme = card.resolvedTheme

            ZStack(alignment: .topLeading) {
                // Layer 1 — Background
                backgroundLayer(theme: theme, w: w, h: h)

                // Layer 2 — Left photo panel
                if theme.showLeftPanel, let photo = playerPhoto {
                    photoLayer(photo: photo, theme: theme, w: w, h: h)
                }

                // Layer 3 — Right text panel
                textPanel(theme: theme, w: w, h: h)

                // Layer 4 — Bottom strip (badges + match label)
                bottomStrip(theme: theme, w: w, h: h)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(1080.0 / 1350.0, contentMode: .fit)
        .clipped()
    }

    // MARK: - Background Layer

    @ViewBuilder
    private func backgroundLayer(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        switch theme.backgroundStyle {
        case .solid:
            theme.backgroundColor
                .frame(width: w, height: h)

        case .gradient:
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.backgroundColor.opacity(0.8),
                    theme.accentColor.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: w, height: h)

        case .blurredPhoto:
            ZStack {
                theme.backgroundColor.frame(width: w, height: h)
                if let photo = bgPhoto ?? playerPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: w, height: h)
                        .blur(radius: 22)
                        .clipped()
                        .overlay(theme.backgroundColor.opacity(0.62))
                }
            }
        }
    }

    // MARK: - Photo Layer (left side, fades right)

    @ViewBuilder
    private func photoLayer(photo: UIImage, theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let photoW = w * theme.leftPanelWidth * 1.18  // slightly wider so fade reaches the panel boundary

        Image(uiImage: photo)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: photoW, height: h)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    Rectangle()
                        .frame(width: photoW * 0.52)
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.6), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(width: photoW, height: h)
            )
    }

    // MARK: - Text Panel

    @ViewBuilder
    private func textPanel(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let panelX = theme.showLeftPanel ? w * theme.leftPanelWidth * 0.72 : w * 0.06
        let panelW = w - panelX - w * 0.05
        let alignment: HorizontalAlignment = {
            switch theme.listAlignment {
            case .leading:   return .leading
            case .center:    return .center
            case .trailing:  return .trailing
            }
        }()

        VStack(alignment: alignment, spacing: 0) {
            // Title block
            titleBlock(theme: theme, w: panelW, h: h)

            // Divider
            dividerLine(theme: theme, w: panelW)
                .padding(.top, h * 0.014)
                .padding(.bottom, h * 0.014)

            // Starting players
            starterList(theme: theme, w: panelW, h: h)

            // Bench section
            if !card.bench.isEmpty {
                benchSection(theme: theme, w: panelW, h: h)
            }

            Spacer(minLength: 0)
        }
        .frame(width: panelW, alignment: Alignment(horizontal: alignment, vertical: .top))
        .padding(.top, h * 0.07)
        .offset(x: panelX)
        .frame(height: h * 0.87)  // leave room for bottom strip
    }

    // MARK: - Title Block

    @ViewBuilder
    private func titleBlock(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let alignment: HorizontalAlignment = {
            switch theme.listAlignment {
            case .leading:   return .leading
            case .center:    return .center
            case .trailing:  return .trailing
            }
        }()
        VStack(alignment: alignment, spacing: h * 0.004) {
            // "STARTING" / title word
            Text(card.titleWord.uppercased())
                .font(.system(size: h * 0.026, weight: .bold, design: .default))
                .tracking(h * 0.003)
                .foregroundColor(theme.textColor)
                .lineLimit(1)

            // Roman numeral — large, accent colour
            Text(card.romanNumeral)
                .font(.system(size: h * 0.092, weight: .black, design: .default))
                .foregroundColor(theme.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Sponsor line (optional)
            if !card.sponsorLine.isEmpty {
                Text(card.sponsorLine)
                    .font(.system(size: h * 0.015, weight: .medium, design: .default))
                    .tracking(1.5)
                    .foregroundColor(theme.textColor.opacity(0.45))
                    .lineLimit(1)
            }

            // Manager (optional)
            if !card.managerName.isEmpty {
                Text("MGR: \(card.managerName.uppercased())")
                    .font(.system(size: h * 0.017, weight: .semibold, design: .default))
                    .foregroundColor(theme.textColor.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Divider

    @ViewBuilder
    private func dividerLine(theme: TeamTheme, w: CGFloat) -> some View {
        Rectangle()
            .fill(theme.accentColor.opacity(0.45))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Starter List

    @ViewBuilder
    private func starterList(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let count = max(card.starters.count, 1)
        let hasBench = !card.bench.isEmpty
        // Total rows = starters + (bench header + bench players if present)
        let totalEffectiveRows = count + (hasBench ? card.bench.count + 1 : 0)
        // Available height for all rows (from divider to bottom strip)
        let availH = h * 0.52
        let rowH = min(availH / CGFloat(max(totalEffectiveRows, 8)), h * 0.068)
        let fontSize = rowH * 0.52

        VStack(alignment: alignmentFor(theme), spacing: rowH * 0.08) {
            ForEach(Array(card.starters.enumerated()), id: \.element.id) { _, player in
                PlayerRowView(
                    player: player,
                    theme: theme,
                    fontSize: fontSize,
                    rowHeight: rowH
                )
                .frame(height: rowH)
            }
        }
    }

    // MARK: - Bench Section

    @ViewBuilder
    private func benchSection(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let count = max(card.starters.count, 1)
        let hasBench = !card.bench.isEmpty
        let totalEffectiveRows = count + (hasBench ? card.bench.count + 1 : 0)
        let availH = h * 0.52
        let rowH = min(availH / CGFloat(max(totalEffectiveRows, 8)), h * 0.068)
        let subFontSize = rowH * 0.40

        VStack(alignment: alignmentFor(theme), spacing: rowH * 0.06) {
            // Subs header
            HStack(spacing: 4) {
                Rectangle()
                    .fill(theme.accentColor)
                    .frame(width: 3, height: subFontSize * 1.1)
                Text("SUBS")
                    .font(.system(size: subFontSize * 0.9, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(theme.accentColor)
            }
            .padding(.top, rowH * 0.3)

            // Bench players in two columns if 5+
            if card.bench.count >= 5 {
                let half = Int(ceil(Double(card.bench.count) / 2.0))
                let left = Array(card.bench.prefix(half))
                let right = Array(card.bench.suffix(card.bench.count - half))
                HStack(alignment: .top, spacing: w * 0.04) {
                    VStack(alignment: .leading, spacing: rowH * 0.06) {
                        ForEach(left) { player in
                            PlayerRowView(player: player, theme: theme, fontSize: subFontSize, rowHeight: rowH * 0.75)
                        }
                    }
                    VStack(alignment: .leading, spacing: rowH * 0.06) {
                        ForEach(right) { player in
                            PlayerRowView(player: player, theme: theme, fontSize: subFontSize, rowHeight: rowH * 0.75)
                        }
                    }
                }
            } else {
                ForEach(card.bench) { player in
                    PlayerRowView(player: player, theme: theme, fontSize: subFontSize, rowHeight: rowH * 0.75)
                }
            }
        }
    }

    // MARK: - Bottom Strip

    @ViewBuilder
    private func bottomStrip(theme: TeamTheme, w: CGFloat, h: CGFloat) -> some View {
        let stripH = h * 0.11
        HStack(alignment: .center, spacing: 0) {
            // Match label
            if !card.matchLabel.isEmpty {
                Text(card.matchLabel.uppercased())
                    .font(.system(size: h * 0.019, weight: .semibold))
                    .tracking(1.0)
                    .foregroundColor(theme.textColor.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            // Badges
            HStack(spacing: w * 0.025) {
                if let b1 = badge1 {
                    Image(uiImage: b1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: stripH * 0.62)
                }
                if let b2 = badge2 {
                    Image(uiImage: b2)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: stripH * 0.62)
                }
            }
        }
        .padding(.horizontal, w * 0.055)
        .frame(width: w, height: stripH)
        .background(theme.accentColor.opacity(0.08))
        .offset(y: h * 0.89)
    }

    // MARK: - Helpers

    private func alignmentFor(_ theme: TeamTheme) -> HorizontalAlignment {
        switch theme.listAlignment {
        case .leading:   return .leading
        case .center:    return .center
        case .trailing:  return .trailing
        }
    }
}

// MARK: - Player Row View

struct PlayerRowView: View {
    let player: Player
    let theme: TeamTheme
    let fontSize: CGFloat
    let rowHeight: CGFloat

    var body: some View {
        switch theme.numberPlacement {
        case .leftInteger:
            leftIntegerRow
        case .rightDecimal:
            rightDecimalRow
        }
    }

    // "31  PLAYER NAME [C]"
    private var leftIntegerRow: some View {
        HStack(alignment: .center, spacing: fontSize * 0.45) {
            Text("\(player.number)")
                .font(.system(size: fontSize * 0.72, weight: .medium))
                .foregroundColor(theme.numberColor)
                .frame(width: fontSize * 1.6, alignment: .trailing)
                .lineLimit(1)

            Text(player.surname.uppercased())
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            if player.isCaptain {
                captainBadge
            }

            Spacer(minLength: 0)
        }
        .frame(height: rowHeight)
    }

    // "PLAYER NAME .31 [C]"
    private var rightDecimalRow: some View {
        HStack(alignment: .center, spacing: fontSize * 0.3) {
            Spacer(minLength: 0)

            if player.isCaptain {
                captainBadge
            }

            Text(player.surname.uppercased())
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(".\(player.number)")
                .font(.system(size: fontSize * 0.68, weight: .regular))
                .foregroundColor(theme.numberColor)
                .lineLimit(1)
        }
        .frame(height: rowHeight)
    }

    private var captainBadge: some View {
        Text("C")
            .font(.system(size: fontSize * 0.55, weight: .black))
            .foregroundColor(theme.backgroundColor)
            .frame(width: fontSize * 0.9, height: fontSize * 0.9)
            .background(theme.accentColor)
            .clipShape(Circle())
    }
}
