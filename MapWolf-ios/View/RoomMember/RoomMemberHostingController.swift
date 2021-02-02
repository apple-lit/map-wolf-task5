//
//  RoomMemberHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import AVFoundation
import Combine
import SwiftUI

final class RoomMemberHostingController: UIHostingController<RoomMemberView> {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: RoomViewModel) {
        viewModel.startScanning()
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.$didDetectRoom.dropFirst().prefix(1).sink { [weak self] in
            guard let `self` = self else { return }
            let vc = ConfirmRoomHostController(viewModel: viewModel)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }.store(in: &cancellables)

        viewModel.$didCreateQRImage
            .dropFirst()
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                let vc = RoomHostHostingController(viewModel: viewModel)
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
            .store(in: &cancellables)

        viewModel.$backToLoginView.sink {
            self.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
