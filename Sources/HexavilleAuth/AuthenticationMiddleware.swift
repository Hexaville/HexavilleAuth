//
//  AuthenticationMiddleware.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/06/25.
//
//

import Foundation
import HexavilleFramework


extension HexavilleAuth {
    public struct AuthenticationMiddleware: Middleware {
        
        public init(){}
        
        static var sessionKey = "hexaville.auth.loginUser"
        
        public func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
            if let dict = context.session?[AuthenticationMiddleware.sessionKey] as? [String: Any] {
                context.loginUser = try LoginUser(fromDictionary: dict)
            }
            
            return .next(request)
        }
    }

}
