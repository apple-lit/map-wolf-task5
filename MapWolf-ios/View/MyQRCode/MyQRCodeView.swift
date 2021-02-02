//
//  MyQRCodeView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/24.
//

import SwiftUI

struct MyQRCodeView: View {
    @ObservedObject var viewModel: MyQRCodeViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                HStack {
                    Button(action: {
                        viewModel.didTapBackButton()
                    }) {
                        Image(systemSymbol: .xmark)
                            .font(Font.title.weight(.bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 48, minHeight: 48)
                            .background(Color(Asset.Colors.mwPink.color))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Spacer()
                    }
                }

                if let qrCode = viewModel.qrImage {
                    Image(uiImage: qrCode)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width * 0.8)
                } else {
                    Image(systemSymbol: .slashCircle)
                }

                Spacer()

                Text(viewModel.avatarString)
                    .font(.system(size: 100))
                    .frame(minWidth: 160, minHeight: 160)
                    .background(Color(viewModel.userColor))
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))

                Spacer()
            }
        }
        .padding()
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct MyQRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MyQRCodeViewModel(userId: "asdfasdf")
        MyQRCodeView(viewModel: viewModel)
    }
}
