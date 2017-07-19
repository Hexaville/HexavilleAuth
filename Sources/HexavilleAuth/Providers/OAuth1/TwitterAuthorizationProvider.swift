//
//  TwitterAuthorizationProvider.swift
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

public struct TwitterAuthorizationProvider: OAuth1AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth1
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])? = nil, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth1(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl: "https://api.twitter.com/oauth/authenticate",
            accessTokenUrl: "https://api.twitter.com/oauth/access_token",
            callbackURL: callbackURL,
            blockForCallbackURLQueryParams: blockForCallbackURLQueryParams,
            withAllowedCharacters: .twitterQueryAllowed
        )
        
        self.callback = callback
    }
    
    public func authorize(request: Request, requestToken: RequestToken) throws -> (Credential, LoginUser)  {
        let credential = try self.getAccessToken(request: request, requestToken: requestToken)
        let info = try self.oauth.verify(credential: credential, verifyURL: "https://api.twitter.com/1.1/account/verify_credentials.json")
        
        let user = LoginUser(
            id: info["id_str"] as? String ?? "",
            name: info["screen_name"] as? String ?? "",
            screenName: info["name"] as? String,
            picture: info["profile_image_url_https"] as? String,
            raw: info
        )
        return (credential, user)
    }
}

