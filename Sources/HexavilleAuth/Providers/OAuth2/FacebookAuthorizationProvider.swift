//
//  FacebookAuthorizationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/30.
//
//

import Foundation
import HexavilleFramework

public struct FacebookAuthorizationProvider: OAuth2AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "https://www.facebook.com/dialog/oauth",
            accessTokenURL: "https://graph.facebook.com/oauth/access_token",
            callbackURL: callbackURL,
            scope: scope
        )
        
        self.callback = callback
    }
}
