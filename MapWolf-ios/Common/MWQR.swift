//
//  MWQR.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import EFQRCode
import SwiftUI
import UIKit

class MVQRGenerator: NSObject {
    private static func generateWatermarkImage(from image: UIImage?) -> UIImage? {
        guard let image = image else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: image.size.width + 80, height: image.size.height), false, 1)
        UIGraphicsGetCurrentContext()
        image.draw(in: CGRect(x: 40, y: 0, width: image.size.width, height: image.size.height))
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }

    static func generate(text: String, handler: @escaping (_ image: UIImage) -> Void) {
        if let image = EFQRCode.generate(
            content: text,
            size: EFIntSize(width: 1024, height: 1024),
            backgroundColor: UIColor.white.cgColor,
            foregroundColor: UIColor.black.cgColor,
            watermark: nil,
            watermarkMode: .scaleAspectFit,
            inputCorrectionLevel: .q,
            allowTransparent: true,
            pointShape: .circle) {
            handler(UIImage(cgImage: image))
        }
    }
}
