//
//  ConfirmRoomView.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/24.
//

import SwiftUI

struct ConfirmRoomView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        VStack {
            HStack {
                Button(action: {
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
            Text("Room Found!")
                .font(.system(size: 40, weight: .bold))
            Spacer()
            HStack {
                Text(viewModel.hostAvatarText).font(.system(size: 48))
                    .padding(4)
                    .background(viewModel.hostColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Spacer()
                Text(viewModel.hostName)
                    .modifier(RoundedBoldFontModifier(fontSize: 24))
                Spacer()
                Text("\(viewModel.playerCount)/\(viewModel.maximumPlayerCount)")
                    .modifier(RoundedBoldFontModifier(fontSize: 24))
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .clipShape(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            Spacer()
            Button(
                action: {
                    viewModel.didTapConfirmRoomButton()
                },
                label: {
                    Text("Join Game")
                        .foregroundColor(.white)
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            )
            .background(Color(Asset.Colors.mwPink.color))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer()
        }.padding()
    }
}

struct ConfirmRoomView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomViewModel()
        viewModel.hostName = "choccho"
        viewModel.hostAvatarText = "🐙"
        viewModel.hostColor = Color(PlayerColor.green.color)
        return ConfirmRoomView(viewModel: viewModel).previewDevice(
            PreviewDevice(rawValue: "iPhone 11 Pro"))
    }
}
