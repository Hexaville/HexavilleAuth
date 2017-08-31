//
//  OAuth2AuthorizationProvidable.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public typealias RespodWithCredential = (Credential, LoginUser, Request, ApplicationContext) throws -> Response

public protocol OAuth2AuthorizationProvidable {
    var path: String { get }
    var oauth: OAuth2 { get }
    var callback: RespodWithCredential { get }
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])?, scope: String, callback: @escaping RespodWithCredential)
    func getAccessToken(for: Request) throws -> Credential
    func authorize(for: Request) throws -> (Credential, LoginUser)
}

extension OAuth2AuthorizationProvidable {
    public func createAuthorizeURL(withCallbackURLQueryItems queryItems: [URLQueryItem]) throws -> URL {
        return try oauth.createAuthorizeURL(withCallbackURLQueryItems: queryItems)
    }
    
    public func getAccessToken(for request: Request) throws -> Credential {
        return try self.oauth.getAccessToken(for: request)
    }
}
