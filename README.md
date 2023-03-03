# ServisBOT swift sdk

SDK for using ServisBOT's Messenger application within iOS devices.

## Getting started

add the ServisBOT swift sdk to your project

1. select File > Swift Packages > Add Package Dependency and enter its repository URL. [detailed instructions](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)  
    * alternatively: File > Add Packages > (repository URL in search bar)
2. repository URL: https://github.com/servisbot/swift-sdk

## basic configuration

```swift
    let basicConfig:[String:Any] = [
        "organization": "netscapestg",
        "endpoint": "netscapestg-AskBot",
        "sbRegion": "us-1",
    ]
```

for your bots, check with your Account manager for your values

## advance configuration

```swift
    let customStyle = ""  // a css file reference (hyperlink)

    let enhancedConfig:[String:Any] = [
        "organization": "netscapestg",
        "endpoint": "netscapestg-AskBot",
        "sbRegion": "us-1",
        "displayWidget": true,
        "customStyle": customStyle,
        "customerReference": "1234567890",
        "context": ["userName": "fakeUserName"]
    ]
```

## usage pattern

import the ServisBOT SDK

```swift
import ServisBOTSDK
```

setup your configuration

instantiate the messenger

```swift
    sbMessenger = Messenger(config: basicConfig, resetAtStart: false)
```

when loading the messenger, it will produce a `WkWebView`.

```swift
    let sbView: WKWebView = try sbMessenger!.load()
```

add the webview into your controller and setup delegates if you want to track state changes

```swift
    do {
        let sbView: WKWebView = try sbMessenger.load()
        sbView.navigationDelegate = self
        self.view.addSubview(sbView)
        setLayoutDetails(webView: sbView)
    } catch {
        print("Messenger failed to load")
    }
```

full code snippet here
```swift
import UIKit
import WebKit
import ServisBOTSDK

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        showMessenger()
    }

    private func showMessenger() {
        let organization = "netscapestg"
        let endpoint = "netscapestg-AskBot"
        let sbRegion = "us-1"
        
        let basicConfig:[String:Any] = [
            "organization": organization,
            "endpoint": endpoint,
            "sbRegion": sbRegion,
        ]
                
        do {
            let sbMessenger = try Messenger(
              config: basicConfig,
              hostNotificationDelegate: hostNotification,
              resetAtStart: false,
              logLevel: 2  // logLevel 0=debug, 1=log, 2=warn, 3=error
            )

            let sbView: WKWebView = try sbMessenger.load()
            sbView.navigationDelegate = self
            self.view.addSubview(sbView)
            setLayoutDetails(webView: sbView)
        } catch {
            print("Messenger failed to load")
        }
    }
    
    func hostNotification(message: String) {
        print("Host Notification \(message)")
    }

    func webView(_ webView: WKWebView, didFinish  navigation: WKNavigation!)
    {
        let url = webView.url?.absoluteString
        print("--- Loaded hostpage domain --->\(url!)")
    }
    
    private func setLayoutDetails(webView: WKWebView) {
        // Show web view on screen
        webView.layer.cornerRadius = 20.0
        webView.layer.masksToBounds = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 20.0),
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20.0),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0),
            webView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -20.0),
        ])
    }

}
```

