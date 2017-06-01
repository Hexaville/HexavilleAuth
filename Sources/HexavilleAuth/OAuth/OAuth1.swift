//
//  OAuth1.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework
import CLibreSSL

public enum OAuth1Error: Error {
    case couldNotGenerateSignature
    case invalidAuthrozeURL(String)
    case missingRequiredParameters(String)
    case accessTokenIsMissingInSession
}

public struct RequestToken {
    let oauthToken: String
    let oauthTokenSecret: String
    let oauthCallbackConfirmed: Bool?
}

public class OAuth1 {
    var allowMissingOAuthVerifier: Bool = false
    let consumerKey: String
    let consumerSecret: String
    let requestTokenUrl: String
    let authorizeUrl: String
    let accessTokenUrl: String
    let callbackURL: CallbackURL
    let withAllowedCharacters: CharacterSet
    
    public init(consumerKey: String, consumerSecret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String, callbackURL: CallbackURL, withAllowedCharacters: CharacterSet = CharacterSet.alphanumerics) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.requestTokenUrl = requestTokenUrl
        self.authorizeUrl = authorizeUrl
        self.accessTokenUrl = accessTokenUrl
        self.callbackURL = callbackURL
        self.withAllowedCharacters = withAllowedCharacters
    }
    
    private func dictionary2Query(_ dict: [String: String]) -> String {
        return dict.map({ "\($0.key)=\($0.value)" }).joined(separator: "&")
    }
    
    public func getRequestToken() throws -> RequestToken {
        var params = [
            "oauth_callback": callbackURL.absoluteURL()!.absoluteString,
            "oauth_consumer_key": consumerKey,
            "oauth_nonce": OAuth1.generateNonce(),
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(Int64(Date().timeIntervalSince1970)),
            "oauth_version": "1.0A"
        ]
        
        guard let sig = signature(method: "POST", urlString: requestTokenUrl, parameters: params, withAllowedCharacters: withAllowedCharacters) else {
            throw OAuth1Error.couldNotGenerateSignature
        }
        
        params["oauth_signature"] = sig
        
        var urlRequest = URLRequest(url: URL(string: requestTokenUrl)!)
        urlRequest.httpMethod = "POST"
        
        urlRequest.addValue(OAuth1.oAuthAuthorizationString(fromParameters: params, withAllowedCharacters: withAllowedCharacters), forHTTPHeaderField: "Authorization")
        
        let (response, data) = try URLSession.shared.resumeSync(with: urlRequest)
        
        let bodyDictionary = OAuth1.parse(bodyData: data)
        
        guard (200..<300).contains(response.statusCode) else {
            throw HexavilleAuthError.responseError(response.transform(withBodyData: data))
        }
        
        guard let oauthToken = bodyDictionary["oauth_token"] else {
            throw OAuth1Error.missingRequiredParameters("oauth_token")
        }
        
        guard let oauthTokenSecret = bodyDictionary["oauth_token_secret"] else {
            throw OAuth1Error.missingRequiredParameters("oauth_token_secret")
        }
        
        var oauthCallbackConfirmed: Bool?
        if let occ = bodyDictionary["oauth_callback_confirmed"] {
            if occ == "true" {
                oauthCallbackConfirmed = true
            } else {
                oauthCallbackConfirmed = false
            }
        }
        
        return RequestToken(
            oauthToken: oauthToken,
            oauthTokenSecret: oauthTokenSecret,
            oauthCallbackConfirmed: oauthCallbackConfirmed
        )
    }
    
    public func createAuthorizeURL(requestToken: RequestToken) throws -> URL {
        return URL(string: self.authorizeUrl+"?oauth_token="+requestToken.oauthToken)!
    }
    
    public func getAccessToken(request: Request, requestToken: RequestToken) throws -> Credential {
        guard let oauthToken = request.queryItems.filter({ $0.name == "oauth_token" }).first?.value else {
            throw OAuth1Error.missingRequiredParameters("oauth_token")
        }
        
        guard let oauthVerifier = request.queryItems.filter({ $0.name == "oauth_verifier" }).first?.value else {
            throw OAuth1Error.missingRequiredParameters("oauth_verifier")
        }
        
        var params = [
            "oauth_consumer_key": consumerKey,
            "oauth_nonce": OAuth1.generateNonce(),
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(Int64(Date().timeIntervalSince1970)),
            "oauth_token": oauthToken,
            "oauth_version": "1.0A",
            "oauth_verifier": oauthVerifier
        ]
        
        let urlString = "\(accessTokenUrl)?oauth_verifier=\(oauthVerifier)"
        
        guard let sig = signature(
            method: "POST",
            urlString: urlString,
            parameters: params,
            oauthToken: requestToken.oauthTokenSecret,
            withAllowedCharacters: withAllowedCharacters
        ) else {
            throw OAuth1Error.couldNotGenerateSignature
        }
        
        params["oauth_signature"] = sig
        
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.httpMethod = "POST"
        
        urlRequest.addValue(OAuth1.oAuthAuthorizationString(fromParameters: params, withAllowedCharacters: withAllowedCharacters), forHTTPHeaderField: "Authorization")
        
        let (response, data) = try URLSession.shared.resumeSync(with: urlRequest)
        
        guard (200..<300).contains(response.statusCode) else {
            throw HexavilleAuthError.responseError(response.transform(withBodyData: data))
        }
        
        return try Credential(withDictionary: OAuth1.parse(bodyData: data))
    }
}


extension OAuth1 {
    static func parse(bodyData data: Data) -> [String: String] {
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        var bodyDictionary: [String: String] = [:]
        bodyString.components(separatedBy: "&").forEach {
            let components = $0.components(separatedBy: "=")
            guard components.count > 1 else { return }
            bodyDictionary[components[0]] = components[1]
        }
        
        return bodyDictionary
    }
    
    static func generateNonce() -> String {
        return UUID().uuidString.components(separatedBy: "-")[0]
    }
    
    static func oAuthAuthorizationString(fromParameters parameters: [String : String], withAllowedCharacters: CharacterSet = CharacterSet.alphanumerics) -> String {
        var keyValues = [String]()
        var parameters = parameters
        
        let a = parameters.removeValue(forKey: "oauth_signature")!
        
        for (key, value) in parameters.sorted(by: {$0.0 < $1.0}) {
            keyValues.append("\(key)=\"\(value.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters)!)\"")
        }
        
        keyValues.append("oauth_signature=\"\(a)\"")
        
        return "OAuth \(keyValues.joined(separator: ","))"
    }
    
    public func signature(method: String, urlString: String, parameters: [String: String], oauthToken: String? = nil, withAllowedCharacters: CharacterSet = CharacterSet.alphanumerics) -> String? {
        
        var keyValues = [String]()
        for (key, value) in parameters {
            keyValues.append("\(key)=\(value.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters)!)")
        }
        
        let sortedParameters = keyValues.sorted(by: <)
        
        let joinedParameters = sortedParameters.joined(separator: "&")
        guard let percentEncodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters),
            let percentEncodedJoinedParameters = joinedParameters.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters),
            let percentEncodedConsumerSecret = consumerSecret.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters) else {
                return nil
        }
        
        let rawString = [method, percentEncodedUrl, percentEncodedJoinedParameters].joined(separator: "&")
        let encodedRawBytes =  hmacsha1(string: rawString, key: (percentEncodedConsumerSecret + "&" + (oauthToken ?? "")).bytes)
        
        let encodedData = Data(bytes: encodedRawBytes)
        let encodedString = encodedData.base64EncodedString()
        
        return encodedString.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters)!
    }
}
