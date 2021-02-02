//
//  PollingHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/27.
//

import Combine
import SwiftUI

final class PollingHostingController: UIHostingController<PollingView> {
    private var cancellables: [AnyCancellable] = []

    init() {
        let viewModel = PollingViewModel()
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.$killedPlayer.dropFirst().sink {
            _ in
            self.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)

        viewModel.$skipped.dropFirst().sink {
            self.dismiss(animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
