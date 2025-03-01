//
//  String+Utils.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/9/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import SwiftUI

extension String {
    private static let __firstpart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
    private static let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
    private static let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,6}"

    public var isEmail: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", type(of:self).__emailRegex)
        return predicate.evaluate(with: self)
    }

    // this needs testing
    private static let __domainRegex = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,2}[A-Za-z]{2,6}"
    public var isDomain: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", type(of:self).__domainRegex)
        return predicate.evaluate(with: self)
    }
    
    // this needs testing
    public var isNumber: Bool {
        !isEmpty && rangeOfCharacter(from: .decimalDigits) != nil
    }
}
