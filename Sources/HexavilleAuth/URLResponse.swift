//
//  URLResponse.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import Prorsum

extension HTTPURLResponse {
    func transform(withBodyData bodyData: Data) -> Response {
        var headers: Headers = [:]
        for el in allHeaderFields {
            headers[el.key.description] = "\(el.value)"
        }
        
        return Response(
            status: Response.Status(statusCode: statusCode),
            headers: headers,
            body: bodyData
        )
    }
}
