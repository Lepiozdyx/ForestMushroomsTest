import SwiftUI

struct AchievementsScreen: View {
    private enum AchievementsState {
        case inactive
        case active
    }

    private struct Achievement: Identifiable {
        let id: AchievementID
        let title: String
        let description: String
        let icon: String
    }

    private let gradientTop = Color(red: 27 / 255, green: 74 / 255, blue: 27 / 255)
    private let gradientMiddle = Color(red: 13 / 255, green: 48 / 255, blue: 16 / 255)
    private let gradientBottom = Color(red: 10 / 255, green: 42 / 255, blue: 10 / 255)
    @State private var showHerbariumSettings = false
    @EnvironmentObject private var store: GameStore
    @State private var selectedAchievement: Achievement?
    @State private var selectedAchievementUnlocked = true

    private var achievements: [Achievement] {
        store.achievementDefinitions().map { .init(id: $0.id, title: $0.title, description: $0.description, icon: $0.icon) }
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
                if let selectedAchievement {
                    achievementDetails(selectedAchievement, unlocked: selectedAchievementUnlocked)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            banner
                                .padding(.horizontal, 24)
                                .padding(.top, 24)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 12
                            ) {
                                ForEach(achievements) { item in
                                    achievementCard(item)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 48)
                            .padding(.bottom, 24)
                        }
                    }
                }
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
            if selectedAchievement == nil {
                Text("Achievements")
                    .font(AppTypography.fredoka(size: 26))
                    .foregroundStyle(.white)
            } else {
                Button(action: {
                    AppFeedback.playButtonSound()
                    selectedAchievement = nil
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

            if selectedAchievement == nil {
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
            } else {
                Color.clear.frame(width: 46, height: 46)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 71)
        .background(Color(red: 14 / 255, green: 42 / 255, blue: 14 / 255))
    }

    private var banner: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Progress")
                    .font(AppTypography.fredoka(size: 18))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(store.achievementProgressText)
                    .font(AppTypography.fredoka(size: 22))
                    .foregroundStyle(Color(red: 1, green: 215 / 255, blue: 0))
            }

            RoundedRectangle(cornerRadius: 5)
                .fill(.white.opacity(0.1))
                .frame(height: 10)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1, green: 179 / 255, blue: 0), Color(red: 1, green: 215 / 255, blue: 0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * (CGFloat(store.unlockedAchievements.count) / CGFloat(max(AchievementID.allCases.count, 1))), height: 10)
                            .shadow(color: Color(red: 1, green: 215 / 255, blue: 0).opacity(0.5), radius: 8)
                    }
                }
                .padding(.top, 14)
        }
        .padding(.horizontal, 20.69)
        .padding(.vertical, 20)
        .frame(height: 100)
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
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 223 / 255, green: 196 / 255, blue: 56 / 255), lineWidth: 2.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func achievementCard(_ item: Achievement) -> some View {
        let isActive = isAchievementUnlocked(item)

        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isActive ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.15) : .white.opacity(0.06))
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.4) : .white.opacity(0.1), lineWidth: 0.7)
                    )
                    .frame(width: 52, height: 52)

                Image(item.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isActive ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.22))
                    .overlay {
                        Image(item.icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(isActive ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.22))
                            .scaleEffect(1.04)
                    }

                if isActive {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1, green: 215 / 255, blue: 0))
                        Text("✓")
                            .font(AppTypography.fredoka(size: 9))
                            .foregroundStyle(.black)
                    }
                    .frame(width: 16, height: 16)
                    .offset(x: 18, y: 18)
                }
            }
            .padding(.top, 16.69)

            Text(item.title)
                .font(AppTypography.fredoka(size: 13))
                .foregroundStyle(isActive ? .white : .white.opacity(0.28))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 8)

            if isActive {
                Text("Unlocked: \(formattedUnlockDate(for: item.id))")
                    .font(AppTypography.fredoka(size: 10))
                    .foregroundStyle(Color(red: 133 / 255, green: 149 / 255, blue: 42 / 255))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 16)
            } else {
                Text(item.description)
                    .font(AppTypography.fredoka(size: 10))
                    .foregroundStyle(Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(isActive ? .white.opacity(0.08) : .white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.3) : .white.opacity(0.08), lineWidth: 0.7)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            selectedAchievement = item
            selectedAchievementUnlocked = isAchievementUnlocked(item)
        }
    }

    private func achievementDetails(_ item: Achievement, unlocked: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.15) : .white.opacity(0.06))
                        .overlay(
                            Circle()
                                .stroke(unlocked ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.5) : .white.opacity(0.12), lineWidth: 1.4)
                        )
                        .frame(width: 112, height: 112)
                        .shadow(color: (unlocked ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.2) : .clear), radius: 20)

                    Image(item.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundStyle(unlocked ? Color(red: 1, green: 228 / 255, blue: 77 / 255) : .white.opacity(0.2))
                        .overlay {
                            Image(item.icon)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .foregroundStyle(unlocked ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.2))
                        }
                        .shadow(color: (unlocked ? Color(red: 1, green: 215 / 255, blue: 0).opacity(0.35) : .clear), radius: 6)
                }

                HStack(spacing: 6) {
                    Image(systemName: unlocked ? "checkmark.circle" : "lock")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(unlocked ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.35))
                    Text(unlocked ? "Unlocked" : "Locked")
                        .font(AppTypography.fredoka(size: 17))
                        .foregroundStyle(unlocked ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.35))
                }
            }
            .padding(.top, 48)

            VStack(alignment: .leading, spacing: 10) {
                Text("ACHIEVEMENT INFO")
                    .font(AppTypography.fredoka(size: 13))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))

                detailsRow(label: "Name", value: item.title)
                detailsDivider
                detailsRow(
                    label: "Condition",
                    value: conditionText(for: item.description),
                    valueColor: unlocked ? .white : .white.opacity(0.3),
                    multiline: true
                )
                detailsDivider
                detailsRow(
                    label: "Date",
                    value: unlocked ? "Unlocked: \(formattedUnlockDate(for: item.id))" : "Not unlocked yet",
                    valueColor: unlocked ? Color(red: 1, green: 215 / 255, blue: 0) : .white.opacity(0.3)
                )
            }
            .padding(16.7)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: 218)
            .background(.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((unlocked ? Color(red: 1, green: 215 / 255, blue: 0) : .white).opacity(0.35), lineWidth: 0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .padding(.top, 48)

            Spacer(minLength: 0)
        }
    }

    private func detailsRow(
        label: String,
        value: String,
        valueColor: Color = .white,
        multiline: Bool = false
    ) -> some View {
        HStack(alignment: multiline ? .top : .center) {
            Text(label)
                .font(AppTypography.fredoka(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer(minLength: 12)
            Text(value)
                .font(AppTypography.fredoka(size: 15))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(multiline ? 2 : 1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: multiline ? 170 : .infinity, alignment: .trailing)
        }
    }

    private var detailsDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
    }

    private func conditionText(for text: String) -> String {
        if text.hasSuffix(".") { return text }
        return text + "."
    }

    private func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
        store.unlockedAchievements.contains(achievement.id)
    }

    private func formattedUnlockDate(for id: AchievementID) -> String {
        guard let date = store.achievementUnlockedDates[id] else {
            return "Unknown"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    AchievementsScreen()
}
