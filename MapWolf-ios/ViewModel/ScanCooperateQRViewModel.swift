//
//  ScanCooperateQRViewModel.swift
//  MapWolf-ios
//
//  Created by fumiyatanaka_admin on 2021/01/30.
//

import AVFoundation
import RxRelay
import RxSwift
import SwiftUI

class ScanCooperateQRViewModel: ObservableObject {
    private let model: CooperateTaskModelType = TaskModel()
    private let disposeBag: DisposeBag = .init()

    @Published var updateUIView: Void = ()
    @Published var isCompleted: Bool = false
    @Published var closeView: Void = ()
    let previewLayer = AVCaptureVideoPreviewLayer()

    var session: AVCaptureSession {
        model.session
    }

    let cooperateTask: CooperateTask

    init(cooperateTask: CooperateTask) {
        self.cooperateTask = cooperateTask

        model.sessionHasStarted.observe(on: MainScheduler.instance).subscribe(onNext: {
            [weak self] in
            guard let self = self else {
                return
            }
            self.previewLayer.session = self.session
            self.previewLayer.videoGravity = .resizeAspectFill
            self.updateUIView = ()
        }).disposed(by: disposeBag)

        model.taskCompleted.subscribe(onNext: { [weak self] _ in
            self?.isCompleted = true
        }).disposed(by: disposeBag)
    }

    func didTapBackButtonAtRoomScan() {
        closeView = ()
    }
}
