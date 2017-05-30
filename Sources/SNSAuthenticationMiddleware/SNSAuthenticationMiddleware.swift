import Foundation
import HexavilleFramework

public enum SNSAuthenticationMiddlewareError: Error {
    case unsupportedPlaform
    case codeIsMissingInResponseParameters
    case responseError(Response)
}

public struct SNSAuthenticationMiddleware: Middleware {
    var providers: [OAuth2AuthentitionProvidable] = []
    
    var callbackHandler: RespodWithCredential?

    public init() {}
    
    public mutating func add(_ provider: OAuth2AuthentitionProvidable) {
        self.providers.append(provider)
    }

    public func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        let currentPath = request.path ?? "/"
        
        for provider in providers {
            if provider.path == currentPath {
                let response = Response(
                    status: .found,
                    headers: [
                        "Location": provider.createAuthorizeURL().absoluteString
                    ]
                )
                return .respond(to: response)
            }
            
            if let url = URL(string: provider.oauth.callbackURL), url.path == currentPath {
                let cred = try provider.getAccessToken(request: request)
                return .respond(to: try provider.callback(cred, request, context))
            }
        }
        
        return .next(request)
    }
    
    public mutating func callback(_ handler: @escaping RespodWithCredential) {
        self.callbackHandler = handler
    }
}
