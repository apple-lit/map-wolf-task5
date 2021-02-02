//
//  ImpostorMenuView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/30.
//

import SwiftUI

struct ImpostorMenuView: View {
    @Binding var isOpened: Bool
    @ObservedObject var viewModel: ImpostorMapViewModel

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack {
                    Button(action: {
                        isOpened.toggle()
                    }) {
                        Image(
                            systemSymbol: isOpened ? .chevronDownCircleFill : .chevronUpCircleFill
                        )
                        .font(.system(size: 24))
                        .foregroundColor(Color(Asset.Colors.mwPink.color))
                    }

                    Spacer()
                }

                Text("IMPOSTOR MENU")
                    .bold()
                    .font(.title)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Button(action: {
                    viewModel.didTapKillButton()
                }) {
                    Text("Kill")
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(Color(Asset.Colors.mwPink.color))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .disabled(!viewModel.canKill)

                Button(action: {
                    //TODO: impl sabotage!!!
                    print("sabotage button pressed")
                    viewModel.sabotage()
                }) {
                    Text("Sabotage")
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .background(Color(Asset.Colors.mwPink.color))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(alignment: .bottom) {
                Text("Kill Cool Down")
                    .modifier(RoundedBoldFontModifier(fontSize: 16))
                Text("\(viewModel.killCoolTime)")
                    .modifier(RoundedBoldFontModifier(fontSize: 48))
                Text("sec")
                    .modifier(RoundedBoldFontModifier(fontSize: 16))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct ImpostorMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ImpostorMenuView(
            isOpened: .constant(true), viewModel: ImpostorMapViewModel(model: ImpostorModel()))
    }
}
