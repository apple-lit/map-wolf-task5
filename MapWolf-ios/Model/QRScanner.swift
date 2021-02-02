//
//  QRScanner.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/21.
//

import AVFoundation
import RxRelay
import RxSwift

class QRScaner: NSObject {
    let session = AVCaptureSession()
    private let foundQRRelay = PublishRelay<String>()
    var foundQR: Observable<String> {
        return foundQRRelay.asObservable()
    }
    let sessionHasStartedRelay: PublishRelay<Void> = .init()
    let sessionHasStoppedRelay: PublishRelay<Void> = .init()

    func setupQRScan() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back)
        let devices = discoverySession.devices
        if let backCamera = devices.first {
            do {
                let deviceInput = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                    let metadataOutput = AVCaptureMetadataOutput()
                    if session.canAddOutput(metadataOutput) {
                        session.addOutput(metadataOutput)
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }

    func startQRScan() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning { return }
            self.session.startRunning()
            self.sessionHasStartedRelay.accept(())
        }
    }

    func stopQRScan() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.sessionHasStoppedRelay.accept(())
            }
        }
    }
}

extension QRScaner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            guard metadata.type == .qr,
                let text = metadata.stringValue
            else {
                continue
            }
            foundQRRelay.accept(text)
        }
    }
}
