//
//  RoomMemberView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import AVFoundation
import SwiftUI

struct RoomMemberView: View {
    @ObservedObject var viewModel: RoomViewModel

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
                        viewModel.didTapBackButtonAtRoomScan()
                    }) {
                        Image(systemSymbol: .chevronLeft)
                            .font(Font.title.weight(.bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 48, minHeight: 48)
                            .background(Color(Asset.Colors.mwPink.color))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                    }
                }
                Spacer()
                Text("Scan to Join 🤼‍♂️")
                    .font(.system(size: 32, weight: .bold))
                Spacer()
                Image(uiImage: Asset.Images.scanQR.image)
                    .frame(minWidth: 160, minHeight: 160)
                Spacer()
                Button(action: {
                    viewModel.becomeHost()
                }) {
                    Text("Become Host")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(minWidth: 170, minHeight: 34)
                        .background(Color(Asset.Colors.mwPink.color))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

                Spacer()
            }
            .padding()
        }.onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}

struct RoomMemberView_Previews: PreviewProvider {
    static var previews: some View {
        RoomMemberView(viewModel: RoomViewModel())
    }
}
