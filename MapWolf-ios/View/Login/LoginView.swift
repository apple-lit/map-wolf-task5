//
//  LoginView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var canSubmitted: (can: Bool, nicknameErrorMsg: String, avatarErrorMsg: String) {
        if viewModel.nickName.isEmpty {
            return (false, "type something in", " ")
        }
        if viewModel.avatar.isEmpty {
            return (false, " ", "type something in")
        }

        // nickName Validation
        if !(viewModel.nickName.count
            == viewModel.nickName.lengthOfBytes(using: String.Encoding.shiftJIS)) {
            return (false, "only alphabets", " ")
        }
        if !(viewModel.nickName.count <= 8) {
            return (false, "less than 8 letters", " ")
        }
        if viewModel.nickName.range(of: "[^a-zA-Z]", options: .regularExpression) != nil {
            return (false, "only alphabets", " ")
        }

        // avatar Validation
        if viewModel.avatar.count > 1 {
            return (false, " ", "only 1 emoji here")
        }

        if !(viewModel.avatar.unicodeScalars.first!.properties.isEmoji
            && viewModel.avatar.range(of: "[a-zA-Z0-9]", options: .regularExpression) == nil) {
            return (false, " ", "only emojis here")
        }

        return (true, " ", " ")
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(uiImage: Asset.Images.logo.image)

            Spacer()

            VStack(alignment: .leading) {
                Text("NICKNAME")
                    .bold()
                    .foregroundColor(.secondary)

                LoginTextField(
                    placeholder: "Enter Nickname", text: $viewModel.nickName,
                    textContentType: .nickname, keyboardType: .alphabet, order: .id,
                    onCommitHandler: nil)

                Text(canSubmitted.nicknameErrorMsg)
                    .foregroundColor(Color(Asset.Colors.mwPink.color))
                    .font(.footnote)
            }

            VStack(alignment: .leading) {
                Text("AVATAR")
                    .bold()
                    .foregroundColor(.secondary)

                LoginTextField(
                    placeholder: "Enter Avatar Emoji", text: $viewModel.avatar, order: .avatar,
                    onCommitHandler: nil)

                Text(canSubmitted.avatarErrorMsg)
                    .foregroundColor(Color(Asset.Colors.mwPink.color))
                    .font(.footnote)
            }

            VStack(alignment: .leading) {
                Text("COLOR")
                    .bold()
                    .foregroundColor(.secondary)

                ColorPicker("CHOOSE COLOR", selection: $viewModel.color)
            }

            Spacer()

            Button(action: {
                viewModel.didTapSignInButton = ()
            }) {
                Text("Start Game")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .background(Color(Asset.Colors.mwPink.color))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(!canSubmitted.can)
            .opacity(canSubmitted.can ? 1.0 : 0.5)

            Spacer()

            #if DEBUG
                Text("isLoggedIn: " + String(viewModel.isLoggedIn))
            #endif
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel())
    }
}
