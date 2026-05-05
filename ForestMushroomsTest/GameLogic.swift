import Foundation
import SwiftUI
import Combine

enum MushroomSafety: String, Codable {
    case edible
    case poisonous
}

struct Mushroom: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let latinName: String
    let initialLook: String
    let sporePrint: String
    let geography: String
    let infoCard: String
    let safety: MushroomSafety
    let imageName: String
}

struct MushroomProgress: Codable, Hashable {
    var successfulIdentifications: Int = 0
    var isUnlocked: Bool = false
    var mistakes: Int = 0
}

struct SessionProgress: Codable {
    var attempts: Int = 0
    var correct: Int = 0
}

enum AchievementID: String, CaseIterable, Identifiable {
    case firstStep
    case cautious
    case intuition
    case noMistakes
    case collector
    case fullHerbarium
    case sporeExpert
    case whiteDanger
    case greenLight
    case riskManager
    case scientist
    case weekOfPractice
    case monthOfSilence
    case noDeaths
    case recidivist
    case speedster
    case attentive
    case mycologist
    case perfectionist
    case forestLegend

    var id: String { rawValue }
}

struct AchievementDefinition: Identifiable {
    let id: AchievementID
    let title: String
    let description: String
    let icon: String
}

struct IdentificationOutcome {
    let isCorrect: Bool
    let usedSporeCheck: Bool
    let xpAwarded: Int
    let isFatalMistake: Bool
}

final class GameStore: ObservableObject {
    @Published private(set) var mushrooms: [Mushroom] = []
    @Published private(set) var currentMushroom: Mushroom
    @Published private(set) var xp: Int = 0
    @Published private(set) var streak: Double = 0
    @Published private(set) var maxStreak: Double = 0
    @Published private(set) var totalAttempts: Int = 0
    @Published private(set) var correctAttempts: Int = 0
    @Published private(set) var sporeChecks: Int = 0
    @Published private(set) var fatalMistakes: Int = 0
    @Published private(set) var totalEncountered: Int = 0
    @Published private(set) var riskXP: Int = 0
    @Published private(set) var interpretedSpores: Int = 0
    @Published private(set) var consecutiveSporeChecks: Int = 0
    @Published private(set) var consecutiveNoMistakes: Int = 0
    @Published private(set) var noFatalMistakesRun: Int = 0
    @Published private(set) var session = SessionProgress()
    @Published private(set) var viewedCards: Set<String> = []
    @Published private(set) var encounteredMushrooms: Set<String> = []
    @Published private(set) var progressByMushroom: [String: MushroomProgress] = [:]
    @Published private(set) var unlockedAchievements: Set<AchievementID> = []
    @Published private(set) var achievementUnlockedDates: [AchievementID: Date] = [:]
    @Published var isVibrationEnabled: Bool = true {
        didSet {
            saveProgress()
        }
    }

    private var sameMushroomMistakeStreak: [String: Int] = [:]
    private var currentShownAt: Date = Date()
    private let storageKey = "forest_mushrooms_game_state_v1"

    private struct StoredState: Codable {
        let currentMushroomID: String
        let xp: Int
        let streak: Double
        let maxStreak: Double
        let totalAttempts: Int
        let correctAttempts: Int
        let sporeChecks: Int
        let fatalMistakes: Int
        let totalEncountered: Int
        let riskXP: Int
        let interpretedSpores: Int
        let consecutiveSporeChecks: Int
        let consecutiveNoMistakes: Int
        let noFatalMistakesRun: Int
        let session: SessionProgress
        let viewedCards: [String]
        let encounteredMushrooms: [String]
        let progressByMushroom: [String: MushroomProgress]
        let unlockedAchievements: [String]
        let sameMushroomMistakeStreak: [String: Int]
        let isVibrationEnabled: Bool
        let achievementUnlockedDates: [String: TimeInterval]
    }

    init() {
        mushrooms = Self.defaultMushrooms
        currentMushroom = Self.defaultMushrooms[0]
        Self.defaultMushrooms.forEach { progressByMushroom[$0.id] = MushroomProgress() }
        if !loadProgress() {
            refreshCurrentMushroom()
        }
    }

    var levelTitle: String {
        switch xp {
        case ..<1000: return "Beginner"
        case ..<2500: return "Expert"
        default: return "Mycologist"
        }
    }

    var accuracyPercent: Int {
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(correctAttempts) / Double(totalAttempts) * 100).rounded())
    }

    var sporeCheckPercent: Int {
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(sporeChecks) / Double(totalAttempts) * 100).rounded())
    }

    var openedMushroomCount: Int {
        progressByMushroom.values.filter(\.isUnlocked).count
    }

    var masterMushroomCount: Int {
        progressByMushroom.values.filter { $0.successfulIdentifications >= 5 }.count
    }

    var achievementProgressText: String {
        "\(unlockedAchievements.count)/\(AchievementID.allCases.count) unlocked"
    }

    var profileProgressTarget: Int {
        levelTitle == "Beginner" ? 1000 : (levelTitle == "Expert" ? 2500 : 5000)
    }

    var profileProgressValue: Double {
        min(Double(xp) / Double(profileProgressTarget), 1)
    }

    func currentMushroomShown() {
        currentShownAt = Date()
    }

    func identify(as guess: MushroomSafety, usedSporeCheck: Bool) -> IdentificationOutcome {
        let mushroom = currentMushroom
        encounteredMushrooms.insert(mushroom.id)
        totalEncountered = encounteredMushrooms.count
        totalAttempts += 1
        session.attempts += 1

        if usedSporeCheck {
            sporeChecks += 1
            interpretedSpores += 1
            consecutiveSporeChecks += 1
        } else {
            consecutiveSporeChecks = 0
        }

        let correct = guess == mushroom.safety
        var awardedXP = 0
        var isFatalMistake = false

        if correct {
            correctAttempts += 1
            session.correct += 1
            var baseXP = usedSporeCheck ? 10 : 20
            if streak >= 5 {
                baseXP = Int((Double(baseXP) * 1.5).rounded())
            }
            awardedXP = baseXP
            xp += awardedXP
            if !usedSporeCheck {
                riskXP += awardedXP
            }
            streak += 1
            maxStreak = max(maxStreak, streak)
            consecutiveNoMistakes += 1
            noFatalMistakesRun += 1

            var progress = progressByMushroom[mushroom.id] ?? MushroomProgress()
            progress.successfulIdentifications += 1
            progress.isUnlocked = true
            progressByMushroom[mushroom.id] = progress
        } else {
            if usedSporeCheck {
                streak = max(0, streak - 0.5)
            } else {
                streak = max(0, streak - 1)
            }
            consecutiveNoMistakes = 0
            if !usedSporeCheck, mushroom.safety == .poisonous, guess == .edible {
                fatalMistakes += 1
                noFatalMistakesRun = 0
                isFatalMistake = true
            } else {
                noFatalMistakesRun += 1
            }

            var progress = progressByMushroom[mushroom.id] ?? MushroomProgress()
            progress.mistakes += 1
            progressByMushroom[mushroom.id] = progress
            sameMushroomMistakeStreak[mushroom.id, default: 0] += 1
        }

        if correct {
            sameMushroomMistakeStreak[mushroom.id] = 0
        }

        evaluateAchievements(lastCorrect: correct, usedSporeCheck: usedSporeCheck)
        saveProgress()
        return IdentificationOutcome(isCorrect: correct, usedSporeCheck: usedSporeCheck, xpAwarded: awardedXP, isFatalMistake: isFatalMistake)
    }

    func markInfoCardViewed(for mushroomID: String) {
        viewedCards.insert(mushroomID)
        evaluateAchievements(lastCorrect: true, usedSporeCheck: false)
        saveProgress()
    }

    func refreshCurrentMushroom() {
        currentMushroom = mushrooms.randomElement() ?? mushrooms[0]
        currentMushroomShown()
        saveProgress()
    }

    func resetProgress() {
        xp = 0
        streak = 0
        maxStreak = 0
        totalAttempts = 0
        correctAttempts = 0
        sporeChecks = 0
        fatalMistakes = 0
        totalEncountered = 0
        riskXP = 0
        interpretedSpores = 0
        consecutiveSporeChecks = 0
        consecutiveNoMistakes = 0
        noFatalMistakesRun = 0
        session = SessionProgress()
        viewedCards = []
        encounteredMushrooms = []
        unlockedAchievements = []
        achievementUnlockedDates = [:]
        sameMushroomMistakeStreak = [:]
        progressByMushroom = [:]
        mushrooms.forEach { progressByMushroom[$0.id] = MushroomProgress() }
        refreshCurrentMushroom()
        saveProgress()
    }

    func achievementDefinitions() -> [AchievementDefinition] {
        [
            .init(id: .firstStep, title: "First Step", description: "Identify your first mushroom", icon: "Icon-43"),
            .init(id: .cautious, title: "Cautious", description: "Make 10 spore checks in a row", icon: "Icon-44"),
            .init(id: .intuition, title: "Intuition", description: "Identify 5 mushrooms without checking spores", icon: "Vector-2"),
            .init(id: .noMistakes, title: "No Mistakes", description: "Identify 10 mushrooms in a row without errors", icon: "Vector-3"),
            .init(id: .collector, title: "Collector", description: "Open 10 mushrooms in the Herbarium", icon: "Icon-45"),
            .init(id: .fullHerbarium, title: "Full Herbarium", description: "Open all 30 mushrooms in the collection", icon: "Icon-46"),
            .init(id: .sporeExpert, title: "Spore Expert", description: "Correctly interpret 50 spore print colors", icon: "Icon-47"),
            .init(id: .whiteDanger, title: "White Danger", description: "Correctly identify Death Cap 5 times", icon: "Icon-48"),
            .init(id: .greenLight, title: "Green Light", description: "Correctly identify Chlorophyllum 5 times", icon: "Icon-49"),
            .init(id: .riskManager, title: "Risk Manager", description: "Earn 1000 XP through Risk Mode", icon: "Icon-50"),
            .init(id: .scientist, title: "Scientist", description: "Open all info cards in the Herbarium", icon: "Icon-51"),
            .init(id: .weekOfPractice, title: "Week of Practice", description: "Open the app 7 days in a row", icon: "Icon-52"),
            .init(id: .monthOfSilence, title: "Month of Silence", description: "Open the app 30 days in a row", icon: "Icon-53"),
            .init(id: .noDeaths, title: "No Deaths", description: "Identify 50 mushrooms without fatal mistakes", icon: "Icon-54"),
            .init(id: .recidivist, title: "Recidivist", description: "Make a mistake on the same mushroom 3 times", icon: "Icon-55"),
            .init(id: .speedster, title: "Speedster", description: "Identify a mushroom in under 5 seconds", icon: "Icon-56"),
            .init(id: .attentive, title: "Attentive", description: "Notice the difference between Oyster and Galerina", icon: "Icon-57"),
            .init(id: .mycologist, title: "Mycologist", description: "Reach the maximum profile level", icon: "Icon-58"),
            .init(id: .perfectionist, title: "Perfectionist", description: "Get 100% accuracy in a session of 10 mushrooms", icon: "Icon-59"),
            .init(id: .forestLegend, title: "Forest Legend", description: "Unlock all 20 achievements", icon: "Icon-60")
        ]
    }

    private func evaluateAchievements(lastCorrect: Bool, usedSporeCheck: Bool) {
        func unlock(_ id: AchievementID) {
            if !unlockedAchievements.contains(id) {
                achievementUnlockedDates[id] = Date()
            }
            unlockedAchievements.insert(id)
        }

        if totalAttempts >= 1 { unlock(.firstStep) }
        if consecutiveSporeChecks >= 10 { unlock(.cautious) }
        if riskXP >= 1000 { unlock(.riskManager) }
        if consecutiveNoMistakes >= 10 { unlock(.noMistakes) }
        if openedMushroomCount >= 10 { unlock(.collector) }
        if openedMushroomCount >= 30 { unlock(.fullHerbarium) }
        if interpretedSpores >= 50 { unlock(.sporeExpert) }
        if noFatalMistakesRun >= 50 { unlock(.noDeaths) }
        if sameMushroomMistakeStreak.values.contains(where: { $0 >= 3 }) { unlock(.recidivist) }
        if levelTitle == "Mycologist" { unlock(.mycologist) }
        if viewedCards.count == mushrooms.count { unlock(.scientist) }

        if let deathCap = progressByMushroom["death_cap"], deathCap.successfulIdentifications >= 5 {
            unlock(.whiteDanger)
        }
        if let chlorophyllum = progressByMushroom["chlorophyllum_molybdites"], chlorophyllum.successfulIdentifications >= 5 {
            unlock(.greenLight)
        }
        if let galerina = progressByMushroom["galerina_marginata"], galerina.successfulIdentifications >= 1 {
            unlock(.attentive)
        }
        if session.attempts >= 10, session.correct == session.attempts {
            unlock(.perfectionist)
        }
        if lastCorrect, !usedSporeCheck, Date().timeIntervalSince(currentShownAt) <= 5 {
            unlock(.speedster)
        }
        if unlockedAchievements.count == AchievementID.allCases.count - 1 {
            unlock(.forestLegend)
        }
    }

    private static let defaultMushrooms: [Mushroom] = [
        .init(
            id: "field_mushroom",
            displayName: "Field Mushroom",
            latinName: "Agaricus campestris",
            initialLook: "White cap, pink gills",
            sporePrint: "Dark Brown",
            geography: "Meadows and open fields. Europe and North America.",
            infoCard: "Pleasant anise scent. Dark spore print unlike poisonous look-alikes. Grows in meadows.",
            safety: .edible,
            imageName: "Image-1"
        ),
        .init(
            id: "death_cap",
            displayName: "Death Cap",
            latinName: "Amanita phalloides",
            initialLook: "Olive cap, stem ring",
            sporePrint: "White",
            geography: "Deciduous and mixed forests.",
            infoCard: "Deadly poisonous. Spore print is always white. Found in deciduous and mixed forests.",
            safety: .poisonous,
            imageName: "Image-2"
        ),
        .init(
            id: "summer_oyster",
            displayName: "Summer Honey Fungus",
            latinName: "Kuehneromyces mutabilis",
            initialLook: "Brown cap, clustered growth",
            sporePrint: "Brown",
            geography: "Rotting hardwood in temperate areas.",
            infoCard: "A good edible mushroom. Warm brown spore print. Grows on decaying hardwood.",
            safety: .edible,
            imageName: "Image-3"
        ),
        .init(
            id: "galerina_marginata",
            displayName: "Funeral Bell",
            latinName: "Galerina marginata",
            initialLook: "Honey-like look, rusty tone",
            sporePrint: "Rusty Brown",
            geography: "Conifer stumps and damp woods.",
            infoCard: "Contains dangerous toxins. Rusty-brown spore print is the key marker. Grows on conifer stumps.",
            safety: .poisonous,
            imageName: "Image-4"
        ),
        .init(
            id: "green_russula",
            displayName: "Green Russula",
            latinName: "Russula virescens",
            initialLook: "Flat greenish cap",
            sporePrint: "White",
            geography: "Birch and oak forests.",
            infoCard: "Flesh is brittle. Spore print is pure white. Common in birch and oak forests.",
            safety: .edible,
            imageName: "Image-5"
        ),
        .init(
            id: "parasol",
            displayName: "Parasol Mushroom",
            latinName: "Macrolepiota procera",
            initialLook: "Large scaly cap",
            sporePrint: "White",
            geography: "Forest edges and light woods.",
            infoCard: "Large mushroom with a chicken-like taste. Pure white spore print. Likes forest edges.",
            safety: .edible,
            imageName: "Image-6"
        ),
        .init(
            id: "chlorophyllum_molybdites",
            displayName: "Chlorophyllum Molybdites",
            latinName: "Chlorophyllum molybdites",
            initialLook: "Parasol-like, gray tone",
            sporePrint: "Greenish",
            geography: "Lawns and grassy areas.",
            infoCard: "Strong gastrointestinal toxin. Main marker is a rare green spore print. Grows on lawns.",
            safety: .poisonous,
            imageName: "Image-7"
        ),
        .init(
            id: "silky_rosegill",
            displayName: "Silky Rosegill",
            latinName: "Volvariella bombycina",
            initialLook: "Silky cap, tree-growing",
            sporePrint: "Pink",
            geography: "Old tree hollows and trunks.",
            infoCard: "A beautiful mushroom with a volva at the base. Pink spore print. Often in old tree hollows.",
            safety: .edible,
            imageName: "Image-8"
        ),
        .init(
            id: "entoloma_sinuatum",
            displayName: "Entoloma Sinuatum",
            latinName: "Entoloma sinuatum",
            initialLook: "Large gray cap, rolled edge",
            sporePrint: "Pink",
            geography: "Deciduous forests.",
            infoCard: "Causes severe poisoning. Pink spores like some edible species. Grows in deciduous forests.",
            safety: .poisonous,
            imageName: "Image-9"
        ),
        .init(
            id: "shaggy_inkcap",
            displayName: "Shaggy Inkcap",
            latinName: "Coprinus comatus",
            initialLook: "Tall shaggy cylindrical cap",
            sporePrint: "Black",
            geography: "Rich soils and pastures.",
            infoCard: "Edible only when young. Black ink-like spore print. Grows on rich soils and pastures.",
            safety: .edible,
            imageName: "Image-10"
        )
    ]

    private func saveProgress() {
        let state = StoredState(
            currentMushroomID: currentMushroom.id,
            xp: xp,
            streak: streak,
            maxStreak: maxStreak,
            totalAttempts: totalAttempts,
            correctAttempts: correctAttempts,
            sporeChecks: sporeChecks,
            fatalMistakes: fatalMistakes,
            totalEncountered: totalEncountered,
            riskXP: riskXP,
            interpretedSpores: interpretedSpores,
            consecutiveSporeChecks: consecutiveSporeChecks,
            consecutiveNoMistakes: consecutiveNoMistakes,
            noFatalMistakesRun: noFatalMistakesRun,
            session: session,
            viewedCards: Array(viewedCards),
            encounteredMushrooms: Array(encounteredMushrooms),
            progressByMushroom: progressByMushroom,
            unlockedAchievements: unlockedAchievements.map(\.rawValue),
            sameMushroomMistakeStreak: sameMushroomMistakeStreak,
            isVibrationEnabled: isVibrationEnabled,
            achievementUnlockedDates: Dictionary(
                uniqueKeysWithValues: achievementUnlockedDates.map { ($0.key.rawValue, $0.value.timeIntervalSince1970) }
            )
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    @discardableResult
    private func loadProgress() -> Bool {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(StoredState.self, from: data)
        else {
            return false
        }

        xp = state.xp
        streak = state.streak
        maxStreak = state.maxStreak
        totalAttempts = state.totalAttempts
        correctAttempts = state.correctAttempts
        sporeChecks = state.sporeChecks
        fatalMistakes = state.fatalMistakes
        riskXP = state.riskXP
        interpretedSpores = state.interpretedSpores
        consecutiveSporeChecks = state.consecutiveSporeChecks
        consecutiveNoMistakes = state.consecutiveNoMistakes
        noFatalMistakesRun = state.noFatalMistakesRun
        session = state.session
        viewedCards = Set(state.viewedCards)
        encounteredMushrooms = Set(state.encounteredMushrooms)
        totalEncountered = max(state.totalEncountered, encounteredMushrooms.count)
        progressByMushroom = state.progressByMushroom
        sameMushroomMistakeStreak = state.sameMushroomMistakeStreak
        isVibrationEnabled = state.isVibrationEnabled

        unlockedAchievements = Set(
            state.unlockedAchievements.compactMap { AchievementID(rawValue: $0) }
        )
        achievementUnlockedDates = Dictionary(
            uniqueKeysWithValues: state.achievementUnlockedDates.compactMap { key, value in
                guard let id = AchievementID(rawValue: key) else { return nil }
                return (id, Date(timeIntervalSince1970: value))
            }
        )

        if let storedCurrent = mushrooms.first(where: { $0.id == state.currentMushroomID }) {
            currentMushroom = storedCurrent
        } else {
            currentMushroom = mushrooms.randomElement() ?? mushrooms[0]
        }
        currentMushroomShown()
        return true
    }
}
