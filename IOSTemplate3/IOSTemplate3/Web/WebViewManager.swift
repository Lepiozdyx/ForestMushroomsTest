
import SwiftUI
import WebKit
import Foundation

struct WebViewManager: UIViewRepresentable, Identifiable {
    @State var webView: WKWebView
    let configuration: WKWebViewConfiguration
    let id = UUID()
    var openInNewTabHandler: ((WebViewManager) -> Void)?
    var closeWebViewHandler: (() -> Void)?
    var coordinator: Coordinator?
    
    init(configuration: WKWebViewConfiguration? = nil, wkWebView: WKWebView? = nil) {
        self.configuration = configuration ?? WKWebViewConfiguration()
        self.configuration.allowsInlineMediaPlayback = true
        self.configuration.allowsPictureInPictureMediaPlayback = true
        self.configuration.allowsAirPlayForMediaPlayback = true
        self.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let userContentController = WKUserContentController()
        self.configuration.userContentController = userContentController
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        self.configuration.defaultWebpagePreferences = preferences
        self.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = wkWebView ?? WKWebView(frame: .zero, configuration: self.configuration)
        coordinator = Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.parent = self
        configure(webView, with: context.coordinator)
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        return coordinator ?? Coordinator(self)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    /// Configures the shared WView instance and wires delegate callbacks.
    func configure(_ webView: WKWebView, with coordinator: Coordinator) {
        webView.navigationDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.isInspectable = true
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.uiDelegate = coordinator
        // Replace previously added custom edge-pan gestures to avoid duplicates.
        webView.gestureRecognizers?
            .filter { $0 is EdgePanWithWebRef }
            .forEach { webView.removeGestureRecognizer($0) }
        let edgePan = EdgePanWithWebRef(target: coordinator, action: #selector(Coordinator.handleBackEdgePan(_:)))
        edgePan.webView = webView
        edgePan.edges = .left
        edgePan.delegate = coordinator
        webView.addGestureRecognizer(edgePan)
        webView.customUserAgent = "Version/17.2 Mobile/15E148 Safari/604.1"
    }

    /// Starts loading the provided URL and sets up JS bridge callbacks.
    func loadURL(url: URL) {
        webView.load(URLRequest(url: url))
    }
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let onComplete: ([URL]?) -> Void

    init(onComplete: @escaping ([URL]?) -> Void) {
        self.onComplete = onComplete
        super.init()
    }

    /// Forwards picked file URLs back to the originating handler.
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
        onComplete(urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
        onComplete(nil)
    }
}


class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
    var parent: WebViewManager
    private var retryCount = 0
    private let maxRetries = 3
    
    init(_ parent: WebViewManager) {
        self.parent = parent
        super.init()
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {}
    
    func topViewController(
        from root: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        guard let root = root else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        if let nav = top as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        
        if let tab = top as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        
        return top
    }
}

// Handling multi-tab cases
extension Coordinator {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.targetFrame?.isMainFrame != false else {
            decisionHandler(.allow)
            return
        }
        
        if let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased() {
            let inAppSchemes: Set<String> = ["http", "https", "about", "data", "file", "blob"]
            
            if !inAppSchemes.contains(scheme) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let childManager = WebViewManager(configuration: configuration)
        childManager.configure(childManager.webView, with: self)
        parent.openInNewTabHandler?(childManager)
        return childManager.webView
    }
}

// Handling navigation events
extension Coordinator {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Navigation started for URL: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Navigation finished successfully, url is \(webView.url)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation failed: \(error)")
    }
}

// Alerts handling
extension Coordinator {
    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))

        topViewController()?.present(alertController, animated: true, completion: nil)
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        topViewController()?.present(alertController, animated: true, completion: nil)
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        topViewController()?.present(alertController, animated: true, completion: nil)
    }
}

// Handling back tab navigation swipes
extension Coordinator {
    @objc func handleBackEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard let edgePan = gesture as? EdgePanWithWebRef,
              let web = edgePan.webView,
        // If WV can go back, prefer its native back-swipe gesture.
        !web.canGoBack else { return }

        switch gesture.state {
        case .ended:
            let translation = gesture.translation(in: gesture.view)
            if translation.x > 20 { // require a meaningful rightward swipe
                parent.closeWebViewHandler?()
            }
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let edgePan = gestureRecognizer as? EdgePanWithWebRef,
              let web = edgePan.webView else { return false }
        // Only begin our edge gesture when WV cannot go back.
        // This avoids conflict with WV's own back-swipe gesture.
        return !web.canGoBack
    }
}

// Edge pan that keeps a weak reference to its associated web view
private class EdgePanWithWebRef: UIScreenEdgePanGestureRecognizer {
    weak var webView: WKWebView?
}
