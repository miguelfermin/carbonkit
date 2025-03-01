//
//  CSafariView.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/12/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import UIKit
import SwiftUI
import SafariServices

private struct CSafariView {
    fileprivate typealias Completion = () -> Void
    fileprivate typealias UIViewControllerType = SFSafariViewController
    
    private let url: URL
    private let entersReaderIFAvailable: Bool
    private let onDismiss: Completion?
    private let safariDelegate: SafariDelegate
    
    fileprivate init(url: URL, entersReaderIfAvailable: Bool = false, onDismiss: Completion? = nil) {
        self.url = url
        self.entersReaderIFAvailable = entersReaderIfAvailable
        self.onDismiss = onDismiss
        self.safariDelegate = SafariDelegate(onDismiss: onDismiss)
    }
}

extension CSafariView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = entersReaderIFAvailable
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.delegate = safariDelegate
        controller.preferredControlTintColor = UIColor.tintColor
        return controller
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension CSafariView {
    fileprivate class SafariDelegate: NSObject, SFSafariViewControllerDelegate {
        private let onDismiss: Completion?
        init(onDismiss: (() -> Void)?) { self.onDismiss = onDismiss }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) { onDismiss?() }
    }
}

extension View {
    public func safariScreenCover(
        isPresented: Binding<Bool>,
        url: URL,
        entersReaderIfAvailable: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self
            .environment(\.openURL, OpenURLAction { url in
                isPresented.wrappedValue.toggle()
                return .handled
            })
            .fullScreenCover(isPresented: isPresented) {
                CSafariView(url: url, entersReaderIfAvailable: entersReaderIfAvailable, onDismiss: onDismiss)
                    .edgesIgnoringSafeArea(.all)
            }
    }
    
    public func handleOpenURL(
        url: URL,
        entersReaderIfAvailable: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(CSafariViewModifier(url: url))
    }
}

private struct CSafariViewModifier: ViewModifier {
    private let url: URL
    private let entersReaderIfAvailable: Bool
    private let onDismiss: (() -> Void)?
    
    @State private var isPresented = false
    
    fileprivate init(url: URL, entersReaderIfAvailable: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.url = url
        self.onDismiss = onDismiss
        self.entersReaderIfAvailable = entersReaderIfAvailable
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                if url == self.url {
                    isPresented.toggle()
                    return .handled
                } else {
                    return .systemAction
                }
            })
            .fullScreenCover(isPresented: $isPresented) {
                CSafariView(
                    url: url,
                    entersReaderIfAvailable: entersReaderIfAvailable,
                    onDismiss: onDismiss
                )
                .edgesIgnoringSafeArea(.all)
            }
    }
}
