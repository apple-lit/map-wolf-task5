//
//  LoginHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import Combine
import SwiftUI

final class LoginHostingController: UIHostingController<LoginView> {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: LoginViewModel) {
        super.init(rootView: .init(viewModel: viewModel))
        viewModel.$didTapSignInButton
            .dropFirst()
            .sink { [weak self] _ in
                guard let `self` = self else { return }

                let vc = RoomMemberHostingController(viewModel: RoomViewModel())
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
            .store(in: &self.cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
