//
//  TwitterAuthenticationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

internal extension CharacterSet {
    static var twitterQueryAllowed: CharacterSet {
        var alphaNumericSet: CharacterSet = .alphanumerics
        alphaNumericSet.insert(charactersIn: "_-.~") //https://dev.twitter.com/oauth/overview/percent-encoding-parameters
        return alphaNumericSet
    }
}

public struct TwitterAuthenticationProvider: OAuth1AuthentitionProvidable {
    
    public let path: String
    
    public let oauth: OAuth1
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth1(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl: "https://api.twitter.com/oauth/authenticate",
            accessTokenUrl: "https://api.twitter.com/oauth/access_token",
            callbackURL: callbackURL,
            withAllowedCharacters: .twitterQueryAllowed
        )
        
        self.callback = callback
    }
}

