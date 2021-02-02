//
//  CrewmateMapHostingViewController.swift
//  MapWolf-ios
//
//  Created by 張翔 on 2021/01/25.
//

import Combine
import SwiftUI

final class CrewmateMapHostingController: UIHostingController<CrewmateMapView> {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CrewmateMapViewModel) {
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.$winnerRole.filter({ $0 != .unknown })
            .sink { [weak self] role in
                let vc = ResultHostingController(winnerRole: role)
                self?.present(vc, animated: true, completion: nil)
            }.store(in: &cancellables)

        viewModel.$presentSipoleTaskViewController
            .dropFirst()
            .compactMap { _ in viewModel.currentSpotTask }
            .sink { [weak self] spotTask in
                //FIXME: ハードコーディングやめろ
                switch Int.random(in: 1...5) {
                case 1:
                    let vc = StoryboardScene.CommonTask1.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)

                case 2:
                    let vc = StoryboardScene.CommonTask2.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)

                case 3:
                    let vc = StoryboardScene.CommonTask3.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)

                case 4:
                    let vc = StoryboardScene.CommonTask4.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)

                case 5:
                    let vc = StoryboardScene.CommonTask5.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)

                default:
                    let vc = StoryboardScene.SimpleTapTask.initialScene.instantiate()
                    vc.viewModel = SimpleTaskViewModel(simpleTask: spotTask)
                    self?.present(vc, animated: true, completion: nil)
                }
            }
            .store(in: &cancellables)

        viewModel.$presentPollingView
            .dropFirst()
            .sink { [weak self] _ in
                let vc = PollingHostingController()
                self?.present(vc, animated: true, completion: nil)
            }.store(in: &cancellables)

        viewModel.$showMyQRCode.dropFirst().filter({ !$0.isEmpty }).sink { [weak self] code in
            let vc = MyQRCodeHostingController(userId: code)
            self?.present(vc, animated: true, completion: nil)
        }.store(in: &cancellables)

        viewModel.$showScanView.compactMap({ $0 }).sink { [weak self] task in
            let vc = ScanQRCodeHostingController(cooperateTask: task)
            self?.present(vc, animated: true, completion: nil)
        }.store(in: &cancellables)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
