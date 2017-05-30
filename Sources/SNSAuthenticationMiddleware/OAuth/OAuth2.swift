//
//  OAuth2.swift
//  SNSAuthenticationMiddleware
//
//  Created by Yuki Takei on 2017/05/31.
//
//

import Foundation
import HexavilleFramework

public class OAuth2 {
    let consumerKey: String
    let consumerSecret: String
    let authorizeURL: String
    var accessTokenURL: String?
    let responseType: String
    let callbackURL: String
    let scope: String
    
    public init(consumerKey: String, consumerSecret: String, authorizeURL: String, accessTokenURL: String? = nil, responseType: String = "code", callbackURL: String, scope: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.authorizeURL = authorizeURL
        self.accessTokenURL = accessTokenURL
        self.responseType = responseType
        self.scope = scope
        self.callbackURL = callbackURL
    }
    
    private func dictionary2Query(_ dict: [String: String]) -> String {
        return dict.map({ "\($0.key)=\($0.value)" }).joined(separator: "&")
    }
    
    public func createAuthorizeURL() -> URL {
        let params = [
            "client_id": consumerKey,
            "redirect_uri": callbackURL,
            "response_type": responseType,
            "scope": scope
        ]
        
        let queryString = dictionary2Query(params)
        
        return URL(string: "\(authorizeURL)?\(queryString)")!
    }
    
    public func getAccessToken(request: Request) throws -> Credential {
        guard let code = request.queryItems.filter({ $0.name == "code" }).first?.value else {
            throw SNSAuthenticationMiddlewareError.codeIsMissingInResponseParameters
        }
        let urlString = self.accessTokenURL!
        let url = URL(string: urlString)!
        
        let body: [String] = [
            "client_id=\(self.consumerKey)",
            "client_secret=\(self.consumerSecret)",
            "code=\(code)",
            "grant_type=authorization_code",
            "redirect_uri=\(self.callbackURL)"
        ]
        
        print(body)
        
        let client = try HTTPClient(url: url)
        try client.open()
        let response = try client.request(
            method: .post,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: body.joined(separator: "&").data
        )
        
        guard (200..<300).contains(response.statusCode) else {
            throw SNSAuthenticationMiddlewareError.responseError(response)
        }
        
        do {
            let bodyDictionary = try JSONSerialization.jsonObject(with: response.body.asData(), options: []) as! [String: Any]
            return try Credential(withDictionary: bodyDictionary)
        } catch {
            throw error
        }
    }
    
}

