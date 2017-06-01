//
//  GithubAuthenticationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public struct GithubAuthenticationProvider: OAuth2AuthentitionProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "http://github.com/login/oauth/authorize",
            accessTokenURL: "https://github.com/login/oauth/access_token",
            callbackURL: callbackURL,
            scope: scope
        )
        
        self.callback = callback
    }
}

