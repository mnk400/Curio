//
//  WebView.swift
//  Riki
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import WebKit

/// A SwiftUI wrapper for WKWebView that displays web content
struct WebView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The URL to load in the web view
    let url: URL
    
    // MARK: - UIViewRepresentable
    
    /// Creates and configures the WKWebView
    /// - Parameter context: The representable context
    /// - Returns: A configured WKWebView instance
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    /// Updates the web view with the current URL
    /// - Parameters:
    ///   - webView: The WKWebView to update
    ///   - context: The representable context
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    /// Creates the coordinator for handling web view navigation events
    /// - Returns: A WebViewCoordinator instance
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator()
    }
}

// MARK: - WebView Coordinator

/// Coordinator class that handles WKWebView navigation delegate methods
final class WebViewCoordinator: NSObject, WKNavigationDelegate {
    
    /// Called when the web view starts loading content
    /// - Parameters:
    ///   - webView: The web view that started loading
    ///   - navigation: The navigation object
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Future: Could show loading indicator here
    }
    
    /// Called when the web view finishes loading content
    /// - Parameters:
    ///   - webView: The web view that finished loading
    ///   - navigation: The navigation object
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Future: Could hide loading indicator here
    }
    
    /// Called when the web view fails to load content
    /// - Parameters:
    ///   - webView: The web view that failed to load
    ///   - navigation: The navigation object
    ///   - error: The error that occurred
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
    }
    
    /// Called when the web view fails to start loading content
    /// - Parameters:
    ///   - webView: The web view that failed to start loading
    ///   - navigation: The navigation object
    ///   - error: The error that occurred
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
    }
}

#Preview {
    WebView(url: URL(string: "https://en.wikipedia.org/wiki/Swift_(programming_language)")!)
}