//
//  WebView.swift
//  Curio
//
//  Created by Manik on 5/1/25.
//

import SwiftUI
import SafariServices

/// A SwiftUI wrapper for SFSafariViewController that displays web content with Reader mode
struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemBlue
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
