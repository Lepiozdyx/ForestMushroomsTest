import SwiftUI

struct StatisticsScreen: View {
    private enum StatisticsState {
        case empty
        case withData
    }

    private let gradientTop = Color(red: 27 / 255, green: 74 / 255, blue: 27 / 255)
    private let gradientMiddle = Color(red: 13 / 255, green: 48 / 255, blue: 16 / 255)
    private let gradientBottom = Color(red: 10 / 255, green: 42 / 255, blue: 10 / 255)
    @State private var showHerbariumSettings = false
    @EnvironmentObject private var store: GameStore
    private var isSECompact: Bool { UIScreen.main.bounds.height <= 700 }

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
                if store.totalAttempts == 0 {
                    emptyState
                } else {
                    dataState
                }
                Spacer(minLength: 0)
            }
        }
        .fullScreenCover(isPresented: $showHerbariumSettings) {
            HerbariumScreen(openSettings: true) {
                showHerbariumSettings = false
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Statistics")
                .font(AppTypography.fredoka(size: 26))
                .foregroundStyle(.white)

            Spacer()

            Button(action: {
                AppFeedback.playButtonSound()
                showHerbariumSettings = true
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
        }
        .padding(.horizontal, 24)
        .frame(height: 71)
        .background(Color(red: 14 / 255, green: 42 / 255, blue: 14 / 255))
    }

    private var dataState: some View {
        VStack(spacing: 0) {
            profileBanner
                .padding(.horizontal, 24)
                .padding(.top, isSECompact ? 16 : 24)

            Text("METRICS")
                .font(AppTypography.fredoka(size: 13))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, isSECompact ? 16 : 24)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                metricCard(
                    value: "\(store.accuracyPercent)%",
                    title: "Identification Accuracy",
                    border: Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255),
                    tint: Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255),
                    icon: "target",
                    compact: isSECompact
                )
                metricCard(
                    value: "\(store.sporeCheckPercent)%",
                    title: "Spore Check Rate",
                    border: Color(red: 100 / 255, green: 181 / 255, blue: 246 / 255),
                    tint: Color(red: 100 / 255, green: 181 / 255, blue: 246 / 255),
                    icon: "eye",
                    compact: isSECompact
                )
                metricCard(
                    value: "\(store.totalEncountered)",
                    title: "Total Mushrooms Encountered",
                    border: Color(red: 1, green: 215 / 255, blue: 0),
                    tint: Color(red: 1, green: 215 / 255, blue: 0),
                    icon: "Icon-17",
                    compact: isSECompact
                )
                metricCard(
                    value: "\(store.fatalMistakes)",
                    title: "Fatal Mistakes",
                    border: Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255),
                    tint: Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255),
                    icon: "Icon-18",
                    compact: isSECompact
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
    }

    private var profileBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MYCOLOGIST PROFILE")
                    .font(AppTypography.fredoka(size: 13))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text(store.levelTitle)
                    .font(AppTypography.fredoka(size: 14))
                    .foregroundStyle(Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255))
                    .padding(.horizontal, 14.7)
                    .frame(height: 33.4)
                    .background(Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255).opacity(0.133))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255).opacity(0.4), lineWidth: 0.7)
                    )
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(store.xp)")
                    .font(AppTypography.fredoka(size: 40))
                Text("XP")
                    .font(AppTypography.fredoka(size: 20))
                    .baselineOffset(2)
                    .opacity(0.55)
            }
            .foregroundStyle(Color(red: 1, green: 215 / 255, blue: 0))
            .padding(.top, 8)

            HStack {
                Text("\(store.levelTitle) → Expert")
                    .font(AppTypography.fredoka(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(store.xp) / \(store.profileProgressTarget) XP")
                    .font(AppTypography.fredoka(size: 12))
                    .foregroundStyle(Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255))
            }
            .padding(.top, 10)

            RoundedRectangle(cornerRadius: 5)
                .fill(.white.opacity(0.1))
                .frame(height: 10)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255),
                                        Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255).opacity(0.733)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * store.profileProgressValue, height: 10)
                            .shadow(color: Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255).opacity(0.4), radius: 8)
                    }
                }
                .padding(.top, 8)
        }
        .padding(.horizontal, 20.7)
        .padding(.vertical, isSECompact ? 14 : 20.69)
        .frame(height: isSECompact ? 154 : 176)
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
                .stroke(Color(red: 223 / 255, green: 196 / 255, blue: 56 / 255), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metricCard(
        value: String,
        title: String,
        border: Color,
        tint: Color,
        icon: String,
        compact: Bool
    ) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.133))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tint.opacity(0.267), lineWidth: 0.7)
                    )
                    .frame(width: 40, height: 40)

                if icon.hasPrefix("Icon-") {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(tint)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(tint)
                }
            }
            .padding(.top, compact ? 6 : 10)

            Text(value)
                .font(AppTypography.fredoka(size: compact ? 24 : 30))
                .foregroundStyle(.white)
                .padding(.top, compact ? 6 : 12)

            Text(title)
                .font(AppTypography.fredoka(size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(width: 135)
                .padding(.top, compact ? 5 : 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 124 : 142)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(border, lineWidth: 0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

                Image("Vector")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 39.6, height: 39.6)
            }

            Text("No Statistics Yet")
                .font(AppTypography.fredoka(size: 16))
                .foregroundStyle(Color(red: 165 / 255, green: 214 / 255, blue: 167 / 255))
                .padding(.top, 5)

            Text("Your stats will appear here after\nYou identify your first mushroom")
                .font(AppTypography.fredoka(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 79 / 255, green: 110 / 255, blue: 81 / 255))
                .lineSpacing(4)
        }
        .frame(width: 208)
        .padding(.top, 270)
    }
}

#Preview {
    StatisticsScreen()
}
