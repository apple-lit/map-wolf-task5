//
//  RoomHostHostingViewController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import Combine
import SwiftUI

class RoomHostHostingController: UIHostingController<RoomHostView> {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: RoomViewModel) {
        super.init(rootView: RoomHostView(viewModel: viewModel))
        viewModel.$backToScanRoomView
            .dropFirst()
            .sink { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }.store(in: &cancellables)
        viewModel.$readyForGame.dropFirst().sink { [weak self] in
            let vc = DisplayRoleHostingController(viewModel: viewModel)
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
