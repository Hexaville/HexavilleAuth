//
//  GithubAuthorizationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public enum GithubAuthorizationProviderError: Error {
    case bodyShouldBeAJSON
}

public struct GithubAuthorizationProvider: OAuth2AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])? = nil, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "http://github.com/login/oauth/authorize",
            accessTokenURL: "https://github.com/login/oauth/access_token",
            callbackURL: callbackURL,
            blockForCallbackURLQueryParams: blockForCallbackURLQueryParams,
            scope: scope
        )
        
        self.callback = callback
    }
    
    public func authorize(for request: Request) throws -> (Credential, LoginUser)  {
        let credential = try self.getAccessToken(for: request)
        let url = URL(string: "https://api.github.com/user?access_token=\(credential.accessToken)")!
        let (response, body) = try HTTPClient().send(url: url)
        
        guard (200..<300).contains(response.statusCode) else {
            throw HexavilleAuthError.responseError(response, body)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: body, options: []) as? [String: Any] else {
            throw GithubAuthorizationProviderError.bodyShouldBeAJSON
        }
        
        let user = LoginUser(
            id: String(json["id"] as? Int ?? 0),
            name: json["login"] as? String ?? "",
            screenName: json["name"] as? String,
            email: json["email"] as? String,
            picture: json["avatar_url"] as? String,
            raw: json
        )
        return (credential, user)
    }
}

