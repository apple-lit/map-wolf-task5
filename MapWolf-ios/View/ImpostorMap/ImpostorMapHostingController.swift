//
//  ImpostorMapHostingController.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import Combine
import SwiftUI

class ImpostorMapHostingController: UIHostingController<ImpostorMapView> {
    var cancellables: [AnyCancellable] = []

    init(viewModel: ImpostorMapViewModel) {
        let view = ImpostorMapView(viewModel: viewModel)
        super.init(rootView: view)

        viewModel.$startPoll
            .dropFirst()
            .sink { [weak self] in
                let viewController = PollingHostingController()
                self?.present(viewController, animated: true, completion: nil)
            }.store(in: &cancellables)

        viewModel.$winnerRole
            .filter({ $0 != .unknown })
            .sink { [weak self] role in
                let vc = ResultHostingController(winnerRole: role)
                self?.present(vc, animated: true, completion: nil)
            }.store(in: &cancellables)

        viewModel.$showMyQRCode
            .dropFirst()
            .filter({ !$0.isEmpty })
            .sink { [weak self] code in
                let vc = MyQRCodeHostingController(userId: code)
                self?.present(vc, animated: true, completion: nil)
            }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
