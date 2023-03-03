import Foundation
import WebKit


public func hookToMessenger(userContentController: WKUserContentController) {
    let overrideConsole = """
        function toSdk(message) {
          window.webkit.messageHandlers.handleHostNotification.postMessage(
            `${message}`
          )
        }
    """

    class MessageHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            /* currently a string */
            print("Received host notification '\(message.body)'")
        }
    }

    userContentController.add(MessageHandler(), name: "handleHostNotification")
    userContentController.addUserScript(WKUserScript(source: overrideConsole, injectionTime: .atDocumentStart, forMainFrameOnly: true))
}
