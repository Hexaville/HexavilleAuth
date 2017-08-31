//
//  InstagramAuthorizationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public struct InstagramAuthorizationProvider: OAuth2AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "https://api.instagram.com/oauth/authorize",
            accessTokenURL: "https://api.instagram.com/oauth/access_token",
            callbackURL: callbackURL,
            scope: scope
        )
        
        self.callback = callback
    }
    
    
    // TODO:
    // not implemented yet
    public func authorize(for request: Request) throws -> (Credential, LoginUser)  {
        let credential = try self.getAccessToken(for: request)
        let user = LoginUser(id: "", name: "")
        return (credential, user)
    }
}

