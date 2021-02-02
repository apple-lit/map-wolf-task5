//
//  AuthClient.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import FirebaseAuth
import Foundation

protocol AuthClientType {
    var uid: String? { get }
    var user: User? { get }
    func loginAnonymously(completion: ((Result<User, Error>) -> Void)?)
    func logout() throws
    func updateDisplayName(_ displayName: String, completion: @escaping (Error?) -> Void)
}

class AuthClient: AuthClientType {
    private let auth = Auth.auth()

    var uid: String? {
        auth.currentUser?.uid
    }

    var user: User? {
        auth.currentUser
    }

    func updateDisplayName(_ displayName: String, completion: @escaping (Error?) -> Void) {
        guard let user = user else {
            return
        }
        let request = user.createProfileChangeRequest()
        request.displayName = displayName
        request.commitChanges(completion: completion)
    }

    func loginAnonymously(completion: ((Result<User, Error>) -> Void)?) {
        auth.signInAnonymously { result, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            guard let user = result?.user else {
                return
            }
            completion?(.success(user))
        }
    }

    func logout() throws {
        try auth.signOut()
    }
}
