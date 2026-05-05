import Foundation
import FirebaseMessaging
import UIKit
import UserNotifications
import AppTrackingTransparency

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    func requestPremissions(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                print("🔔 Notification permission granted: \(granted)")
                DispatchQueue.main.async() {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([[.banner, .list, .sound]])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: Notification.Name("didRecieveRemoteNotification"), object: nil, userInfo: userInfo)
        completionHandler()  
    }
}
