//
//  CALayerView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/25.
//

import SwiftUI

struct CALayerView: UIViewRepresentable {
    typealias UIViewType = UIView
    @Binding var update: Void
    var caLayer: CALayer
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(caLayer)
        caLayer.frame = view.layer.frame
        view.layer.masksToBounds = true
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        caLayer.frame = uiView.layer.bounds
    }
}
