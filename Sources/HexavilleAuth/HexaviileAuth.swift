import Foundation
import HexavilleFramework

public enum HexavilleAuthError: Error {
    case unsupportedPlaform
    case codeIsMissingInResponseParameters
    case responseError(Response)
}

extension HexavilleAuthError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .responseError(let response):
            var str = ""
            str += "\(response)"
            str += "\n"
            str += "\n"
            str += String(data: response.body.asData(), encoding: .utf8) ?? "Unknown Error"
            return str
            
        default:
            return "\(self)"
        }
    }
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
}

extension ApplicationContext {
    public func isAuthenticated() -> Bool {
        return loginUser != nil
    }
    
    public var loginUser: LoginUser? {
        get {
            return memory[HexavilleAuth.AuthenticationMiddleware.sessionKey] as? LoginUser
        }
        set {
            return memory[HexavilleAuth.AuthenticationMiddleware.sessionKey] = newValue
        }
    }
}
