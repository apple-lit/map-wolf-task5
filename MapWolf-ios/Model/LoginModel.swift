//
//  LoginModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseAuth
import Foundation
import RxRelay
import RxSwift

protocol LoginModelType {
    var isLoggedIn: Observable<Bool> { get }
    var nickName: Observable<String> { get }
    var avatar: Observable<Avatar> { get }
    var color: Observable<PlayerColor> { get }
    func commitChanges(nickName: String, colorHex: String, avatarText: String) -> Single<Void>
    func logout() -> Single<Void>
}

class LoginModel: LoginModelType {
    private let store: Store
    private let auth = AuthClient()
    private let userDefautls = UserDefaults.standard
    private let disposeBag = DisposeBag()

    private let nickNameRelay: BehaviorRelay<String?> = .init(value: nil)
    private let colorRelay: BehaviorRelay<PlayerColor> = .init(value: .red)
    private let avatarRelay: BehaviorRelay<Avatar> = .init(value: .defaultAvatar)

    var isLoggedIn: Observable<Bool> {
        store.user.map { $0 != nil }
    }

    var color: Observable<PlayerColor> {
        colorRelay.asObservable()
    }

    var avatar: Observable<Avatar> {
        avatarRelay.asObservable()
    }

    var nickName: Observable<String> {
        nickNameRelay.compactMap { $0 }
    }

    init(store: Store = .shared) {
        self.store = store

        colorRelay.accept(store.color)
        avatarRelay.accept(store.avatar)
        store.user.map { $0?.displayName }.bind(to: nickNameRelay).disposed(by: disposeBag)

        if auth.user == nil {
            auth.loginAnonymously(completion: nil)
        }
    }

    func commitChanges(nickName: String, colorHex: String, avatarText: String) -> Single<Void> {
        userDefautls.set(colorHex, forKey: "player_color_hex")
        userDefautls.set(avatarText, forKey: "avatar_resource_name")
        nickNameRelay.accept(nickName)
        colorRelay.accept(PlayerColor(hex: colorHex))
        avatarRelay.accept(Avatar(resourceName: avatarText))
        return Single<Void>.create { singleEvent -> Disposable in
            self.auth.updateDisplayName(nickName) { error in
                if let error = error {
                    singleEvent(.failure(error))
                    return
                }
                singleEvent(.success(()))
            }
            return Disposables.create()
        }
    }

    func logout() -> Single<Void> {
        Single.create { singleEvent -> Disposable in
            do {
                try self.auth.logout()
                singleEvent(.success(()))
            } catch {
                singleEvent(.failure(error))
            }
            return Disposables.create()
        }
    }
}
