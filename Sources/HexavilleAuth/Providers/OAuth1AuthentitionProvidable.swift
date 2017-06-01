//
//  OAuth1AuthentitionProvidable.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public protocol OAuth1AuthentitionProvidable {
    var path: String { get }
    var oauth: OAuth1 { get }
    var callback: RespodWithCredential { get }
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential)
    func getRequestToken() throws -> RequestToken
    func createAuthorizeURL(requestToken: RequestToken) throws -> URL
    func getAccessToken(request: Request, requestToken: RequestToken) throws -> Credential
}

extension OAuth1AuthentitionProvidable {
    public func getRequestToken() throws -> RequestToken {
        return try oauth.getRequestToken()
    }
    
    public func createAuthorizeURL(requestToken: RequestToken) throws -> URL {
        return try oauth.createAuthorizeURL(requestToken: requestToken)
    }
    
    public func getAccessToken(request: Request, requestToken: RequestToken) throws -> Credential {
        return try self.oauth.getAccessToken(request: request, requestToken: requestToken)
    }
}

