//
//  ConfirmRoomHostController.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/24.
//

import Combine
import SwiftUI

class ConfirmRoomHostController: UIHostingController<ConfirmRoomView> {
    private var cancellables: [AnyCancellable] = []

    init(viewModel: RoomViewModel) {
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.$backToScanRoomView.dropFirst().sink { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)

        viewModel.$didEnterRoom.dropFirst().sink { [weak self] in
            let vc = WaitForHostViewHostingController(viewModel: viewModel)
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
