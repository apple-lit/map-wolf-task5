//
//  MyQRCodeHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/24.
//

import Combine
import SwiftUI

final class MyQRCodeHostingController: UIHostingController<MyQRCodeView> {
    private var cancellables = Set<AnyCancellable>()
    init(userId: String) {
        let viewModel = MyQRCodeViewModel(userId: userId)
        super.init(rootView: MyQRCodeView(viewModel: viewModel))

        viewModel.$backToMapView
            .dropFirst()
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
