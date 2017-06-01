//
//  Credential.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public enum CredentialError: Error {
    case couldNotFindAccessTokenInResponse
}

public struct Credential {
    public let accessToken: String
    public let tokenType: String?
    public let refreshToken: String?
    public let expiresAt: Date?
    public let raw: [String: Any]
}

extension Credential {
    public init(withDictionary params: [String: Any]) throws {
        if let accessToken = params["code"] as? String {
            self.accessToken = accessToken
        } else if let accessToken = params["access_token"] as? String {
            self.accessToken = accessToken
        } else if let accessToken = params["oauth_token"] as? String {
            self.accessToken = accessToken
        } else {
            throw CredentialError.couldNotFindAccessTokenInResponse
        }
        
        self.tokenType = params["token_type"] as? String
        self.refreshToken = params["refresh_token"] as? String
        
        if let expiresIn = params["expires_in"] as? Double {
            self.expiresAt = Date(timeInterval: expiresIn, since: Date())
        } else {
            self.expiresAt = nil
        }
        self.raw = params
    }
    
    public init(withQueryItems queryItems: [URLQueryItem]) throws {
        var params: [String: String] = [:]
        for item in queryItems {
            guard let value = item.value else { continue }
            params[item.name] = value
        }
        try self.init(withDictionary: params)
    }
}
