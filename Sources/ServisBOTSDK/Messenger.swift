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
    var bundleLink: String
    var hostPageUrl: String
    var hostNotificationDelegate: ((String) -> Void)?
    
    var htmlContent = """
        <html>
          <head>
            <meta name="viewport" content="user-scalable=no, width=device-width">
          </head>
        <body>
        </body>
        </html>
        """

    public init(
        config: [String: Any],
        hostPageUrl: String="https://servisbot.com",
        hostNotificationDelegate: ((String) -> Void)?=nil,
        resetAtStart: Bool=false
    ) throws {
        /*
         hostPageUrl needs to match to your origin settings(security) and needed for localStorage
         */
        self.config = config
        self.hostPageUrl = hostPageUrl
        self.hostNotificationDelegate = hostNotificationDelegate
        self.resetAtStart = resetAtStart
        
        // Validate config, ensure required parameters are present.
        if (!self.config.keys.contains("organization")) {
            throw "organization is required"
        }
        if (!self.config.keys.contains("endpoint")) {
            throw "endpoint is required"
        }
        if (!self.config.keys.contains("sbRegion")) {
            throw "sbRegion is required"
        }

        if (!self.config.keys.contains("defaultOpen")) {
            self.config["defaultOpen"] = false
        }
                
        if let region = self.config["sbRegion"] as? String {
            switch region {
            case "us-1", "us1":
                self.bundleLink = "https://lightning.us1.helium.servismatrixcdn.com/v2/latest/bundle-messenger.js"
            case "eu-1", "eu1":
                self.bundleLink = "https://lightning.production.helium.servismatrixcdn.com/v2/latest/bundle-messenger.js"
            default:
                throw "sbRegion is unknown"
            }
        } else {
            throw "sbRegion is invalid"
        }
    }
    
    private func hostNotification(message: String) {
        if (self.hostNotificationDelegate != nil) {
            self.hostNotificationDelegate!(message)
        }
    }
    
    public func load() throws -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let userContentController = WKUserContentController()
        setupLogging(userContentController: userContentController)
        hookToMessenger(userContentController: userContentController, delegate: hostNotification)
        try userContentController.addUserScript(self.getBundle())
        userContentController.addUserScript(self.initBundle())
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences = preferences
        
        let safeWebView: WKWebView = WKWebView(frame: CGRect.zero, configuration: configuration)
        // Load HTML string to web view
        safeWebView.loadHTMLString(self.htmlContent, baseURL: URL(string: self.hostPageUrl))
        self.webview = safeWebView
        return safeWebView
    }
    
    private func getBundle() throws -> WKUserScript {
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
