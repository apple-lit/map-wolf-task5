//
//  MyQRCodeViewModel.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/31.
//

import SwiftUI
import UIKit

class MyQRCodeViewModel: ObservableObject {
    private let userId: String
    @Published var qrImage: UIImage?
    @Published var backToMapView: Void = ()

    var avatarString: String {
        Store.shared.avatar.resourceName
    }

    var userColor: UIColor {
        Store.shared.color.color
    }

    init(userId: String) {
        self.userId = userId
    }

    func onAppear() {
        MVQRGenerator.generate(text: self.userId) { image in
            self.qrImage = image
        }
    }

    func didTapBackButton() {
        backToMapView = ()
    }
}
