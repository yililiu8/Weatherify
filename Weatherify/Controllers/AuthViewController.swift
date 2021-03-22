//
//  AuthViewController.swift
//  Weatherify
//
//  Created by Yili Liu on 3/22/21.
//

import UIKit
import WebKit

class AuthViewController: UIViewController, WKNavigationDelegate {
    
    public var completionHandler: ((Bool) -> Void)?
    
    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        webView.frame = view.frame
        guard let url = AuthManager.shared.signInURL else {
            print("failed to connect to signin server")
            return
        }
        webView.load(URLRequest(url: url))
        print("success")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        let component = URLComponents(string: url.absoluteString)
        guard let code = component?.queryItems?.first(where: { $0.name == "code"  })?.value else {
            return
        }
        webView.isHidden = true
        print("Code: \(code)")
        AuthManager.shared.convertCodeToToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                self?.dismiss(animated: true, completion: nil)
                self?.completionHandler?(success)
            }
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        let component = URLComponents(string: url.absoluteString)
        guard let code = component?.queryItems?.first(where: { $0.name == "code"  })?.value else {
            return
        }
        webView.isHidden = true
        print("Code: \(code)")
        AuthManager.shared.convertCodeToToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                self?.dismiss(animated: true, completion: nil)
                self?.completionHandler?(success)
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
