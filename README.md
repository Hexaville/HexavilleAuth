# HexavilleAuth

HexavilleAuth is an Authentication(OAuth, simple password based) framework for [Hexaville](https://github.com/noppoMan/Hexaville).

HexavilleAuth recognizes that each application has unique authentication requirements. It allows individual authentication mechanisms to be packaged as plugins which it consumes.

Plugins can range from a simple password based authentication or, authentication using OAuth (via Facebook, Github OAuth provider, etc.).

HexavilleAuth automatically creates resources for authorize/callback for each sns platforms, So you can embed sns authentication features into your Hexaville application very quickly.


## Authentication Methods
* [ ] Email+password

## Authorization Methods
* [x] OAuth1
* [x] OAuth2

## Supported SNS Platforms

### OAuth2

* [x] Facebook
* [x] Github
* [x] Google
* [x] Instagram

### OAuth1
* [x] Twitter

## Installation

Just add `.Package(url: "https://github.com/Hexaville/HexavilleAuth.git", majorVersion: 0, minor: 1)` into your Package.swift

```swift
import PackageDescription

let package = Package(
    name: "MyHexavilleApplication",
    dependencies: [
        .Package(url: "https://github.com/Hexaville/HexavilleAuth.git", majorVersion: 0, minor: 1)
    ]
)
```

## Usage

Here is an example code for facebook oauth authorization with [HexavilleFramework](https://github.com/noppoMan/HexavilleFramework)

```swift
import Foundation
import HexavilleAuth
import HexavilleFramework

let app = HexavilleFramework()

var auth = HexavilleAuth()

let APP_URL = ProcessInfo.processInfo.environment["APP_URL"] ?? "http://localhost:3000"

let facebookProvider = FacebookAuthorizationProvider(
    path: "/auth/facebook",
    consumerKey: ProcessInfo.processInfo.environment["FACEBOOK_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["FACEBOOK_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/facebook/callback"),
    scope: "public_profile"
) { credential, request, context in

    // here is called when the access_token got successfully from sns.

    return Response(body: "\(credential)")
}

auth.add(facebookProvider)

app.use(auth.asRouter())

app.catch { error in
    switch error {
    case HexavilleAuthError.responseError(let response):
        return Response(body: response.body.asData())
    default:
        return Response(body: "\(error)")
    }
}

try app.run()
```

## Try Example!

[Here is an official full example code](https://github.com/Hexaville/HexavilleAuth/blob/master/Sources/HexavilleAuthExample/main.swift).

### Install and Build Example

```sh
git clone https://github.com/Hexaville/HexavilleAuth.git
cd HexavilleAuth
cd swift build
```

### Launch Server

```sh
./.build/debug/HexavilleAuthExample

# => Hexaville Builtin Server started at 0.0.0.0:3000
```

### Resources

Try to access following resources to authentication/authorization with Browser!

* Facebook: http://yourlocaldomain:3000/auth/facebook
* Github: http://yourlocaldomain:3000/auth/github
* Instagram: http://yourlocaldomain:3000/auth/instagram
* Google: http://yourlocaldomain:3000/auth/google

# Create Your Custom Authorization/Authentication Provider

You can create Custom Authorization/Authentication Provider with `OAuthXAuthorizationProvidable`/ `AuthenticationProvidable`

## Oauth2

#### OAuth2Authorization
```swift
public protocol OAuth2AuthorizationProvidable {
    var path: String { get } // path for authorize
    var oauth: OAuth2 { get }
    var callback: RespodWithCredential { get }  // callback for success handler
    init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential)
    func getAccessToken(request: Request) throws -> Credential
}
```

here is an example for Salesforce Authorization.

```swift
public struct SalesforceAuthorizationProvider: OAuth2AuthorizationProvidable {

    public let path: String

    public let oauth: OAuth2

    public let callback: RespodWithCredential

    public init(path: String, consumerKey: String, consumerSecret: String, callbackURL: CallbackURL, scope: String, callback: @escaping RespodWithCredential) {
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
var auth = HexavilleAuth()

let salesforceProvider = SalesforceAuthorizationProvider(
    path: "/auth/salesforce",
    consumerKey: "consumer",
    consumerSecret: "secret",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/salesforce/callback"),
    scope: "public_profile"
) { credential, request, context in

    try DB.save(token: credential.accessToken)

    return Response(body: "\(credential)")
}

auth.add(salesforceProvider)
```

## License

HexavilleAuth is released under the MIT license. See LICENSE for details.
