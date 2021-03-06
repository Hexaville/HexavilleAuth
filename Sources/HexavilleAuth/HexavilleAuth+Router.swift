//
//  HexavilleAuth+Router.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/06/25.
//
//

import Foundation
import HexavilleFramework

extension HexavilleAuth {
    func asRouter() -> Router {
        var router = Router()
        for type in providers {
            switch type {
            case .oauth1(let provider):
                router.use(.GET, provider.path) { request, context in
                    let requestToken = try provider.getRequestToken(for: request)
                    context.session?["hexaville.oauth_token_secret"] = requestToken.oauthTokenSecret
                    context.session?["hexaville.oauth_token"] = requestToken.oauthToken
                    let location = try provider.createAuthorizeURL(requestToken: requestToken).absoluteString
                    
                    var headers = context.responseHeaders
                    headers.add(name: "Location", value: location)
                    return Response(status: .found, headers: headers)
                }
                
                router.use(.GET, provider.oauth.callbackURL.path) { request, context in
                    guard let secret = context.session?["hexaville.oauth_token_secret"] as? String else {
                        throw OAuth1Error.accessTokenIsMissingInSession
                    }
                    
                    guard let token = context.session?["hexaville.oauth_token"] as? String else {
                        throw OAuth1Error.accessTokenIsMissingInSession
                    }
                    
                    let requestToken = RequestToken(
                        oauthToken: token,
                        oauthTokenSecret: secret,
                        oauthCallbackConfirmed: nil
                    )
                    
                    let (cred, user) = try provider.authorize(request: request, requestToken: requestToken)
                    context.session?[AuthenticationMiddleware.sessionKey] = user.serialize()
                    return try provider.callback(cred, user, request, context)
                }
                
                
            case .oauth2(let provider):
                router.use(.GET, provider.path) { request, context in
                    return Response(
                        status: .found,
                        headers: [
                            "Location": try provider.createAuthorizeURL(for: request).absoluteString
                        ]
                    )
                }
                
                router.use(.GET, provider.oauth.callbackURL.path) { request, context in
                    let (cred, user) = try provider.authorize(for: request)
                    context.session?[AuthenticationMiddleware.sessionKey] = user.serialize()
                    return try provider.callback(cred, user, request, context)
                }
            }
        }
        
        return router
    }
}

extension HexavilleFramework {
    public func use(_ auth: HexavilleAuth) {
        self.use(auth.asRouter())
    }
}
