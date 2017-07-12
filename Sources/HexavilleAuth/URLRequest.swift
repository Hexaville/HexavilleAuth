//
//  URLRequest.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/07/12.
//
//

import Foundation
import Prorsum

extension Request.Method {
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "get":
            self = .get
        case "post":
            self = .post
        case "put":
            self = .put
        case "patch":
            self = .patch
        case "delete":
            self = .delete
        case "head":
            self = .head
        default:
            self = .other(method: rawValue)
        }
    }
    
    var rawValue: String {
        switch self {
        case .other(method: let method):
            return method.uppercased()
        default:
            return "\(self)".uppercased()
        }
    }
}

extension URLRequest {
    func transform() -> Request {
        var headers: Headers = [:]
        for (key, value) in self.allHTTPHeaderFields ?? [:] {
            headers[key] = value
        }
        let method = Request.Method(rawValue: self.httpMethod ?? "get")
        return Request(
            method: method,
            url: self.url!,
            headers: headers,
            body: self.httpBody ?? Data()
        )
    }
}

