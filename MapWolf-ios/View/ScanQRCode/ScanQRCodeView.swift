//
//  ScanQRCodeView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/25.
//

import SwiftUI

struct ScanQRCodeView: View {
    @ObservedObject var viewModel: ScanCooperateQRViewModel

    var body: some View {
        ZStack {
            CALayerView(
                update: Binding(
                    get: {
                        viewModel.updateUIView
                    },
                    set: {
                        viewModel.updateUIView = ()
                    }), caLayer: viewModel.previewLayer
            )
            .ignoresSafeArea(.all, edges: .all)

            VStack {
                HStack {
                    Button(action: {
                        print("backbutton")
                        viewModel.didTapBackButtonAtRoomScan()
                    }) {
                        Image(systemSymbol: .xmark)
                            .font(Font.title.weight(.bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 48, minHeight: 48)
                            .background(Color(Asset.Colors.mwPink.color))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Spacer()
                }

                Spacer()
                Text("Scan to Complete😎")
                    .font(.system(size: 32, weight: .bold))
                Spacer()
                Image(uiImage: Asset.Images.scanQR.image)
                    .frame(minWidth: 160, minHeight: 160)
                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}

struct ScanQRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        ScanQRCodeView(
            viewModel: ScanCooperateQRViewModel(
                cooperateTask: CooperateTask(id: 0, qr: "hoge", avatar: nil, color: nil)))
    }
}
