//
//  DisplayRoleHostingController.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/24.
//

import Combine
import SwiftUI

class DisplayRoleHostingController: UIHostingController<DisplayRoleView> {
    var cancellables: [AnyCancellable] = []

    init(viewModel: RoomViewModel) {
        let view = DisplayRoleView(viewModel: viewModel)
        super.init(rootView: view)

        viewModel.$confirmedPlayerRole.dropFirst().combineLatest(viewModel.$playerRole).sink {
            [weak self] _, role in
            let viewController: UIViewController
            if role == .crewmate {
                viewController = CrewmateMapHostingController(viewModel: CrewmateMapViewModel())
            } else if role == .impostor {
                viewController = ImpostorMapHostingController(
                    viewModel: ImpostorMapViewModel(model: ImpostorModel()))
            } else {
                fatalError()
            }
            viewController.modalPresentationStyle = .fullScreen
            self?.present(viewController, animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
