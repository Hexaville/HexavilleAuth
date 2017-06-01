//
//  LoginUser.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/06/01.
//
//

import Foundation

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
}
