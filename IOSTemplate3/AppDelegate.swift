import SwiftUI
import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let appInitializer = AppInitializer()
    static let AppID = "6764538491"
    static let AFDevKey = "P8Cmc5f5JjkNjQ3haoGbWS"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        
        if AppSettingsManager.HardcodedUrl != "" {
            onDecided(url: AppSettingsManager.HardcodedUrl)
            return true
        }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        if AppState.wasChecked {
            if AppState.acceptedURL != "" {
                self.onAccepted(url: AppState.acceptedURL)
            } else {
                self.onDeclined()
            }
            return true
        }
        
        requestPremissions(application: application)
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("APNS token success:\n\(deviceToken)")
        appInitializer.InitializeApp(attToken: deviceToken, callback: onDecided )
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNS token error:\n\(error.localizedDescription)")
        onDeclined()
    }
    
    func onDecided(url: String) {
        AppState.wasChecked = true
        AppState.acceptedURL = url
        
        DispatchQueue.main.async() {
            if url != "" {
                self.onAccepted(url: url)
            } else {
                self.onDeclined()
            }
        }
    }
    
    func onAccepted(url: String) {
        let webView = WebViewView()
        let contentView = CustomHostingController(rootView: webView)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = contentView
        OrientationHelper.orientaionMask = UIInterfaceOrientationMask.all
        OrientationHelper.isAutoRotationEnabled = true
        self.window?.makeKeyAndVisible()
        webView.loadURL(url: url)
    }
    
    func onDeclined() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let root = CustomHostingController(rootView: MainScreen())
        
        window.rootViewController = root
        self.window = window
        
        OrientationHelper.orientaionMask = UIInterfaceOrientationMask.portrait
        OrientationHelper.isAutoRotationEnabled = false
        window.makeKeyAndVisible()
    }
}

class CustomHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Allow all orientations
        return OrientationHelper.orientaionMask
    }

    override var shouldAutorotate: Bool {
        // Enable auto-rotation
        return OrientationHelper.isAutoRotationEnabled
    }
}

class CustomNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationHelper.orientaionMask
    }

    override var shouldAutorotate: Bool {
        return OrientationHelper.isAutoRotationEnabled
    }
}

class OrientationHelper
{
    public static var orientaionMask: UIInterfaceOrientationMask = .portrait
    public static var isAutoRotationEnabled: Bool = false
}
