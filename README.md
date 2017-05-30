# SNSAuthenticationMiddleware for Hexaville

SNSAuthenticationMiddleware is an authentication middleware for [Hexaville](https://github.com/noppoMan/Hexaville). 

SNSAuthenticationMiddleware recognizes that each application has unique authentication requirements. It allows individual authentication mechanisms to be packaged as plugins which it consumes. SNSAuthenticationMiddleware automatically creates resources for authorize/callback for each sns platforms, So you can embed sns authentication features into your Hexaville application very quickly.



## Supported SNS Platforms

### OAuth2

* [x] Facebook
* [x] Github
* [x] Google
* [x] Instagram

### OAuth1
* [ ] Twitter

## Installation

Just add `.Package(url: "https://github.com/Hexaville/SNSAuthenticationMiddleware.git", majorVersion: 0, minor: 1)` into your Package.swift

```swift
import PackageDescription

let package = Package(
    name: "MyHexavilleApplication",
    dependencies: [
        .Package(url: "https://github.com/Hexaville/SNSAuthenticationMiddleware.git", majorVersion: 0, minor: 1)
    ]
)
```

## Usage

Here is an example code for facebook oauth authentication with [HexavilleFramework](https://github.com/noppoMan/HexavilleFramework)

```swift
import Foundation
import SNSAuthenticationMiddleware
import HexavilleFramework

let app = HexavilleFramework()

var middleware = SNSAuthenticationMiddleware()

let facebookProvider = FacebookAuthenticationProvider(
    path: "/auth/facebook",
    consumerKey: ProcessInfo.processInfo.environment["FACEBOOK_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["FACEBOOK_APP_SECRET"] ?? "",
    callbackURL: "\(APP_URL)/auth/facebook/callback",
    scope: "public_profile"
) { credential, request, context in
    
    // here is called when the access_token got successfully from sns.
    
    return Response(body: "\(credential)")
}

middleware.add(facebookProvider)

app.use(middleware)

app.catch { error in
    switch error {
    case SNSAuthenticationMiddlewareError.responseError(let response):
        return Response(body: response.body.asData())
    default:
        return Response(body: "\(error)")
    }
}

try app.run()
```

## Try Example!

[Here is an official full example code](https://github.com/Hexaville/SNSAuthenticationMiddleware/blob/master/Sources/SNSAuthenticationMiddlewareExample/main.swift).

### Install and Build Example

```sh
git clone https://github.com/Hexaville/SNSAuthenticationMiddleware.git
cd SNSAuthenticationMiddleware
cd swift build
```

### Launch Server

```sh
./.build/debug/SNSAuthenticationMiddlewareExample

# => Hexaville Builtin Server started at 0.0.0.0:3000
```

### Resources

Try to access following resources to authentication with Browser!

* Facebook: http://yourlocaldomain:3000/auth/facebook
* Github: http://yourlocaldomain:3000/auth/github
* Instagram: http://yourlocaldomain:3000/auth/instagram
* Google: http://yourlocaldomain:3000/auth/google

# Create Your Custom Authentication Provider

You can create Custom Authentication Provider with `OAuthXAuthentitionProvidable`

## Oauth2

#### OAuth2AuthentitionProvidable
```swift
public protocol OAuth2AuthentitionProvidable {
    var path: String { get } // path for authorize
    var oauth: OAuth2 { get }
    var callback: RespodWithCredential { get }  // callback for success handler
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: String, scope: String, callback: @escaping RespodWithCredential)
    func getAccessToken(request: Request) throws -> Credential
}
```

here is an example for Salesforce Authentication.

```swift
public struct SalesforceAuthenticationProvider: OAuth2AuthentitionProvidable {
    
    public let path: String
    
    public let oauth: OAuth2
    
    public let callback: RespodWithCredential
    
    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: String, scope: String, callback: @escaping RespodWithCredential) {
        self.path = path
        
        self.oauth = OAuth2(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeURL: "https://login.salesforce.com/services/oauth2/authorize",
            accessTokenURL: "https://login.salesforce.com/services/oauth2/token",
            callbackURL: callbackURL,
            scope: scope
        )
        
        self.callback = callback
    }
}
```

Use it!
```swift
var middleware = SNSAuthenticationMiddleware()

let salesforceProvider = SalesforceAuthenticationProvider(
    path: "/auth/salesforce",
    consumerKey: "consumer",
    consumerSecret: "secret",
    callbackURL: "\(APP_URL)/auth/salesforce/callback",
    scope: "public_profile"
) { credential, request, context in

    try DB.save(token: credential.accessToken)
    
    return Response(body: "\(credential)")
}

middleware.add(salesforceProvider)
```

## License

SNSAuthenticationMiddleware is released under the MIT license. See LICENSE for details.
