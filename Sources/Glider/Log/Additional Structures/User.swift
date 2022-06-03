//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// This struct represent the logged user of the SDK. It will be sent along
/// each event to the specified transport layers.
public struct User: Codable {
    
    // MARK: - Public Properties
    
    /// Id of the user.
    public var userId: String
    
    /// Email of the user.
    public var email: String?
    
    /// Username.
    public var username: String?
    
    /// IP Address.
    public var ipAddress: String?
    
    /// Additional data.
    public var data: [String: SerializableData]?
    
    // MARK: - Initialization
    
    /// Initialize a new user with the id.
    ///
    /// - Parameter userId: id of the user.
    
    
    /// Initialize a new user with the id.
    ///
    /// - Parameters:
    ///   - userId: user id.
    ///   - email: user email.
    ///   - username: username.
    ///   - ipAddress: ip address.
    ///   - data: data.
    public init(userId: String,
                email: String? = nil,
                username: String? = nil,
                ipAddress: String? = nil,
                data: [String: SerializableData]? = nil) {
        self.userId = userId
        self.email = email
        self.username = username
        self.ipAddress = ipAddress
        self.data = data
    }
    
    // MARK: - Codable -
    
    enum CodingKeys: String, CodingKey {
        case userId, email, username, ipAddress, data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.username, forKey: .email)
        try container.encodeIfPresent(self.ipAddress, forKey: .ipAddress)
        
        if let encodableDict: [String: Data?] = data?.mapValues({ $0.asData() }) {
            let encodedData = try JSONSerialization.data(withJSONObject: encodableDict, options: .sortedKeys)
            try container.encodeIfPresent(encodedData, forKey: .data)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
        
        if let data = try container.decodeIfPresent(Data.self, forKey: .data) {
            let decodedData: [String: SerializableData]? = try JSONSerialization.jsonObject(with: data) as? [String: Data]
            self.data = decodedData
        } else {
            self.data = nil
        }
    }
    
}
