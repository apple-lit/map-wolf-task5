//
//  WaitForHostViewHostingController.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import Combine
import SwiftUI

class WaitForHostViewHostingController: UIHostingController<WaitForHostView> {
    var cancellables: [AnyCancellable] = []

    init(viewModel: RoomViewModel) {
        let view = WaitForHostView(viewModel: viewModel)
        super.init(rootView: view)

        viewModel.$readyForGame.dropFirst().sink { [weak self] in
            let viewController = DisplayRoleHostingController(viewModel: viewModel)
            viewController.modalPresentationStyle = .fullScreen
            self?.present(viewController, animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
