import AudioToolbox

enum AppFeedback {
    static func playButtonSound() {
        AudioServicesPlaySystemSound(1104)
    }
}
