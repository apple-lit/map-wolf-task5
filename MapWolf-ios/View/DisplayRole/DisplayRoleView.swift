//
//  DisplayRoleView.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/24.
//

import SwiftUI

struct DisplayRoleView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        VStack {
            Spacer().frame(height: 184)
            Text(viewModel.playerRole.iconText).font(
                .system(size: 200, weight: .bold, design: .rounded)
            )
            .shadow(
                color: Color(Asset.Colors.mwPink.color),
                radius: 2, x: 0, y: 2)
            Spacer().frame(height: 123)
            Text(viewModel.playerRole.name).font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.systemBackground))
                .shadow(
                    color: Color(Asset.Colors.mwPink.color),
                    radius: 2, x: 0, y: 2)
            Spacer()
        }.onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.confirmedPlayerRole = ()
            }
        })
        .onTapGesture {
            viewModel.confirmedPlayerRole = ()
        }
    }
}

struct DisplayRoleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DisplayRoleView(viewModel: RoomViewModel()).previewDevice(
                PreviewDevice(rawValue: "iPhone 11"))
        }
    }
}
