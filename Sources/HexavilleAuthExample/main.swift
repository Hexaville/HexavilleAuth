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

var auth = HexavilleAuth()

let APP_URL = ProcessInfo.processInfo.environment["APP_URL"] ?? "http://localhsot:3000"

let facebookProvider = FacebookAuthenticationProvider(
    path: "/auth/facebook",
    consumerKey: ProcessInfo.processInfo.environment["FACEBOOK_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["FACEBOOK_APP_SECRET"] ?? "",
    callbackURL: "\(APP_URL)/auth/facebook/callback",
    scope: "public_profile"
) { credential, request, context in
    return Response(body: "\(credential)")
}

let githubProvider = GithubAuthenticationProvider(
    path: "/auth/github",
    consumerKey: ProcessInfo.processInfo.environment["GITHUB_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["GITHUB_APP_SECRET"] ?? "",
    callbackURL: "\(APP_URL)/auth/github/callback",
    scope: "user,repo"
) { credential, request, context in
    return Response(body: "\(credential)")
}

let googleProvider = GoogleAuthenticationProvider(
    path: "/auth/google",
    consumerKey: ProcessInfo.processInfo.environment["GOOGLE_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["GOOGLE_APP_SECRET"] ?? "",
    callbackURL: "\(APP_URL)/auth/google/callback",
    scope: "https://www.googleapis.com/auth/drive"
) { credential, request, context in
    return Response(body: "\(credential)")
}

let instagramProvider = InstagramAuthenticationProvider(
    path: "/auth/instagram",
    consumerKey: ProcessInfo.processInfo.environment["INSTAGRAM_APP_ID"] ?? "",
    consumerSecret: ProcessInfo.processInfo.environment["INSTAGRAM_APP_SECRET"] ?? "",
    callbackURL: "\(APP_URL)/auth/instagram/callback",
    scope: "basic"
) { credential, request, context in
    return Response(body: "\(credential)")
}

auth.add(facebookProvider)
auth.add(githubProvider)
auth.add(googleProvider)
auth.add(instagramProvider)

app.use(auth.asRouter())

let router = Router()

router.use(.get, "/") { _ in
    return Response(body: "Welcome to Hexaville Auth")
}

app.use(router)

app.catch { error in
    switch error {
    case HexavilleAuthError.responseError(let response):
        return Response(body: response.body.asData())
    default:
        return Response(body: "\(error)")
    }
}

try app.run()
