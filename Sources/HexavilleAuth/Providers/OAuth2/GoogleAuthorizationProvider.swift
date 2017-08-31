//
//  GoogleAuthorizationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public struct GoogleAuthorizationProvider: OAuth2AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])? = nil, scope: String, callback: @escaping RespodWithCredential) {    
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "https://accounts.google.com/o/oauth2/auth",
            accessTokenURL: "https://accounts.google.com/o/oauth2/token",
            callbackURL: callbackURL,
            blockForCallbackURLQueryParams: blockForCallbackURLQueryParams,
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
