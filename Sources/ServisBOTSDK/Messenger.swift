import Foundation
import WebKit


extension String: Error {}

extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .ascii)
    }
}

public class Messenger {
    /*
     NOTE: configuration (scripts) must be complete before passing to WebView
     */
    var webview: WKWebView?
    var config: [String:Any]
    var resetAtStart: Bool
    
    var htmlContent = """
        <html>
          <head>
            <meta name="viewport" content="user-scalable=no, width=device-width">
          </head>
        <body>
        </body>
        </html>
        """
    var baseUrl = "https://servisbot.com"   // needs to match to your origin settings(security) and needed for localStorage
    
    public init(config: [String: Any], resetAtStart: Bool=false) {
        self.config = config
        self.resetAtStart = resetAtStart
        
        // Validate config, ensure organization is present.
        
        if (!self.config.keys.contains("defaultOpen")) {
            self.config["defaultOpen"] = false
        }
    }
    
    public func load() throws -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let userContentController = WKUserContentController()
        setupLogging(userContentController: userContentController)
        hookToMessenger(userContentController: userContentController)
        try userContentController.addUserScript(self.getBundle())
        userContentController.addUserScript(self.initBundle())
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences = preferences
        
        let safeWebView: WKWebView = WKWebView(frame: CGRect.zero, configuration: configuration)
        // Load HTML string to web view
        safeWebView.loadHTMLString(self.htmlContent, baseURL: URL(string: self.baseUrl))
        self.webview = safeWebView
        return safeWebView
    }
    
    private func getBundle() throws -> WKUserScript {
        let bundleLink = "https://lightning.us1.helium.servismatrixcdn.com/v2/latest/bundle-messenger.js"

        guard
            let bundleUrl = URL(string: bundleLink),
            let bundleContent = try? String(contentsOf: bundleUrl, encoding: .utf8) else {
            assertionFailure("Fail to get bundle")
            throw "Failed to get bundle"
        }
        let bundleScript = WKUserScript(source: bundleContent,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)
        return bundleScript
    }
    
    private func buildConfigJavascript() -> String {
        var configJS = "config = "
        configJS += self.config.jsonStringRepresentation!
        return configJS
    }
    
    private func initBundle() -> WKUserScript {
        let configJS = buildConfigJavascript()

        let javaScriptInit = """
            console.log("entered javaScriptInit ======================");

            \(configJS)
        
            if (\(resetAtStart)) {
                console.log("Resetting after init");
                config.resetOnLoad = true
            }
        
            console.log(config)
            ServisBotApi = ServisBot.init(config);
        
            ServisBotApi.on('notification', function(message) {
                toSdk(message);
            });
        """
        print(javaScriptInit)
        let initScript = WKUserScript(source: javaScriptInit,
                                      injectionTime: .atDocumentEnd,
                                      forMainFrameOnly: true)
        return initScript
    }

    public func reset() {
        // TODO: Weird effect
        print("try reset")
        if (self.webview != nil) {
            self.webview?.evaluateJavaScript("ServisBotApi.reset();")
        }
        print("after reset")
    }
}
