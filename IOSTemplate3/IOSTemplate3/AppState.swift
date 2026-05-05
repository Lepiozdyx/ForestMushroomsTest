import Foundation

class AppState {
    public static var wasChecked : Bool {
        get {
            return UserDefaults.standard.bool(forKey: "wasChecked")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "wasChecked")
        }
    }

    public static var acceptedURL : String {
        get {
            return UserDefaults.standard.string(forKey: "acceptedURL") ?? ""
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "acceptedURL")
        }
    }
}
