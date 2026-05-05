import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport
import AppsFlyerLib
import FirebaseAnalytics
import FirebaseMessaging
import FirebaseInstallations
import FirebaseAuth
import AdServices

struct IdentitySnapshot {
    let attToken: String?
    let appsFlyerId: String?
    let appInstanceId: String?
    let uuid: String
    let osVersion: String
    let deviceModel: String
    let bundleId: String?
    let fcmToken: String?
}

final class IdentityCollector {
    func collectAll(attToken: Data, completion: @escaping (IdentitySnapshot) -> Void) {
        var fcmToken: String?
        var appInstanceId: String?
        let group = DispatchGroup()

        group.enter()
        fetchFCMToken(apnsToken: attToken) {
            fcmToken = $0
            group.leave()
        }
        
        group.enter()
        fetchAppInstanceId()
        {
            id in
            appInstanceId = id
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let snapshot = IdentitySnapshot(
                attToken: self.fetchAttToken(),
                appsFlyerId: self.fetchAppsFlyerId(),
                appInstanceId: appInstanceId,
                uuid: (UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString).lowercased(),
                osVersion: UIDevice.current.systemVersion,
                deviceModel: Self.deviceModel(),
                bundleId: Bundle.main.bundleIdentifier,
                fcmToken: fcmToken
            )
            completion(snapshot)
        }
    }
}

// MARK: - Private helpers

private extension IdentityCollector {
    func fetchAttToken() -> String? {
        if let token = try? AAAttribution.attributionToken() {
            return token
        } else {
            return nil
        }
    }
    
    func fetchAppsFlyerId() -> String? {
        AppsFlyerLib.shared().appsFlyerDevKey = AppDelegate.AFDevKey
        AppsFlyerLib.shared().appleAppID = AppDelegate.AppID
        AppsFlyerLib.shared().start()
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }


    func fetchAppInstanceId(completion: @escaping (String?) -> Void) {
        Task {
            do {
                let id = try await Installations.installations().installationID()
                print("AAA \(id)")
                completion(id)
            } catch {
                completion("")
            }
        }
    }

    func fetchFCMToken(apnsToken: Data, completion: @escaping (String?) -> Void) {
        Messaging.messaging().apnsToken = apnsToken
        Messaging.messaging().token { token, error in
            guard error == nil else {
                print("Error fetching FCM token: \(String(describing: error))")
                completion("")
                return
            }
            completion(token)
        }
    }

    static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return deviceModel
    }
}
