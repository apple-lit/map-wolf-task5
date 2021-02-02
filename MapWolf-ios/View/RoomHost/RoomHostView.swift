//
//  RoomHostView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import SwiftUI
import UIKit

struct RoomHostView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                HStack {
                    Button(action: {
                        //backbutton pressed
                        print("backbutton pressed")
                        viewModel.didTapHostBackButton()
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
                if let qrCode = viewModel.didCreateQRImage {
                    Image(uiImage: qrCode)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width * 0.8)
                } else {
                    Image(systemSymbol: .slashCircle)
                }

                Text("\(viewModel.playerCount)/\(viewModel.maximumPlayerCount)")
                    .font(
                        .system( /*@START_MENU_TOKEN@*/
                            .title /*@END_MENU_TOKEN@*/, design: .rounded)
                    )
                    .bold()

                VStack {
                    Text("Imposter")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()

                    HStack {
                        Button(action: {
                            viewModel.decreaseImpostorCount()
                        }) {
                            Image(systemSymbol: .minusCircleFill)
                                .font(.largeTitle)
                                .foregroundColor(Color(Asset.Colors.mwPink.color))
                        }

                        Text("\(viewModel.impostorCount)")
                            .font(Font.system(size: 60, weight: .bold))
                            .bold()

                        Button(action: {
                            viewModel.increaseImpostorCount()
                        }) {
                            Image(systemSymbol: .plusCircleFill)
                                .font(.largeTitle)
                                .foregroundColor(Color(Asset.Colors.mwPink.color))
                        }
                    }
                }

                Button(action: {
                    //StartGame
                    viewModel.didTapGameStartButton()
                }) {
                    Text("Start Game")
                        .foregroundColor(.white)
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(Asset.Colors.mwPink.color))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()
            }
        }.padding()
    }
}

struct RoomHostView_Previews: PreviewProvider {
    static var previews: some View {
        RoomHostView(viewModel: RoomViewModel())
    }
}
