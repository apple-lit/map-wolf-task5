//
//  ScanQRCodeHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/25.
//

import Combine
import SwiftUI

final class ScanQRCodeHostingController: UIHostingController<ScanQRCodeView> {
    private var cancellables = Set<AnyCancellable>()

    init(cooperateTask: CooperateTask) {
        let viewModel = ScanCooperateQRViewModel(cooperateTask: cooperateTask)
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.$closeView.dropFirst().sink { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)

        viewModel.$isCompleted.filter({ $0 }).map({ _ in () }).sink { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
