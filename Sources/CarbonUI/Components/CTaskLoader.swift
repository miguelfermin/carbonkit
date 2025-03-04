//
//  CTaskLoader.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/13/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import SwiftUI
import CarbonCore

@MainActor
@Observable
final public class CTaskLoader {
    public enum LoaderState {
        case idle
        case loading(LocalizedStringKey)
        case error(CError, [PostAction] = [])
        case success(LocalizedStringKey, LocalizedStringKey?, Int? = nil, (() -> Void)? = nil)
    }
    
    public struct PostAction: Identifiable {
        public let id: UUID = UUID()
        public let label: LocalizedStringKey
        public let action: () -> Void
        public init(label: LocalizedStringKey, action: @escaping () -> Void) {
            self.label = label
            self.action = action
        }
    }
    
    public var state: LoaderState = .idle
    
    public init(state: LoaderState = .idle) {
        self.state = state
    }
    
    private var isIdle: Bool {
        switch state {
        case .idle: return true
        default: return false
        }
    }
    
    public var isNotIdle: Bool { !isIdle }
}

extension View {
    @ViewBuilder
    public func taskLoader(_ loader: CTaskLoader) -> some View {
        switch loader.state {
        case .idle:
            self
        case .loading(let title):
            AlertLoading(
                title: title,
                content: { self }
            )
        case .error(let error, let actions):
            AlertError(
                error: error,
                actions: actions,
                loader: loader,
                content: { self }
            )
        case .success(let title, let description, let seconds, let onDismiss):
            AlertSuccess(
                title: title,
                description: description,
                dismissSeconds: seconds ?? 2,
                loader: loader,
                content: { self },
                onDismiss: onDismiss
            )
        }
    }
}

private struct AlertError<Content: View>: View {
    let error: CError
    let actions: [CTaskLoader.PostAction]
    let loader: CTaskLoader
    let content: () -> Content
    
    @State private var showErrorInfo: Bool = false
    
    private var errorText: String {
        if showErrorInfo {
            "Error (\(error.code.description))"
        } else {
            "Error"
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "xmark.circle")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.red)
                .onTapGesture(count: 4) {
                    showErrorInfo.toggle()
                }
            VStack(spacing: 8) {
                Text(errorText)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(error.description)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let info = error.info, showErrorInfo {
                    Text(info.description)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            if actions.isEmpty == false {
                if actions.count > 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        actionsForEach
                    }
                } else {
                    actionsForEach
                }
            } else {
                CButton("OK", style: .alert) {
                    loader.state = .idle
                }
            }
        }
        .overlayLoading(content: content)
    }
    
    private var actionsForEach: some View {
        HStack {
            ForEach(actions) { action in
                CButton(action.label, style: .alert) {
                    action.action()
                }
            }
        }
    }
}

private struct AlertSuccess<Content: View>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let dismissSeconds: Int
    let loader: CTaskLoader
    let content: () -> Content
    let onDismiss: (() -> Void)?
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey?,
        dismissSeconds: Int = 2,
        loader: CTaskLoader,
        content: @escaping () -> Content,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.dismissSeconds = dismissSeconds
        self.loader = loader
        self.content = content
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                if let description {
                    Text(description)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .overlayLoading(content: content)
        .task {
            try? await Task.sleep(for: .seconds(dismissSeconds))
            onDismiss?()
            loader.state = .idle
        }
    }
}

private struct AlertLoading<Content: View>: View {
    let title: LocalizedStringKey
    let content: () -> Content
    
    var body: some View {
        VStack {
            ProgressView()
                .controlSize(.extraLarge)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding()
        .overlayLoading(content: content)
    }
}

extension View {
    fileprivate func overlayLoading<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()
            Color.black
                .opacity(0.5)
                .ignoresSafeArea(.all)
            self
                .frame(minWidth: 300)
                .padding()
                .background(
                    Color(.background)
                        .opacity(0.9)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var job = CTaskLoader(state: .success("Success", "This is a very long success message to test how the graphical user interface would look like in this very cool situation", 4))
    
    ZStack {
        Color(.background)
            .ignoresSafeArea(.all)
        
        VStack(spacing: 20) {
            CButton("Success") {
                await job.state = .loading("signing up to Youhoop systems, please wait...")
                try? await Task.sleep(for: .seconds(1.5))
                
                await job.state = .success("Success", "This is a success message we got duing the signup.")
            }
            
            CButton("Error", style: .secondary) {
                job.state = .loading("signing up to Youhoop systems, please wait...")
                try? await Task.sleep(for: .seconds(1.5))
                
                let error = CError(code: 10000, description: "This is an error message we got duing the signup.", info: [:])
                
                await job.state = .error(error, [
                    .init(label: "Cancel", action: {
                        job.state = .idle
                    }),
                    .init(label: "OK", action: {
                        job.state = .idle
                    }),
                    .init(label: "Do Something", action: {
                        job.state = .idle
                    }),
                    .init(label: "Retry", action: {
                        job.state = .idle
                    }),
                ])
            }
            
            CButton("Error", style: .tertiary) {
                job.state = .loading("signing up to Youhoop systems, please wait...")
                try? await Task.sleep(for: .seconds(1.5))
                
                let error = CError(code: 10000, description: "This is an error message we got duing the signup.", info: [:])
                
                await job.state = .error(error, [
                    .init(label: "Cancel", action: {
                        job.state = .idle
                    }),
                    .init(label: "OK", action: {
                        job.state = .idle
                    }),
                ])
            }
        }
        .padding()
        .taskLoader(job)
    }
}
