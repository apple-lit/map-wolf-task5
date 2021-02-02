//
//  ResultHostingController.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/27.
//

import Combine
import SwiftUI

final class ResultHostingController: UIHostingController<ResultView> {
    private var cancellables: [AnyCancellable] = []

    init(winnerRole: PlayerRole) {
        super.init(rootView: ResultView(viewModel: ResultViewModel(winnerRole: winnerRole)))
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
