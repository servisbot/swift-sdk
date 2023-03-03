import Foundation
import WebKit


public func hookToMessenger(userContentController: WKUserContentController, delegate: @escaping (String) -> Void) {
    let overrideConsole = """
        function toSdk(message) {
          window.webkit.messageHandlers.handleHostNotification.postMessage(
            `${message}`
          )
        }
    """

    class MessageHandler: NSObject, WKScriptMessageHandler {
        var delegate: (String) -> Void
        
        public init(delegate: @escaping (String) -> Void) {
            self.delegate = delegate
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            /* currently a string */
            if let message = message.body as? String {
                delegate(message)
            }
        }
    }

    userContentController.add(MessageHandler(delegate: delegate), name: "handleHostNotification")
    userContentController.addUserScript(WKUserScript(source: overrideConsole, injectionTime: .atDocumentStart, forMainFrameOnly: true))
}
