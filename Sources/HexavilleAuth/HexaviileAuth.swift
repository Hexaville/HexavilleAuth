import Foundation
import HexavilleFramework

public enum HexavilleAuthError: Error {
    case unsupportedPlaform
    case codeIsMissingInResponseParameters
    case responseError(Response)
}

public enum CredentialProviderType {
    case oauth2(OAuth2AuthorizationProvidable)
    case oauth1(OAuth1AuthorizationProvidable)
}

extension ApplicationContext {
    public func isAuthenticated() -> Bool {
        return loginUser != nil
    }
    
    public var loginUser: LoginUser? {
        get {
            return memory[AuthenticationMiddleware.sessionKey] as? LoginUser
        }
        set {
            return memory[AuthenticationMiddleware.sessionKey] = newValue
        }
    }
}

public struct AuthenticationMiddleware: Middleware {
    
    static var sessionKey = "hexaville.auth.loginUser"
    
    public func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        if let dict = context.session?[AuthenticationMiddleware.sessionKey] as? [String: Any] {
            context.loginUser = try LoginUser(fromDictionary: dict)
        }
        
        return .next(request)
    }
}

public struct HexavilleAuth {
    var providers: [CredentialProviderType] = []
    
    public init() {}
    
    public mutating func add(_ provider: OAuth1AuthorizationProvidable) {
        self.providers.append(.oauth1(provider))
    }
    
    public mutating func add(_ provider: OAuth2AuthorizationProvidable) {
        self.providers.append(.oauth2(provider))
    }
    
    public func authenticationMiddleware() -> Middleware {
        return AuthenticationMiddleware()
    }
    
    public func asRouter() -> Router {
        let router = Router()
        for type in providers {
            switch type {
            case .oauth1(let provider):
                router.use(.get, provider.path) { request, context in
                    let requestToken = try provider.getRequestToken()
                    context.session?["hexaville.oauth_token_secret"] = requestToken.oauthTokenSecret
                    context.session?["hexaville.oauth_token"] = requestToken.oauthToken
                    let location = try provider.createAuthorizeURL(requestToken: requestToken).absoluteString
                    
                    return Response(status: .found, headers: ["Location": location])
                }
                
                router.use(.get, provider.oauth.callbackURL.path) { request, context in
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
                router.use(.get, provider.path) { request, context in
                    return Response(
                        status: .found,
                        headers: [
                            "Location": try provider.createAuthorizeURL().absoluteString
                        ]
                    )
                }
                
                router.use(.get, provider.oauth.callbackURL.path) { request, context in
                    let (cred, user) = try provider.authorize(request: request)
                    context.session?[AuthenticationMiddleware.sessionKey] = user.serialize()
                    return try provider.callback(cred, user, request, context)
                }
            }
        }
        
        return router
    }
}
