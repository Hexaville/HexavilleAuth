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
    case verifyFailed(Request, Response)
    case failedToGetAccessToken(Request, Response)
    case failedToGetRequestToken(Request, Response)
}

extension OAuth1Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .couldNotGenerateSignature:
            return "couldNotGenerateSignature"
            
        case .invalidAuthrozeURL(let url):
            return "invalidAuthrozeURL: \(url)"
            
        case .missingRequiredParameters(let param):
            return "missingRequiredParameter: \(param)"
            
        case .accessTokenIsMissingInSession:
            return "accessTokenIsMissingInSession"
            
        case .verifyFailed(let req, let res):
            return stringify(code: "verifyFailed", request: req, response: res)
            
        case .failedToGetAccessToken(let req, let res):
            return stringify(code: "failedToGetAccessToken", request: req, response: res)
            
        case .failedToGetRequestToken(let req, let res):
            return stringify(code: "failedToGetRequestToken", request: req, response: res)
        }
    }
    
    private func stringify(code: String, request: Request, response: Response) -> String {
        var requestHeaders: [String: String] = [:]
        for (key, value) in request.headers {
            requestHeaders[key.description] = value
        }
        
        var responseHeaders: [String: String] = [:]
        for (key, value) in response.headers {
            responseHeaders[key.description] = value
        }
        
        let requestDict: [String: Any] = [
            "method": request.method.rawValue,
            "url": request.url.absoluteString,
            "headers": requestHeaders,
            "body": String(data: request.body.asData(), encoding: .utf8) ?? ""
        ]
        
        let responseDict: [String: Any] = [
            "statusCode": response.statusCode,
            "headers": responseHeaders,
            "body": String(data: response.body.asData(), encoding: .utf8) ?? ""
        ]
        
        do {
            let json = try JSONSerialization.data(
                withJSONObject: [
                    "errorCode": code,
                    "request": requestDict,
                    "response": responseDict
                ],
                options: [.prettyPrinted]
            )
            return String(data: json, encoding: .utf8) ?? ""
        } catch {
            return "\(error)"
        }
    }
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
        
        let authorizationValue = OAuth1.oAuthAuthorizationString(fromParameters: params, withAllowedCharacters: withAllowedCharacters)
        
        let request = Request(
            method: .post,
            url: URL(string: requestTokenUrl)!,
            headers: ["Authorization": authorizationValue]
        )
        let client = try HTTPClient(url: request.url)
        try client.open()
        let response = try client.request(request)
        
        guard (200..<300).contains(response.statusCode) else {
            throw OAuth1Error.failedToGetRequestToken(request, response)
        }
        
        let bodyDictionary = OAuth1.parse(bodyData: response.body.asData())
        
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
    
    public func verify(credential: Credential, verifyURL: String) throws -> [String: Any] {
        var params = [
            "oauth_consumer_key" : consumerKey,
            "oauth_nonce" : OAuth1.generateNonce(),
            "oauth_signature_method" : "HMAC-SHA1",
            "oauth_timestamp" : String(Int64(Date().timeIntervalSince1970)),
            "oauth_token" : credential.accessToken,
            "oauth_version" : "1.0A"
        ]
        
        guard let sig = signature(
            method: "GET",
            urlString: verifyURL,
            parameters: params,
            oauthToken: credential.raw["oauth_token_secret"] as? String,
            withAllowedCharacters: withAllowedCharacters
            ) else {
                throw OAuth1Error.couldNotGenerateSignature
        }
        
        params["oauth_signature"] = sig
        
        let authrozationString = OAuth1.oAuthAuthorizationString(fromParameters: params, withAllowedCharacters: withAllowedCharacters)
        
        let request = Request(
            method: .get,
            url: URL(string: verifyURL)!,
            headers: ["Authorization": authrozationString]
        )
        
        let client = try HTTPClient(url: request.url)
        try client.open()
        let response = try client.request(request)
        
        guard (200..<300).contains(response.statusCode) else {
            throw OAuth1Error.verifyFailed(request, response)
        }
        
        return try JSONSerialization.jsonObject(with: response.body.asData(), options: []) as? [String: Any] ?? [:]
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
        
        let authrozationString = OAuth1.oAuthAuthorizationString(fromParameters: params, withAllowedCharacters: withAllowedCharacters)
        
        let request = Request(
            method: .post,
            url: URL(string: urlString)!,
            headers: ["Authorization": authrozationString]
        )
        
        let client = try HTTPClient(url: request.url)
        try client.open()
        let response = try client.request(request)
        
        guard (200..<300).contains(response.statusCode) else {
            throw OAuth1Error.failedToGetAccessToken(request, response)
        }
        
        return try Credential(withDictionary: OAuth1.parse(bodyData: response.body.asData()))
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
        
        let encodedString = String(bytes: Base64Encoder.shared.encode(encodedRawBytes), encoding: .utf8) ?? ""
        
        return encodedString.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters)!
    }
}
