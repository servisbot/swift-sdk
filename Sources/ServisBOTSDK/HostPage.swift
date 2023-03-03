import Foundation
import UIKit
import WebKit

public class HostPage: WKWebView {
    
    public init(frame: CGRect) {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptEnabled = true
        
        super.init(frame: frame, configuration: webConfiguration)
        self.scrollView.isScrollEnabled = false
        self.isMultipleTouchEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @discardableResult
    public func load() -> WKNavigation? {
        
        let link = "https://messenger.servisbot.com/v2/mobile.html?organization=sbdemo3&endpoint=sbdemo3-Features&sbRegion=eu-1&context.loanNumber=1a"
        if let url = URL(string:link) {
            let req = URLRequest(url: url)
            return super.load(req)
        }
        return nil
    }
}
