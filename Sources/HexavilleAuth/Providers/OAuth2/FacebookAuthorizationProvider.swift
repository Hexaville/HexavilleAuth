//
//  FacebookAuthorizationProvider.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/30.
//
//

import Foundation
import HexavilleFramework

public enum FacebookAuthorizationProviderError: Error {
    case bodyShouldBeAJSON
}

public struct FacebookAuthorizationProvider: OAuth2AuthorizationProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])? = nil, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "https://www.facebook.com/dialog/oauth",
            accessTokenURL: "https://graph.facebook.com/oauth/access_token",
            callbackURL: callbackURL,
            blockForCallbackURLQueryParams: blockForCallbackURLQueryParams,
            scope: scope
        )
        
        self.callback = callback
    }
    
    public func authorize(for request: Request) throws -> (Credential, LoginUser)  {
        let credential = try self.getAccessToken(for: request)
        
        let request = Request(
            method: .get,
            url: URL(string: "https://graph.facebook.com/me?fields=id,name,email,picture,gender&access_token=\(credential.accessToken)")!
        )
        
        let client = try HTTPClient(url: request.url)
        try client.open()
        let response = try client.request(request)
        
        guard (200..<300).contains(response.statusCode) else {
            throw HexavilleAuthError.responseError(response)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: response.body.asData(), options: []) as? [String: Any] else {
            throw FacebookAuthorizationProviderError.bodyShouldBeAJSON
        }
        
        var picture: String?
        if let _picture = json["picture"] as? [String: Any], let data = _picture["data"] as? [String: Any] {
            picture = data["url"] as? String
        }
        let user = LoginUser(
            id: json["id"] as? String ?? "",
            name: json["name"] as? String ?? "",
            screenName: json["name"] as? String,
            email: json["email"] as? String,
            picture: picture,
            raw: json
        )
        return (credential, user)
    }
}
