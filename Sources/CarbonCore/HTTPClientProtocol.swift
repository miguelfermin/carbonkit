//
//  HTTPClientProtocol.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/3/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import Foundation

/// Provides all HTTP header fields and refreshes header fields values, where the refresh meaning is determine
/// by conforming types.
public protocol HTTPHeadersProvider: Actor {
    /// All HTTP header fields, either cached or computed.
    /// - Returns: All HTTP header fields.
    func allHeaders() async throws -> [String: String]
    
    /// Refreshes all HTTP header fields and returns them.
    /// - Returns: All HTTP header fields after a refresh operation.
    func allRefreshedHeaders() async throws -> [String : String]
}

/// HTTPClientProtocol makes it easy and consistent to communicate with HTTP servers.
public protocol HTTPClientProtocol: Actor {
    /// Responsible for HTTP header fields applied to each HTTP request.
    var headersProvider: HTTPHeadersProvider { get }
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    /// - Returns: The URL contents as a Data instance.
    func data(for request: HTTPRequest) async throws(CError) -> Data
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    func send(_ request: HTTPRequest) async throws(CError)
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    /// - Returns: The URL contents decoded using a JSONDecoder for the specified type T.
    func send<T: Decodable>(_ request: HTTPRequest) async throws(CError) -> T
    
    /// Convenience method that sends a GET request to the specified URL.
    /// - Parameter url: The URL to send the request to.
    /// - Returns: The URL contents decoded using a JSONDecoder for the specified type T.
    func get<T: Decodable>(_ url: URL) async throws(CError) -> T
}

extension HTTPClientProtocol {
    public func send(_ request: HTTPRequest) async throws(CError) {
        let _: Data = try await data(for: request)
    }
    
    public func send<T: Decodable>(_ request: HTTPRequest) async throws(CError) -> T {
        let data = try await data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = request.dateDecodingStrategy
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CError(code: -1, description: error.localizedDescription, info: ["Decoding Error": "..."])
        }
    }
    
    public func get<T: Decodable>(_ url: URL) async throws(CError) -> T {
        let req = HTTPRequest(url: url)
        return try await send(req)
    }
}
