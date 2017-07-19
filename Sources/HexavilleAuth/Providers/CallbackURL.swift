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
    
    public func absoluteURL(withQueryItems queryItems: [URLQueryItem]) -> URL? {
        guard let url = absoluteURL() else { return nil }
        if queryItems.count > 0 {
            let additionalQuery = queryItems.filter({ $0.value != nil }).map({ "\($0.name)=\($0.value!)" }).joined(separator: "&")
            let separator = url.queryItems.count == 0 ? "?" : "&"
            return URL(string: url.absoluteString+separator+additionalQuery)
        }
        
        return url
    }
}
