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

public struct HexavilleAuth {
    var providers: [CredentialProviderType] = []
    
    public init() {}
    
    public mutating func add(_ provider: OAuth1AuthorizationProvidable) {
        self.providers.append(.oauth1(provider))
    }
    
    public mutating func add(_ provider: OAuth2AuthorizationProvidable) {
        self.providers.append(.oauth2(provider))
    }
    
    public func asRouter() -> Router {
        let router = Router()
        for type in providers {
            switch type {
            case .oauth1(let provider):
                router.use(.get, provider.path) { request, context in
                    var request = request
                    let requestToken = try provider.getRequestToken()
                    request.session?["hexaville.oauth_token_secret"] = requestToken.oauthTokenSecret
                    request.session?["hexaville.oauth_token"] = requestToken.oauthToken
                    let location = try provider.createAuthorizeURL(requestToken: requestToken).absoluteString
                    
                    return Response(status: .found, headers: ["Location": location])
                }
                
                router.use(.get, provider.oauth.callbackURL.path) { request, context in
                    guard let secret = request.session?["hexaville.oauth_token_secret"] as? String else {
                        throw OAuth1Error.accessTokenIsMissingInSession
                    }
                    
                    guard let token = request.session?["hexaville.oauth_token"] as? String else {
                        throw OAuth1Error.accessTokenIsMissingInSession
                    }
                    
                    let requestToken = RequestToken(
                        oauthToken: token,
                        oauthTokenSecret: secret,
                        oauthCallbackConfirmed: nil
                    )
                    
                    let cred = try provider.getAccessToken(request: request, requestToken: requestToken)
                    return try provider.callback(cred, request, context)
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
                    let cred = try provider.getAccessToken(request: request)
                    return try provider.callback(cred, request, context)
                }
            }
        }
        
        return router
    }
}
