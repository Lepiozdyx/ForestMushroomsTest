import SwiftUI

struct HerbariumScreen: View {
    private enum HerbariumState {
        case empty
        case withData
        case settings
    }

    @State private var state: HerbariumState = .withData
    @State private var selectedItem: HerbariumItem?
    @EnvironmentObject private var store: GameStore
    private let onCloseSettings: (() -> Void)?

    init(openSettings: Bool = false, onCloseSettings: (() -> Void)? = nil) {
        _state = State(initialValue: openSettings ? .settings : .withData)
        self.onCloseSettings = onCloseSettings
    }

    private struct HerbariumItem: Identifiable {
        let id = UUID()
        let imageName: String
        let title: String
        let initialLook: String
        let sporeTest: String
        let geography: String
        let type: String
        let infoCard: String
        let typeColor: Color
        let badge: Badge?
        let borderColor: Color
        let isLocked: Bool
    }

    private enum Badge {
        case found
        case master
    }

    private let gradientTop = Color(red: 27 / 255, green: 74 / 255, blue: 27 / 255)
    private let gradientMiddle = Color(red: 13 / 255, green: 48 / 255, blue: 16 / 255)
    private let gradientBottom = Color(red: 10 / 255, green: 42 / 255, blue: 10 / 255)
    private let gold = Color(red: 1, green: 215 / 255, blue: 0)
    private let green = Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255)

    private var progressValue: CGFloat {
        CGFloat(Double(store.openedMushroomCount) / Double(max(store.mushrooms.count, 1)))
    }

    private var openedCount: Int {
        store.openedMushroomCount
    }

    private var masterCount: Int {
        store.masterMushroomCount
    }

    private var collectionCountText: String {
        "\(store.openedMushroomCount)/\(store.mushrooms.count)"
    }

    private var items: [HerbariumItem] {
        store.mushrooms.map { mushroom in
            let progress = store.progressByMushroom[mushroom.id] ?? MushroomProgress()
            let unlocked = progress.isUnlocked
            return HerbariumItem(
                imageName: mushroom.imageName,
                title: mushroom.displayName,
                initialLook: mushroom.initialLook,
                sporeTest: mushroom.sporePrint,
                geography: mushroom.geography,
                type: mushroom.safety == .edible ? "Edible" : "Poisonous",
                infoCard: mushroom.infoCard,
                typeColor: mushroom.safety == .edible ? green : Color(red: 239 / 255, green: 154 / 255, blue: 154 / 255),
                badge: progress.successfulIdentifications >= 5 ? .master : (unlocked ? .found : nil),
                borderColor: progress.successfulIdentifications >= 5 ? gold : green,
                isLocked: !unlocked
            )
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [gradientTop, gradientMiddle, gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if state == .settings {
                    settingsContent
                } else if let selectedItem {
                    detailContent(for: selectedItem)
                } else {
                    content
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            if state == .settings {
                Button(action: {
                    AppFeedback.playButtonSound()
                    if let onCloseSettings {
                        onCloseSettings()
                    } else {
                        state = .withData
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 0.7)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else if selectedItem == nil {
                Text("Herbarium")
                    .font(AppTypography.fredoka(size: 26))
                    .foregroundStyle(.white)
            } else {
                Button(action: {
                    AppFeedback.playButtonSound()
                    selectedItem = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 0.7)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if state == .settings {
                Text("Settings")
                    .font(AppTypography.fredoka(size: 22))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)
            }

            Spacer()

            if selectedItem == nil && state != .settings {
                Button(action: {
                    AppFeedback.playButtonSound()
                    state = .settings
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 0.7)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 46, height: 46)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 71)
        .background(Color(red: 14 / 255, green: 42 / 255, blue: 14 / 255))
        .zIndex(10)
    }

    private var content: some View {
        GeometryReader { proxy in
            let isSE = proxy.size.height <= 620
            let emptyBottomPadding: CGFloat = isSE ? 110 : 175
            let emptyScale: CGFloat = isSE ? 0.9 : 1

            if state == .empty {
                VStack(spacing: 0) {
                    progressBanner
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    Spacer(minLength: 0)
                    emptyState
                        .scaleEffect(emptyScale)
                        .padding(.bottom, emptyBottomPadding)
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        progressBanner
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        objectsGrid
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                    }
                    .padding(.bottom, 36)
                }
            }
        }
    }

    private var progressBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Collection Progress")
                    .font(AppTypography.fredoka(size: 16))
                    .foregroundStyle(.white)

                Spacer()

                Text(collectionCountText)
                    .font(AppTypography.fredoka(size: 22))
                    .foregroundStyle(gold)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.1))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [green, gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * progressValue, height: 8)
                            .opacity(state == .withData ? 1 : 0)
                    }
                }
                .padding(.top, 12)

            HStack(spacing: 22) {
                statItem(
                    iconAsset: "Icon-12",
                    text: "\(openedCount) Opened",
                    color: Color(red: 165 / 255, green: 214 / 255, blue: 167 / 255)
                )

                statItem(
                    iconAsset: "Icon-13",
                    text: "\(masterCount) Master",
                    color: gold
                )
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20.7)
        .padding(.top, 20.7)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, minHeight: 129, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.22),
                    Color(red: 78 / 255, green: 200 / 255, blue: 78 / 255).opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 223 / 255, green: 196 / 255, blue: 56 / 255), lineWidth: 2.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var objectsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(items) { item in
                herbariumCard(item: item)
            }
        }
        .padding(.bottom, 36)
    }

    private func herbariumCard(item: HerbariumItem) -> some View {
        ZStack(alignment: .topLeading) {
            if item.isLocked {
                Image("Object_Clouse")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 164, height: 219)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(item.borderColor, lineWidth: 0.7)
                    )

                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 164, height: 219)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 131)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 15))

                if let badge = item.badge {
                    badgeView(badge)
                        .padding(.top, 9)
                        .padding(.leading, badge == .master ? 83 : 88)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(AppTypography.fredoka(size: 14))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.type)
                        .font(AppTypography.fredoka(size: 11))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(item.typeColor)
                }
                .padding(.horizontal, 10.7)
                .padding(.bottom, 11)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: 220)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            guard !item.isLocked else { return }
            selectedItem = item
            if let mushroom = store.mushrooms.first(where: { $0.displayName == item.title }) {
                store.markInfoCardViewed(for: mushroom.id)
            }
        }
    }

    private func detailContent(for item: HerbariumItem) -> some View {
        GeometryReader { proxy in
            let isSECompact = proxy.size.height <= 620
            let imageHeight = isSECompact
                ? min(285.0, max(248.0, proxy.size.height * 0.36))
                : min(330.0, max(300.0, proxy.size.height * 0.42))
            let titleSize: CGFloat = isSECompact ? 22 : 26
            let labelSize: CGFloat = isSECompact ? 13 : 14
            let bodySize: CGFloat = isSECompact ? 13 : 14
            let cardPadding: CGFloat = isSECompact ? 13.5 : 16.7

            VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: imageHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.clear, Color(red: 10 / 255, green: 30 / 255, blue: 10 / 255).opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: imageHeight)

                Text(item.title)
                    .font(AppTypography.fredoka(size: titleSize))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, isSECompact ? 16 : 20)
                    .padding(.bottom, isSECompact ? 14 : 20)
            }

            VStack(alignment: .leading, spacing: isSECompact ? 6 : 8) {
                Text("MUSHROOM INFO")
                    .font(AppTypography.fredoka(size: isSECompact ? 12 : 13))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))

                HStack {
                    Text("Status")
                        .font(AppTypography.fredoka(size: labelSize))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    statusBadge(type: item.type, color: item.typeColor)
                }

                infoDivider

                HStack {
                    Text("Spore Print")
                        .font(AppTypography.fredoka(size: labelSize))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sporeColor(for: item.sporeTest))
                            .frame(width: isSECompact ? 12 : 14, height: isSECompact ? 12 : 14)
                        Text(item.sporeTest)
                            .font(AppTypography.fredoka(size: labelSize))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                infoDivider

                HStack(alignment: .top) {
                    Text("Geography")
                        .font(AppTypography.fredoka(size: labelSize))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer(minLength: 10)
                    Text(item.geography)
                        .font(AppTypography.fredoka(size: bodySize))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(isSECompact ? 1 : 2)
                        .minimumScaleFactor(0.8)
                }

                infoDivider

                Text("DESCRIPTION")
                    .font(AppTypography.fredoka(size: isSECompact ? 12 : 13))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.45))

                Text(item.infoCard)
                    .font(AppTypography.fredoka(size: bodySize))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(isSECompact ? 2 : 3)
                    .lineLimit(isSECompact ? 2 : 3)
                    .minimumScaleFactor(0.75)
            }
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.15), lineWidth: 0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, isSECompact ? 12 : 18)
            .padding(.bottom, isSECompact ? 10 : 16)
            .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HAPTICS")
                .font(AppTypography.fredoka(size: 13))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 24)
                .padding(.horizontal, 24.42)

            settingsRow(
                title: "Vibration on Long Press",
                titleColor: .white,
                iconName: "Icon-14",
                iconTint: .white.opacity(0.7),
                iconBackground: .white.opacity(0.08)
            ) {
                Button(action: {
                    AppFeedback.playButtonSound()
                    store.isVibrationEnabled.toggle()
                }) {
                    Image(store.isVibrationEnabled ? "Toggle_on" : "Toggle_off")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24.42)
            .padding(.top, 12)

            Text("DATA")
                .font(AppTypography.fredoka(size: 13))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 24)
                .padding(.horizontal, 24.42)

            settingsRow(
                title: "Reset Progress",
                titleColor: Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255),
                iconName: "trash",
                iconTint: Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255),
                iconBackground: Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255).opacity(0.15)
            ) {
                Button(action: {
                    AppFeedback.playButtonSound()
                    store.resetProgress()
                    selectedItem = nil
                    state = .settings
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24.42)
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
    }

    private func settingsRow<Accessory: View>(
        title: String,
        titleColor: Color,
        iconName: String,
        iconTint: Color,
        iconBackground: Color,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)

                if iconName.hasPrefix("Icon-") {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(iconTint)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(iconTint)
                }
            }

            Text(title)
                .font(AppTypography.fredoka(size: 16))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            accessory()
        }
        .padding(.horizontal, 16.69)
        .frame(height: 69.38)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statusBadge(type: String, color: Color) -> some View {
        Text(type)
            .font(AppTypography.fredoka(size: 14))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(height: 31.4)
            .background(color.opacity(0.13))
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.4), lineWidth: 0.7)
            )
            .clipShape(Capsule())
    }

    private var infoDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
    }

    private func sporeColor(for sporeTest: String) -> Color {
        switch sporeTest {
        case "Dark Brown": return Color(red: 125 / 255, green: 47 / 255, blue: 9 / 255)
        case "Brown": return Color(red: 114 / 255, green: 74 / 255, blue: 37 / 255)
        case "Rusty Brown": return Color(red: 192 / 255, green: 103 / 255, blue: 60 / 255)
        case "White": return .white
        case "Greenish": return Color(red: 92 / 255, green: 170 / 255, blue: 101 / 255)
        case "Pink": return Color(red: 231 / 255, green: 156 / 255, blue: 185 / 255)
        case "Black": return Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255)
        default: return .white.opacity(0.7)
        }
    }

    private func badgeView(_ badge: Badge) -> some View {
        let isMaster = badge == .master
        let text = isMaster ? "MASTER" : "FOUND"
        let width: CGFloat = isMaster ? 73.75 : 68
        let border = isMaster ? gold : Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255)
        let textColor = isMaster ? gold : green
        let bg = isMaster ? Color(red: 79 / 255, green: 67 / 255, blue: 0).opacity(0.25) : Color(red: 19 / 255, green: 69 / 255, blue: 21 / 255).opacity(0.35)
        let iconAsset = isMaster ? "Icon-13" : "Icon-12"

        return HStack(spacing: 4) {
            Image(iconAsset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(textColor)

            Text(text)
                .font(AppTypography.fredoka(size: 10))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 8.7)
        .frame(minWidth: width, minHeight: 22.4, maxHeight: 22.4)
        .background(bg)
        .overlay(
            Capsule()
                .stroke(border, lineWidth: 0.7)
        )
        .clipShape(Capsule())
    }

    private func statItem(iconAsset: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(iconAsset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(color)
                .frame(width: 16, height: 16)

            Text(text)
                .font(AppTypography.fredoka(size: 14))
                .foregroundStyle(color)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 65, height: 65)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 0.88)
                    )

                Image("Group")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }

            Text("No Mushrooms Yet")
                .font(AppTypography.fredoka(size: 16))
                .foregroundStyle(Color(red: 165 / 255, green: 214 / 255, blue: 167 / 255))
                .padding(.top, 5)

            Text("You have not identified any mushrooms yet\nGo to Identification and start exploring!")
                .font(AppTypography.fredoka(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 79 / 255, green: 110 / 255, blue: 81 / 255))
                .lineSpacing(4)
        }
        .frame(width: 271)
    }
}

#Preview {
    HerbariumScreen()
}
