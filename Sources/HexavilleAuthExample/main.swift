//
//  main.swift
//  HexavilleAuth
//
//  Created by Yuki Takei on 2017/05/30.
//
//

import Foundation
import HexavilleAuth
import HexavilleFramework

let app = HexavilleFramework()

let sessionMiddleware = SessionMiddleware(
    cookieAttribute: CookieAttribute(
        expiration: 3600,
        httpOnly: true,
        secure: false
    ),
    store: SessionMemoryStore()
)

app.use(sessionMiddleware)

var auth = HexavilleAuth()

let APP_URL = ProcessInfo.processInfo.environment["APP_URL"] ?? "http://localhsot:3000"

let facebookProvider = FacebookAuthorizationProvider(
    path: "/auth/facebook",
    consumerKey: ProcessInfo.processInfo.environment["FACEBOOK_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["FACEBOOK_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/facebook/callback"),
    scope: "public_profile,email"
) { credential, user, request, context in
    return Response(body: "\(user)")
}

let githubProvider = GithubAuthorizationProvider(
    path: "/auth/github",
    consumerKey: ProcessInfo.processInfo.environment["GITHUB_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["GITHUB_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/github/callback"),
    scope: "user,repo"
) { credential, user, request, context in
    return Response(body: "\(user)")
}

let googleProvider = GoogleAuthorizationProvider(
    path: "/auth/google",
    consumerKey: ProcessInfo.processInfo.environment["GOOGLE_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["GOOGLE_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/google/callback"),
    scope: "https://www.googleapis.com/auth/drive"
) { credential, user, request, context in
    return Response(body: "\(credential)")
}

let instagramProvider = InstagramAuthorizationProvider(
    path: "/auth/instagram",
    consumerKey: ProcessInfo.processInfo.environment["INSTAGRAM_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["INSTAGRAM_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/instagram/callback"),
    scope: "basic"
) { credential, user, request, context in
    return Response(body: "\(credential)")
}

let twitterProvider = TwitterAuthorizationProvider(
    path: "/auth/twitter",
    consumerKey: ProcessInfo.processInfo.environment["TWITTER_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["TWITTER_APP_SECRET"] ?? "",
    callbackURL: CallbackURL(baseURL: APP_URL, path: "/auth/twitter/callback"),
    scope: ""
) { credential, user, request, context in
    return Response(body: "\(user)")
}

auth.add(facebookProvider)
auth.add(githubProvider)
auth.add(googleProvider)
auth.add(instagramProvider)
auth.add(twitterProvider)

app.use(HexavilleAuth.AuthenticationMiddleware())

app.use(auth)

let router = Router()

router.use(.get, "/") { req, context in
    return Response(body: "Welcome to Hexaville Auth")
}

app.use(router)

app.catch { error in
    print(error)
    return Response(status: .badRequest, body: "\(error)")
}

try app.run()
