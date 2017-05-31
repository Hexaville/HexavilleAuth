//
//  OAuth2AuthentitionProvidable.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public struct CallbackURL {
    public let baseURL: String
    public let path: String
    
    public init(baseURL: String, path: String){
        self.baseURL = baseURL
        self.path = path
    }
    
    public func absoluteURL() -> URL? {
        return URL(string: "\(baseURL)\(path)")
    }
}

public typealias RespodWithCredential = (Credential, Request, ApplicationContext) throws -> Response

public protocol OAuth2AuthentitionProvidable {
    var path: String { get }
    var oauth: OAuth2 { get }
    var callback: RespodWithCredential { get }
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential)
    func getAccessToken(request: Request) throws -> Credential
}

extension OAuth2AuthentitionProvidable {
    public func createAuthorizeURL() throws -> URL {
        return try oauth.createAuthorizeURL()
    }
    
    public func getAccessToken(request: Request) throws -> Credential {
        return try self.oauth.getAccessToken(request: request)
    }
}
