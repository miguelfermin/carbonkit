//
//  View+Modifiers.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/1/25.
//

import SwiftUI

extension View {
    public func toolbarWithDismiss(
        _ dismiss: @escaping () -> Void,
        systemName: String = "x.circle.fill",
        disabled: () -> Bool = {false}
    ) -> some View {
        self
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: systemName)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    .disabled(disabled())
                }
            }
    }
    
    public func toolbarWithDismiss(
        systemName: String = "x.circle.fill",
        disabled: @escaping () -> Bool = {false}
    ) -> some View {
        modifier(ToolbarWithDismiss(systemName: systemName, disabled: disabled))
    }
}

struct ToolbarWithDismiss: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    let systemName: String
    let disabled: () -> Bool
    
    init(systemName: String, disabled: @escaping () -> Bool) {
        self.systemName = systemName
        self.disabled = disabled
    }
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: systemName)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    .disabled(disabled())
                }
            }
    }
}
