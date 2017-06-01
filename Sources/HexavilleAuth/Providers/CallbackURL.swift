//
//  CallbackURL.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation

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
