import Foundation
import HexavilleFramework

public enum HexavilleAuthError: Error {
    case unsupportedPlaform
    case codeIsMissingInResponseParameters
    case responseError(Response)
}

public struct HexavilleAuth {
    var providers: [OAuth2AuthentitionProvidable] = []
    
    public init() {}
    
    public mutating func add(_ provider: OAuth2AuthentitionProvidable) {
        self.providers.append(provider)
    }
    
    public func asRouter() -> Router {
        let router = Router()
        for provider in providers {
            router.use(.get, provider.path) { request, context in
                let response = Response(
                    status: .found,
                    headers: [
                        "Location": try provider.createAuthorizeURL().absoluteString
                    ]
                )
                return response
            }
            
            router.use(.get, provider.oauth.callbackURL.path) { request, context in
                let cred = try provider.getAccessToken(request: request)
                return try provider.callback(cred, request, context)
            }
        }
        
        return router
    }
}
