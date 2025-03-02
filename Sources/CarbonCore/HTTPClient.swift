//
//  HTTPClient.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/1/25.
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
public protocol HTTPClientProtocol {
    /// Responsible for HTTP header fields applied to each HTTP request.
    var headersProvider: HTTPHeadersProvider { get }
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    /// - Returns: The URL contents as a Data instance.
    func data(for request: HTTPRequest) async throws -> Data
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    func send(_ request: HTTPRequest) async throws
    
    /// Executes an HTTP request to a server using information specified in HTTPRequest.
    /// - Parameter request: An HTTPRequest  that provides request-specific information such as the URL, request type, and body.
    /// - Returns: The URL contents decoded using a JSONDecoder for the specified type T.
    func send<T: Decodable>(_ request: HTTPRequest) async throws -> T
}

extension HTTPClientProtocol {
    public func send(_ request: HTTPRequest) async throws {
        let _: Data = try await data(for: request)
    }
    
    public func send<T: Decodable>(_ request: HTTPRequest) async throws -> T {
        let data = try await data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = request.dateDecodingStrategy
        let value = try decoder.decode(T.self, from: data)
        return value
    }
}

/// HTTPClient makes it easy and consistent to communicate with HTTP servers.
public actor HTTPClient: HTTPClientProtocol {
    private let session = URLSession(configuration: .default)
    
    public let headersProvider: HTTPHeadersProvider
    
    public init(headersProvider: HTTPHeadersProvider) {
        self.headersProvider = headersProvider
    }
    
    public func data(for request: HTTPRequest) async throws -> Data {
        do {
            let urlRequest = try await request.urlRequest(headersProvider: headersProvider)
            let (data, urlResponse) = try await session.data(for: urlRequest)
            
            let response = try urlResponse.toHTTPURLResponse()
            guard response.isOk else {
                if response.isUnauthorized && request.headersStrategy.isNormal {
                    let headers = try await headersProvider.allRefreshedHeaders()
                    var request = request
                    request.updateHeadersStrategy(.custom(headers))
                    return try await self.data(for: request)
                } else {
                    if let error = try? CError(from: data) {
                        throw error
                    } else {
                        throw CError(from: data, response: response)
                    }
                }
            }
            return data
        } catch {
            error.log(request)
            throw error
        }
    }
}

// MARK: - HttpClientError
enum HttpClientError: Error {
    case invalidServerResponse
}

// MARK: - CError+Helper
extension CError {
    fileprivate init(from data: Data) throws {
        enum CErrorDecoding: Error, LocalizedError {
            case badPayload
            case missingDomainCode
            case missingDescription
            
            var errorDescription: String? {
                switch self {
                case .badPayload:           "Bad Data"
                case .missingDomainCode:    "Expected domainCode field missing"
                case .missingDescription:   "Expected description field missing"
                }
            }
        }
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            throw CErrorDecoding.badPayload
        }
        guard let code = json["code"] as? Int else {
            throw CErrorDecoding.missingDomainCode
        }
        guard let description = json["description"] as? String else {
            throw CErrorDecoding.missingDescription
        }
        self.init(code: code, description: description, info: json["info"] as? [String: String])
    }
    
    fileprivate init(from data: Data, response: HTTPURLResponse) {
        self.init(code: response.statusCode, description: "N/A: check data field", info: nil)
        self.data = data
    }
}

// MARK: - URLResponse+Helper
extension URLResponse {
    fileprivate func toHTTPURLResponse() throws -> HTTPURLResponse {
        guard let response = (self as? HTTPURLResponse) else {
            throw HttpClientError.invalidServerResponse
        }
        return response
    }
}

// MARK: - HTTPURLResponse+Helper
extension HTTPURLResponse {
    fileprivate var isOk: Bool { statusCode > 199 && statusCode < 300 }
    
    fileprivate var isUnauthorized: Bool { statusCode == 401 }
}

// MARK: - Error+Helper
extension Error {
    fileprivate func log(_ request: HTTPRequest, fileID: String = #fileID, function: String = #function) {
        print("""
***************************************************************
Error
    - File:             \(fileID)
    - Function:         \(function)
    - Request URL:      \(request.url)
    - Request Method:   \(request.method)
    - Localized:        \(localizedDescription)
    - Carbon Error:     \((self as? CError)?.description ?? "N/A")
***************************************************************
""")
    }
}
