//
//  ZoomAPIJWT.swift
//  SurgeonITPClient
//
//  Created by Jorge Castillo on 11/11/24.
//

import Foundation
import SwiftJWT

struct MyClaims: Claims {
    let app_key: String
    let tpc: String
    let role_type: Int
    let version: Int
    let iat: Date
    let exp: Date
}

struct ZoomAPIJWT {
    var apiKey: String
    var apiSecret: String

    func generateToken(sessionName: String, roleType: Int) -> String {
        let now = Date()
        let exp = Date(timeIntervalSinceNow: 7200) // Token is valid for 2 hours

        let claims = MyClaims(
            app_key: apiKey,
            tpc: sessionName,
            role_type: roleType,
            version: 1,
            iat: now,
            exp: exp
        )

        do {
            var jwt = JWT(header: Header(typ: "JWT"), claims: claims)
            let token = try jwt.sign(using: .hs256(key: apiSecret.data(using: .utf8)!))
            Logger.shared.log("JWT Token generated successfully.")
            return token
        } catch {
            Logger.shared.log("Failed to generate JWT: \(error)")
            return ""
        }
    }
}
