//
//  KeychainStorage.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 3/3/25.
//

import Foundation

/// Stores value in secured device keychain.
///
/// The default storage encoding is JSON (*JSONEncoder/JSONDecoder*).
/// - note: When running app on Simulator, the value is stored in standard user defaults.
@propertyWrapper
public struct KeychainStorage<Value: Codable> {
    let key: String
    
    public init(_ key: String) {
        self.key = key
    }
    
    public var wrappedValue: Value? {
        get {
#if targetEnvironment(simulator)
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(Value.self, from: data)
#else
            Keychain.item(forKey: key, service: .authTokens)
#endif
        }
        set {
#if targetEnvironment(simulator)
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.setValue(data, forKey: key)
#else
            Keychain.add(item: newValue, forKey: key, service: .authTokens)
#endif
        }
    }
}

// Apple Docs:
//  https://developer.apple.com/reference/security/1658642-keychain_services
//  https://www.osstatus.com/search/results?platform=all&framework=all&search=-25299

private enum Keychain {
    enum Service: String {
        case authTokens = "com.carbonkit.authTokens"
    }
    
    private static  let client = ".\(Bundle.main.bundleIdentifier ?? "unknown_bundle_id")"
    
    /// Adds the specified item to the Keychain.
    /// - Parameters:
    ///   - item: The item to add.
    ///   - key: The key to associate the item being saved, for later retrieval.
    ///   - service: The Keychain Service attribute key for the service associated with this item.
    /// - Returns: An **OSStatus** code.
    @discardableResult
    static func add(item: Codable, forKey key: String, service: Service) -> OSStatus {
        guard let data = item.encoded else {
            return errSecInvalidData
        }
        let attributes: NSDictionary = [
            "\(kSecClass)": kSecClassGenericPassword,
            "\(kSecAttrAccount)": key + client,
            "\(kSecAttrService)": service.rawValue,
            "\(kSecValueData)": data
        ]
        
        let status = SecItemAdd(attributes, nil)
        if status == errSecDuplicateItem {
            return update(item: item, forKey: key, service: service)
        } else {
            return status
        }
    }
    
    /// Gets item from the keychain by the specified key.
    /// - Parameters:
    ///   - key: The key associated with the item to be retrieved.
    ///   - service: The Keychain Service attribute key for the service associated with this item.
    /// - Returns: The HttpRequested item if it exist in the Keychain or nil if it doesn't
    @discardableResult
    static func item<T: Codable>(forKey key: String, service: Service) -> T? {
        let query: NSDictionary = [
            "\(kSecClass)": kSecClassGenericPassword,
            "\(kSecAttrAccount)": key + client,
            "\(kSecAttrService)": service.rawValue,
            "\(kSecReturnData)": true
        ]
        var dataObject: AnyObject?
        SecItemCopyMatching(query, &dataObject)
        
        guard let data = dataObject as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    /// Deletes the item matching the specified key from the keychain.
    /// - Parameters:
    ///   - key: The key associated with the item to be deleted.
    ///   - service: The Keychain Service attribute key for the service associated with this item.
    /// - Returns: An **OSStatus** code.
    @discardableResult
    static func deleteItem(withKey key: String, service: Service) -> OSStatus {
        let query: NSDictionary = [
            "\(kSecClass)": kSecClassGenericPassword,
            "\(kSecAttrAccount)": key + client,
            "\(kSecAttrService)": service.rawValue
        ]
        return SecItemDelete(query)
    }
    
    /// Updates the item matching the specified key in the keychain.
    /// - Parameters:
    ///   - item: The item to be updated.
    ///   - key: The key associated with the item to be updated.
    ///   - service: The Keychain Service attribute key for the service associated with this item.
    /// - Returns: An **OSStatus** code.
    @discardableResult
    static func update(item: Codable, forKey key: String, service: Service) -> OSStatus {
        guard let data = item.encoded else {
            return errSecInvalidData
        }
        let query: NSDictionary = [
            "\(kSecClass)": kSecClassGenericPassword,
            "\(kSecAttrAccount)": key + client,
            "\(kSecAttrService)": service.rawValue
        ]
        let value: NSDictionary = ["\(kSecValueData)": data]
        return SecItemUpdate(query, value)
    }
}

extension Encodable {
    fileprivate var encoded: Data? { try? JSONEncoder().encode(self) }
}
