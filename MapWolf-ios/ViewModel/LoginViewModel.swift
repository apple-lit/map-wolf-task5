//
//  LoginViewModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import Combine
import RxRelay
import RxSwift
import SwiftUI

class LoginViewModel: ObservableObject {
    private let model: LoginModelType = LoginModel()
    private let errorRelay: PublishRelay<Error> = .init()
    private let disposeBag = DisposeBag()
    private var cancellables: [AnyCancellable] = []

    @Published var avatar: String = ""
    @Published var color = Color(PlayerColor.red.color)
    @Published var nickName: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var didTapSignInButton: Void = ()

    init() {
        model.nickName.distinctUntilChanged().subscribe(onNext: { [weak self] nickName in
            self?.nickName = nickName
        }).disposed(by: disposeBag)

        model.isLoggedIn.subscribe { isLoggedIn in
            self.isLoggedIn = isLoggedIn
        }.disposed(by: disposeBag)

        errorRelay.map { $0.localizedDescription }.subscribe(onNext: { [weak self] errorMessage in
            self?.errorMessage = errorMessage
        }).disposed(by: disposeBag)

        model.avatar.distinctUntilChanged().subscribe(onNext: { [weak self] avatar in
            self?.avatar = avatar.resourceName
        }).disposed(by: disposeBag)

        model.color.distinctUntilChanged().subscribe(onNext: { [weak self] playerColor in
            self?.color = Color(playerColor.color)
        }).disposed(by: disposeBag)

        $didTapSignInButton.dropFirst().sink { [weak self] _ in
            guard let `self` = self else { return }
            let hex = UIColor(self.color).hexString
            self.model.commitChanges(
                nickName: self.nickName, colorHex: hex, avatarText: self.avatar
            )
            .subscribe().disposed(by: self.disposeBag)
        }.store(in: &cancellables)
    }
}
