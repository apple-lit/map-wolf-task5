//
//  SimpleTaskViewModel.swift
//  MapWolf-ios
//
//  Created by fumiyatanaka_admin on 2021/01/30.
//

import Combine
import RxSwift
import SwiftUI

protocol SimpleTaskViewModelDelegate: AnyObject {
    func finishSimpleTask()
}

class SimpleTaskViewModel {
    private let model: SpotTaskModelType = TaskModel()
    private let disposeBag: DisposeBag = .init()

    weak var delegate: SimpleTaskViewModelDelegate?
    let simpleTask: SpotTask
    private var performing: Bool = false

    init(simpleTask: SpotTask) {
        self.simpleTask = simpleTask
    }

    func clearTask() {
        if performing {
            return
        }
        performing = true
        model.clearSpotTask(task: simpleTask).subscribe(onSuccess: { [weak self] in
            self?.delegate?.finishSimpleTask()
        }).disposed(by: disposeBag)
    }
}
