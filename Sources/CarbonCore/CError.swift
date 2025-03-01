//
//  CError.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/26/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import Foundation

public struct CError: Error, LocalizedError, Decodable {
    /// Domain error code.
    public let code: Int
    /// The error description.
    public let description: String
    /// A dictionary containing additional error information.
    public let info: [String: String]?
    
    public var errorDescription: String? { description }
    
    public init(code: Int, description: String, info: [String : String]?) {
        self.code = code
        self.description = description
        self.info = info
    }
    
    public static func sample(_ description: String) -> Self {
        .init(code: -1, description: description, info: nil)
    }
}
