import SwiftUI

enum AppTypography {
    static func fredoka(size: CGFloat) -> Font {
        .custom("FredokaOne-Regular", size: size)
    }
}

struct MainScreen: View {
    @State private var selectedTab: AppTab = .identification
    @StateObject private var store = GameStore()

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedTab.screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 80)

            BottomNavigationBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(store)
    }
}

private enum AppTab: CaseIterable, Identifiable {
    case identification
    case herbarium
    case statistics
    case achievements

    var id: Self { self }

    var title: String {
        switch self {
        case .identification:
            "Identification"
        case .herbarium:
            "Herbarium"
        case .statistics:
            "Statistics"
        case .achievements:
            "Achievements"
        }
    }

    var assetName: String {
        switch self {
        case .identification:
            "Icon-39"
        case .herbarium:
            "Icon-40"
        case .statistics:
            "Icon-41"
        case .achievements:
            "Icon-42"
        }
    }

    @ViewBuilder
    var screen: some View {
        switch self {
        case .identification:
            IdentificationScreen()
        case .herbarium:
            HerbariumScreen()
        case .statistics:
            StatisticsScreen()
        case .achievements:
            AchievementsScreen()
        }
    }
}

private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(AppTypography.fredoka(size: 28))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: -25) {
            ForEach(AppTab.allCases) { tab in
                BottomNavigationItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    AppFeedback.playButtonSound()
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(red: 10 / 255, green: 30 / 255, blue: 10 / 255))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 0.7)
        }
    }
}

private struct BottomNavigationItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void
    private let selectedGold = Color(red: 1, green: 215 / 255, blue: 0)

    private var iconTintColor: Color {
        isSelected ? selectedGold : .white.opacity(0.15)
    }

    private var textTintColor: Color {
        isSelected ? selectedGold : .white.opacity(0.15)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Image(tab.assetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(iconTintColor)

                    if isSelected {
                        Image(tab.assetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(selectedGold)
                            .opacity(0.95)
                            .scaleEffect(1.06)
                    }
                }
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedGold.opacity(0.15))
                    }
                }

                Text(tab.title)
                    .font(AppTypography.fredoka(size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(textTintColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .padding(.top, 1)
            .padding(.bottom, 9)
            .padding(.horizontal, 0)
        }
        .buttonStyle(.plain)
    }
}
#Preview{MainScreen()}
