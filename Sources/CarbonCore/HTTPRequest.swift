//
//  HTTPRequest.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/1/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import Foundation

public struct HTTPRequest: Sendable {
    public let url: URL
    public let method: HTTPMethod
    public let timeoutInterval: TimeInterval
    public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    
    private(set) var headersStrategy: HTTPRequestHeadersStrategy = .normal
    
    public init(
        url: URL,
        method: HTTPMethod = .get,
        timeoutInterval: TimeInterval = 20,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) {
        self.url = url
        self.method = method
        self.timeoutInterval = timeoutInterval
        self.dateDecodingStrategy = dateDecodingStrategy
    }
    
    func urlRequest(headersProvider: HTTPHeadersProvider) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpBody = method.jsonEncoded
        request.httpMethod = method.string
        request.timeoutInterval = timeoutInterval
        request.allHTTPHeaderFields = switch headersStrategy {
        case .normal, .skipRefresh:
            try await headersProvider.allHeaders()
        case .custom(let headers):
            headers
        }
        return request
    }
    
    mutating func updateHeadersStrategy(_ headersStrategy: HTTPRequestHeadersStrategy) {
        self.headersStrategy = headersStrategy
    }
}

// MARK: - HTTPBody
public typealias HTTPBody = Encodable & Sendable

// MARK: - HTTPMethod
public enum HTTPMethod: Sendable {
    case get
    case post(HTTPBody)
    case put(HTTPBody)
    case patch(HTTPBody)
    case delete(HTTPBody)
    
    var string: String {
        switch self {
        case .get:    return "GET"
        case .post:   return "POST"
        case .put:    return "PUT"
        case .patch:  return "PATCH"
        case .delete: return "DELETE"
        }
    }
    
    var jsonEncoded: Data? {
        switch self {
        case .get:
            return nil
        case .post(let encodable), .put(let encodable), .patch(let encodable), .delete(let encodable):
            return try? JSONEncoder().encode(encodable)
        }
    }
}

// MARK: - HTTPRequestHeadersStrategy
public enum HTTPRequestHeadersStrategy: Equatable, Sendable {
    case normal
    case skipRefresh
    case custom([String: String])
    
    var isNormal: Bool {
        switch self {
        case .normal:
            return true
        default:
            return false
        }
    }
}
