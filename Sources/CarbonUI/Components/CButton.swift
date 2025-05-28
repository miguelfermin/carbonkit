//
//  CButton.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/12/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import SwiftUI

 public struct CButton: View {
     public enum Style {
         case primary, secondary, tertiary, alert, destructive
         var color: Color {
             switch self {
             case .alert: return .secondary
             case .destructive: return .red
             default: return Color.accentColor
             }
         }
     }
     
     let key: LocalizedStringKey
     let style: Style
     let maxWidth: CGFloat?
     let image: Image?
     let disabled: () -> Bool
     let action: @MainActor () async -> Void
     let buttonsTintColor = Color.accentColor
     
     public init(
        _ key: LocalizedStringKey,
        style: Style = .primary,
        maxWidth: CGFloat? = .infinity,
        image: Image? = nil,
        disabled: @escaping () -> Bool = { false },
        action: @escaping @MainActor () async -> Void
     ) {
         self.key = key
         self.style = style
         self.maxWidth = maxWidth
         self.image = image
         self.disabled = disabled
         self.action = action
     }
     
     public var body: some View {
         Button {
             Task { await action() }
         } label: {
             HStack {
                 image
                 Text(key)
             }
             .font(.system(size: 18, weight: .semibold))
             .frame(maxWidth: maxWidth)
         }
         .applyButtonStyle(for: style)
         .controlSize(.large)
         .tint(style.color)
         .disabled(disabled())
     }
 }

fileprivate extension View {
    @ViewBuilder
    public func applyButtonStyle(for style: CButton.Style) -> some View {
        switch style {
        case .primary, .destructive:
            self.buttonStyle(.borderedProminent)
        case .secondary, .alert:
            self.buttonStyle(.bordered)
        case .tertiary:
            self.buttonStyle(.automatic)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        Spacer()
        CButton("Primary", action: {})
        CButton("Secondary", style: .secondary, action: {})
        CButton("Tertiary", style: .tertiary, action: {})
        Spacer()
    }
    .padding()
//    .background(Color.background.ignoresSafeArea(.all))
}
