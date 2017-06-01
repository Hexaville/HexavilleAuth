//
//  OAuth2AuthorizationProvidable.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public typealias RespodWithCredential = (Credential, Request, ApplicationContext) throws -> Response

public protocol OAuth2AuthorizationProvidable {
    var path: String { get }
    var oauth: OAuth2 { get }
    var callback: RespodWithCredential { get }
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential)
    func getAccessToken(request: Request) throws -> Credential
}

extension OAuth2AuthorizationProvidable {
    public func createAuthorizeURL() throws -> URL {
        return try oauth.createAuthorizeURL()
    }
    
    public func getAccessToken(request: Request) throws -> Credential {
        return try self.oauth.getAccessToken(request: request)
    }
}
