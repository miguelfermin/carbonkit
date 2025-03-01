//
//  CCheckbox.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/12/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import SwiftUI

public struct CCheckbox: View {
    @Binding var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        _isOn = isOn
    }
    
    public var body: some View {
        Image(systemName: isOn ? "checkmark.square.fill" : "square")
            .font(.system(size: 25, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .onTapGesture { isOn.toggle() }
    }
}

#Preview {
    @Previewable @State var isOn: Bool = false
    CCheckbox(isOn: $isOn)
}
