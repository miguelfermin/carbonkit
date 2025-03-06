//
//  HTTPClient.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/1/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import Foundation

/// HTTPClient makes it easy and consistent to communicate with HTTP servers.
public actor HTTPClient: HTTPClientProtocol {
    private let session = URLSession(configuration: .default)
    
    public let headersProvider: HTTPHeadersProvider
    
    public init(headersProvider: HTTPHeadersProvider) {
        self.headersProvider = headersProvider
    }
    
    public func data(for request: HTTPRequest) async throws(CError) -> Data {
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
                    throw Self.parseError(data: data, response: response)
                }
            }
            return data
        } catch let error as CError {
            error.log(request)
            throw error
        } catch {
            error.log(request)
            throw CError(code: -1, description: error.localizedDescription, info: nil)
        }
    }
}

extension HTTPClient {
    public static func send<T: Decodable>(_ request: HTTPRequest, headers: [String : String]?) async throws(CError) -> T {
        do {
            var urlRequest = URLRequest(url: request.url)
            urlRequest.httpMethod = request.method.string
            urlRequest.httpBody = request.method.jsonEncoded
            urlRequest.timeoutInterval = request.timeoutInterval
            urlRequest.allHTTPHeaderFields = headers
            let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
            let response = try urlResponse.toHTTPURLResponse()
            guard response.isOk else {
                throw parseError(data: data, response: response)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = request.dateDecodingStrategy
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch let error as CError {
            error.log(request)
            throw error
        } catch {
            error.log(request)
            throw CError(code: -1, description: error.localizedDescription, info: nil)
        }
    }
    
    private static func parseError(data: Data, response: HTTPURLResponse) -> CError {
        if let error = try? CError(from: data) {
            return error
        } else {
            return CError(from: data, response: response)
        }
    }
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
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
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
        let description = String(decoding: data, as: UTF8.self)
        self.init(code: response.statusCode, description: description, info: nil)
        self.data = data
    }
}

// MARK: - URLResponse+Helper
extension URLResponse {
    fileprivate func toHTTPURLResponse() throws -> HTTPURLResponse {
        enum HttpClientError: Error {
            case invalidServerResponse
        }
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
    fileprivate func log(_ request: HTTPRequest, function: String = #function) {
        print("""
🔥 Error:
    - File:         \(#file)
    - Line:         \(#line)
    - Function:     \(function)
    - Request URL:  \(request.url)
    - HTTP Method:  \(request.method.string)
    - Domain Code:  \((self as? CError)?.code ?? 0)
    - Description:  \(localizedDescription)
""")
    }
}
