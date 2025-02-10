//
//  AuthPayload.swift
//  VaporProject
//
//  Created by CursorAI on 2023-10-04.
//

import JWT

public struct AuthPayload: JWTPayload {
    let sub: SubjectClaim
    let exp: ExpirationClaim

    public func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
} 