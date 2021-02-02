//
//  WaitForHostView.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import SwiftUI

struct WaitForHostView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.myAvatarResourceName).font(.system(size: 160))
                .padding(EdgeInsets(top: 32, leading: 44, bottom: 32, trailing: 44))
                .background(viewModel.myColor)
                .clipShape(RoundedRectangle(cornerRadius: 64, style: .continuous))
            Text(viewModel.myNickName).modifier(RoundedBoldFontModifier(fontSize: 36))
            Spacer()
            Text("\(viewModel.playerCount)/\(viewModel.maximumPlayerCount)").modifier(
                RoundedBoldFontModifier(fontSize: 36))
            Spacer()
            Text("Waiting Host…").modifier(RoundedBoldFontModifier(fontSize: 30)).foregroundColor(
                Color.gray)
            Spacer()
        }
    }
}

struct WaitForHostView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = RoomViewModel()
        vm.myAvatarResourceName = "👻"
        vm.myColor = Color.green
        vm.myNickName = "obake"
        return WaitForHostView(viewModel: vm).previewDevice(PreviewDevice(rawValue: "iPhone 11"))
    }
}
