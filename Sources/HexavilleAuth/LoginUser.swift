//
//  LoginUser.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

public enum LoginUserError: Error {
    case missingRequiredParam(String)
}

public struct LoginUser {
    public let id: String
    public let name: String
    public let screenName: String?
    public let email: String?
    public let picture: String?
    public let raw: [String: Any]
    
    public init(id: String, name: String, screenName: String? = nil, email: String? = nil, picture: String? = nil, raw: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.screenName = screenName
        self.email = email
        self.picture = picture
        self.raw = raw
    }
    
    public init(fromDictionary dictionary: [String: Any]) throws {
        guard let id = dictionary["id"] as? String else {
            throw LoginUserError.missingRequiredParam("id")
        }
        
        guard let name = dictionary["name"] as? String else {
            throw LoginUserError.missingRequiredParam("name")
        }
        
        self.id = id
        self.name = name
        self.screenName = dictionary["screenName"] as? String
        self.email = dictionary["email"] as? String
        self.picture = dictionary["picture"] as? String
        self.raw = dictionary["raw"] as? [String: Any] ?? [:]
    }
    
    public func serialize() -> [String: Any] {
        var serialized: [String: Any] = [
            "id": id,
            "name": name,
            "raw": raw
        ]
        
        if let screenName = screenName {
            serialized["screenName"] = screenName
        }
        
        if let picture = picture {
            serialized["picture"] = picture
        }
        
        if let email = email {
            serialized["email"] = email
        }
        
        return serialized
    }
}
