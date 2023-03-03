import Foundation
import WebKit


public func setupLogging(userContentController: WKUserContentController, logLevel: Int = 0) throws {
    
    var enableLevels:String = ""
    
    switch logLevel {
    case 0:
        enableLevels =
        """
        console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) }
        console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
        console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
        """
    case 1:
        enableLevels = """
        console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
        console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
        """
    case 2:
        enableLevels = """
        console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
        """
    case 3:
        enableLevels = """
        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
        """
    default:
        throw "Invalid logLevel"
    }
    
    let overrideConsole = """
        function log(emoji, type, args) {
          window.webkit.messageHandlers.logging.postMessage(
            `${emoji} JS ${type}: ${Object.values(args)
              .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
              .map(v => v.substring(0, 3000)) // Limit msg to 3000 chars
              .join(", ")}`
          )
        }

        let originalLog = console.log
        let originalWarn = console.warn
        let originalError = console.error
        let originalDebug = console.debug
    
        \(enableLevels)

        window.addEventListener("error", function(e) {
           log("💥", "Uncaught", [`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`])
        })
    """

    class LoggingMessageHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print(message.body)
        }
    }

    userContentController.add(LoggingMessageHandler(), name: "logging")
    userContentController.addUserScript(WKUserScript(source: overrideConsole, injectionTime: .atDocumentStart, forMainFrameOnly: true))

}


//        console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
//        console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
//        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
//        console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) }
