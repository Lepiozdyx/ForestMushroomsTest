import SwiftUI
import UIKit

struct IdentificationScreen: View {
    private enum IdentificationState {
        case idle
        case longPressing
        case risk
        case showingResult
        case failedHold
    }

    @EnvironmentObject private var store: GameStore
    @State private var state: IdentificationState = .idle
    @State private var holdStartDate: Date?
    @State private var holdProgress: CGFloat = 0
    @State private var usedSporeCheck = false
    @State private var latestOutcome: IdentificationOutcome?

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let gold = Color(red: 1, green: 215 / 255, blue: 0)

    var body: some View {
        ZStack {
            backgroundLayer
            gradientShadow
            topHeader
            subBar
            bottomButtons
            if state != .showingResult {
                fingerprintOverlay
            }
            resultPopupOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onReceive(timer) { _ in
            guard state == .longPressing, let start = holdStartDate else { return }
            holdProgress = min(Date().timeIntervalSince(start) / 3.0, 1.0)
        }
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 18 / 255, green: 31 / 255, blue: 18 / 255),
                .black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Image(store.currentMushroom.imageName)
                .resizable()
                .scaledToFill()
                .opacity(0.6)
                .allowsHitTesting(false)
        )
        .ignoresSafeArea()
    }

    private var gradientShadow: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.85), location: 0),
                .init(color: .black.opacity(0.3), location: 0.4),
                .init(color: .black.opacity(0.4), location: 0.6),
                .init(color: Color(red: 10 / 255, green: 30 / 255, blue: 10 / 255).opacity(0.95), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(String(format: "%.1f", store.streak))
                    .font(AppTypography.fredoka(size: 20))
            }
            .foregroundStyle(gold)

            Spacer()

            Text("IDENTIFICATION")
                .font(AppTypography.fredoka(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 33)
                .background(Color(red: 31 / 255, green: 34 / 255, blue: 21 / 255))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(gold.opacity(0.6), lineWidth: 0.7)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            HStack {
                Text("\(store.xp)")
                    .font(AppTypography.fredoka(size: 20))
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(gold)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .frame(height: 71, alignment: .top)
        .background(alignment: .top) {
            LinearGradient(
                colors: [.white.opacity(0.1), .white.opacity(0.06), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 71)
            .blur(radius: 1)
            .ignoresSafeArea(edges: .top)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var subBar: some View {
        HStack {
            Text("RISK MULTIPLIER x1.5")
                .foregroundStyle(gold)
            Spacer()
            Text("LEVEL - \(store.levelTitle.uppercased())")
                .foregroundStyle(.white.opacity(0.75))
        }
        .font(AppTypography.fredoka(size: 12))
        .tracking(0.5)
        .padding(.horizontal, 20)
        .frame(height: 30.7)
        .background(.black.opacity(0.4))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 0.7)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 71)
    }

    private var fingerprintOverlay: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(gold.opacity(0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .opacity(state == .longPressing ? 1 : 0)

                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .opacity(state == .longPressing ? 1 : 0)
                    .animation(.linear(duration: 0.08), value: holdProgress)

                Image("Fingerprint")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .contentShape(Circle())
                    .onLongPressGesture(minimumDuration: 3, maximumDistance: 60, pressing: { isPressing in
                        if isPressing {
                            if state != .longPressing {
                                state = .longPressing
                                holdProgress = 0
                                holdStartDate = Date()
                            }
                        } else if state == .longPressing && holdProgress < 1 {
                            state = .failedHold
                            holdProgress = 0
                            holdStartDate = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if state == .failedHold {
                                    state = .idle
                                }
                            }
                        }
                    }) {
                        holdProgress = 1
                        holdStartDate = nil
                        usedSporeCheck = true
                        state = .risk
                        if store.isVibrationEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                .shadow(color: gold.opacity(0.5), radius: 24)
                .allowsHitTesting(state == .idle || state == .longPressing || state == .failedHold)
            }

            if state == .risk {
                Text("SPORE PRINT: \(store.currentMushroom.sporePrint.uppercased())")
                    .font(AppTypography.fredoka(size: 13))
                    .foregroundStyle(Color(red: 125 / 255, green: 47 / 255, blue: 9 / 255))
                    .frame(width: 217, height: 37)
                    .background(.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 125 / 255, green: 47 / 255, blue: 9 / 255).opacity(0.4), lineWidth: 0.7)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text(statusText)
                    .font(AppTypography.fredoka(size: 13))
                    .tracking(0.5)
                    .foregroundStyle(gold)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.bottom, 168)
    }

    private var bottomButtons: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 10 / 255, green: 30 / 255, blue: 10 / 255).opacity(0.9), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            HStack(spacing: 12) {
                identifyButton(
                    title: "EDIBLE",
                    xp: state == .risk ? "+10 XP" : "+20 XP",
                    fill: Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255),
                    isActive: false
                ) {
                    submitGuess(.edible)
                }

                identifyButton(
                    title: "POISONOUS",
                    xp: state == .risk ? "+10 XP" : "+20 XP",
                    fill: Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255),
                    isActive: false
                ) {
                    submitGuess(.poisonous)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .frame(height: 104)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(state == .idle || state == .risk)
    }

    private var resultPopupOverlay: some View {
        Group {
            if state == .showingResult, let latestOutcome {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Text(latestOutcome.isCorrect ? "CORRECT!" : "WRONG!")
                                .font(AppTypography.fredoka(size: 32))
                                .foregroundStyle(latestOutcome.isCorrect ? Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255) : Color(red: 239 / 255, green: 83 / 255, blue: 80 / 255))

                            Spacer()

                            Text(latestOutcome.usedSporeCheck ? "Science Mode" : "Risk Mode")
                                .font(AppTypography.fredoka(size: 13))
                                .foregroundStyle(gold)
                                .padding(.horizontal, 12.7)
                                .frame(height: 33.4)
                                .background(.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.7)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Text(resultMessage(for: latestOutcome))
                            .font(AppTypography.fredoka(size: 16))
                            .foregroundStyle(latestOutcome.isCorrect ? gold : Color(red: 239 / 255, green: 154 / 255, blue: 154 / 255))
                            .padding(.top, 10)

                        Rectangle()
                            .fill(.white.opacity(0.12))
                            .frame(height: 1)
                            .padding(.top, 16)

                        Text(store.currentMushroom.displayName)
                            .font(AppTypography.fredoka(size: 24))
                            .foregroundStyle(.white)
                            .padding(.top, 15)

                        Text(store.currentMushroom.latinName)
                            .font(AppTypography.fredoka(size: 14))
                            .foregroundStyle(Color(red: 165 / 255, green: 214 / 255, blue: 167 / 255))
                            .padding(.top, 1)

                        Text(store.currentMushroom.safety == .edible ? "EDIBLE" : "POISONOUS")
                            .font(AppTypography.fredoka(size: 13))
                            .foregroundStyle(store.currentMushroom.safety == .edible ? Color(red: 102 / 255, green: 187 / 255, blue: 106 / 255) : Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255))
                            .padding(.horizontal, 12.7)
                            .frame(height: 31.4)
                            .background((store.currentMushroom.safety == .edible ? Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255) : Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255)).opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(store.currentMushroom.safety == .edible ? Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255) : Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255), lineWidth: 0.7)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.top, 12)

                        Text(store.currentMushroom.infoCard)
                            .font(AppTypography.fredoka(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.black.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 14)

                        Text("TAP ANYWHERE TO CONTINUE")
                            .font(AppTypography.fredoka(size: 14))
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 17)
                    }
                    .padding(.horizontal, 24.7)
                    .padding(.top, 24.7)
                    .frame(width: 342, height: 377, alignment: .topLeading)
                    .background(.white.opacity(0.04))
                    .background(.ultraThinMaterial.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                latestOutcome.isCorrect
                                    ? Color(red: 67 / 255, green: 160 / 255, blue: 71 / 255).opacity(0.6)
                                    : Color(red: 198 / 255, green: 40 / 255, blue: 40 / 255).opacity(0.6),
                                lineWidth: 3
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    resetForNextRound()
                }
            }
        }
    }

    private func identifyButton(
        title: String,
        xp: String,
        fill: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.fredoka(size: 18))
                    .tracking(1)
                    .foregroundStyle(.white)

                Text(xp)
                    .font(AppTypography.fredoka(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(fill.opacity(isActive ? 1 : 0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(.white.opacity(0.15), lineWidth: 0.7)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .shadow(color: fill.opacity(isActive ? 0.45 : 0.35), radius: isActive ? 18 : 14, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var statusText: String {
        switch state {
        case .idle:
            "PRESS AND HOLD TO IDENTIFY"
        case .longPressing:
            "SCANNING..."
        case .risk:
            "SPORE PRINT: \(store.currentMushroom.sporePrint.uppercased())"
        case .showingResult:
            "RESULT READY"
        case .failedHold:
            "HOLD FOR 3 SECONDS"
        }
    }

    private func submitGuess(_ guess: MushroomSafety) {
        guard state == .idle || state == .risk else { return }
        AppFeedback.playButtonSound()
        latestOutcome = store.identify(as: guess, usedSporeCheck: usedSporeCheck)
        if let latestOutcome, !latestOutcome.isCorrect, store.isVibrationEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        state = .showingResult
    }

    private func resultMessage(for outcome: IdentificationOutcome) -> String {
        if outcome.isCorrect {
            return "+\(outcome.xpAwarded) XP earned"
        }
        if outcome.isFatalMistake {
            return "☠ Fatal mistake"
        }
        return "Wrong identification"
    }

    private func resetForNextRound() {
        state = .idle
        holdProgress = 0
        holdStartDate = nil
        usedSporeCheck = false
        latestOutcome = nil
        store.refreshCurrentMushroom()
    }
}

#Preview {
    IdentificationScreen()
}
