//
//  OAuth2.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public enum OAuth2Error: Error {
    case invalidAuthrozeURL(String)
}

public class OAuth2 {
    let consumerKey: String
    let consumerSecret: String
    let authorizeURL: String
    var accessTokenURL: String?
    let responseType: String
    let callbackURL: CallbackURL
    let blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])?
    let scope: String
    
    public init(consumerKey: String, consumerSecret: String, authorizeURL: String, accessTokenURL: String? = nil, responseType: String = "code", callbackURL: CallbackURL, blockForCallbackURLQueryParams: ((Request) -> [URLQueryItem])? = nil, scope: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.authorizeURL = authorizeURL
        self.accessTokenURL = accessTokenURL
        self.responseType = responseType
        self.scope = scope
        self.blockForCallbackURLQueryParams = blockForCallbackURLQueryParams
        self.callbackURL = callbackURL
    }
    
    private func dictionary2Query(_ dict: [String: String]) -> String {
        return dict.map({ "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)" }).joined(separator: "&")
    }
    
    public func createAuthorizeURL(for request: Request) throws -> URL {
        let queryItems = blockForCallbackURLQueryParams?(request) ?? []
        let params = [
            "client_id": consumerKey,
            "redirect_uri": callbackURL.absoluteURL(withQueryItems: queryItems)!.absoluteString,
            "response_type": responseType,
            "scope": scope
        ]
        
        let queryString = dictionary2Query(params)
        guard let url = URL(string: "\(authorizeURL)?\(queryString)") else {
            throw OAuth2Error.invalidAuthrozeURL("\(authorizeURL)?\(queryString)")
        }
        
        return url
    }
    
    public func getAccessToken(for request: Request) throws -> Credential {
        guard let code = request.queryItems.filter({ $0.name == "code" }).first?.value else {
            throw HexavilleAuthError.codeIsMissingInResponseParameters
        }
        let urlString = self.accessTokenURL!
        let url = URL(string: urlString)!
        let queryItems = blockForCallbackURLQueryParams?(request) ?? []
        let redirectURL = callbackURL
            .absoluteURL(withQueryItems: queryItems)!
            .absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let body: [String] = [
            "client_id=\(self.consumerKey)",
            "client_secret=\(self.consumerSecret)",
            "code=\(code)",
            "grant_type=authorization_code",
            "redirect_uri=\(redirectURL)"
        ]
        
        let request = Request(
            method: .post,
            url: url,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: body.joined(separator: "&").data
        )
        
        let client = try HTTPClient(url: request.url)
        try client.open()
        let response = try client.request(request)
        
        guard (200..<300).contains(response.statusCode) else {
            throw HexavilleAuthError.responseError(response)
        }
        
        do {
            let bodyDictionary = try JSONSerialization.jsonObject(with: response.body.asData(), options: []) as! [String: Any]
            return try Credential(withDictionary: bodyDictionary)
        } catch {
            throw error
        }
    }
    
}
