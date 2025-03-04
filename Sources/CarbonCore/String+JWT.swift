//
//  String+JWT.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/3/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import Foundation

extension String {
    public func toJWT() -> [String:AnyObject]? {
        try? jwtDecoded?.toDictionary()
    }
    
    /// Base 64 decoded or nil it decoding fails.
    private var base64Decoded: String? {
        if let decodedData = Data(base64Encoded: self), let decoded = String(data: decodedData, encoding: .utf8) {
            return decoded
        }
        return nil
    }
    
    /// JSON Web Token (JWT) decoded string.
    private var jwtDecoded: String? {
        let comps = self.components(separatedBy: ".")
        if comps.count < 1 {
            return nil
        }
        let encoded = comps[1]
        
        let rem = encoded.count % 4
        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(repeating: "=", count: amount)
        }
        
        let options = NSString.CompareOptions(rawValue: 0)
        let base64 = encoded.replacingOccurrences(of: "-", with: "+", options: options, range: nil)
            .replacingOccurrences(of: "_", with: "/", options: options, range: nil) + ending
        
        let base64Decoded = base64.base64Decoded
        return base64Decoded
    }
    
    private func toDictionary() throws -> [String:AnyObject]? {
        if let data = self.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                throw error
            }
        }
        return nil
    }
}
