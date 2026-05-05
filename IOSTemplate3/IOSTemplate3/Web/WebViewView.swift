import SwiftUI
import WebKit
import Observation

struct WebViewView: View {
    @State private var webViewModel = WebViewManagerModel()
    @State var loadModel = LoadingVisibilityModel()
    @State var webViewShown = true
    @State var onAppearCallback: (() -> Void)?
    
    var body: some View {
        @Bindable var model = webViewModel
        
        ZStack {
            Color(
                UIColor(
                    red: CGFloat(0x22) / 255.0,
                    green: CGFloat(0x1A) / 255.0,
                    blue: CGFloat(0x1A) / 255.0,
                    alpha: CGFloat(0xFF) / 255.0
                )
            ).ignoresSafeArea()
            
            GeometryReader { geo in
                VStack(spacing: 0) {
                    if !webViewModel.webViewStack.isEmpty {
                        Rectangle()
                            .foregroundColor(.black)
                            .frame(height: geo.size.height * 0.05)
                            .overlay {
                                NavBarr(webViewModel: model)
                            }
                    }
                    
                    ZStack {
                        model.webView
                        ForEach(model.webViewStack) { manager in
                            manager
                        }
                    }
                }
            }
        }
        .onAppear()
        {
            onAppearCallback?()
        }
    }

    func loadURL(url: String) {
        webViewModel.loadURL(url: URL(string: url)!)
    }
}

@Observable
class LoadingVisibilityModel {
    var loadingVisible: Bool = true
}

@Observable
class WebViewManagerModel {
    var webView: WebViewManager
    var webViewStack: [WebViewManager]
    
    var currentWebView: WebViewManager {
        if let last = webViewStack.last
        {
            return last
        }
        return webView
    }
    
    var canGoBack: Bool {
        if let vw = topWebView()
        {
            print("back jumps: \(vw.webView.backForwardList.backList.count)")
        }
        print("")
        return !(topWebView()?.webView.backForwardList.backList.isEmpty ?? true) || !webViewStack.isEmpty
    }
    
    var canGoForward: Bool {
        return !(topWebView()?.webView.backForwardList.forwardList.isEmpty ?? true)
    }

    private let rootId = UUID()
    var currentWebViewId: UUID {
        webViewStack.last?.id ?? rootId
    }

    init() {
        self.webView = WebViewManager()
        self.webViewStack = []
    }
    
    func loadURL(url: URL) {
        configureHandlers(for: &webView)
        webView.loadURL(url: url)
    }

    /// Pushes a new manager when the w-content asks to open a separate window.
    func pushWebView(manager: WebViewManager) {
        var newManager = manager
        configureHandlers(for: &newManager)
        webViewStack.append(newManager)
    }
    
    func goBack() {
        if let topWebView = topWebView(), topWebView.webView.canGoBack {
            topWebView.webView.goBack()
        } else {
            popWebView()
        }
    }

    func popWebView() {
        if !webViewStack.isEmpty {
            webViewStack.removeLast()
            print("Tab popped")
        }
    }
    
    func topWebView() -> WebViewManager? {
        if webViewStack.isEmpty {
            return webView
        }
        return webViewStack.last ?? nil
    }
    
    /// Rebinds tab navigation callbacks so new managers participate in the stack.
    private func configureHandlers(for manager: inout WebViewManager) {
        manager.openInNewTabHandler = { newManager in
            self.pushWebView(manager: newManager)
        }
        manager.closeWebViewHandler = {
            self.popWebView()
        }
    }
}

struct IdentifiableWebViewManager: Identifiable {
    var id = UUID()
    var webViewManager: WebViewManager
}

struct NavBarr: View {
    @Bindable var webViewModel: WebViewManagerModel
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                Button(action: {
                    if webViewModel.canGoBack {
                        webViewModel.goBack()
                    }
                }) {
                    ZStack {
                        Color.clear
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                }
                .disabled(!webViewModel.canGoBack)
                .frame(width: geo.size.height)
                
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}
