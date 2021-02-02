//
//  ResultView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/27.
//

import SwiftUI

struct ResultUser: Hashable, Identifiable {
    var id: String
    var avatarEmoji: String
}

struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel

    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.myRole.iconText)
                .font(.system(size: 88))

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 56, maximum: 96)),
                    GridItem(.adaptive(minimum: 56, maximum: 96)),
                    GridItem(.adaptive(minimum: 56, maximum: 96))
                ],
                spacing: 16, pinnedViews: []
            ) {
                ForEach(viewModel.losers + viewModel.winners) { user in
                    Text(user.avatarEmoji)
                        .font(.system(size: 56))
                        .modifier(
                            HideViewModifier(
                                isHidden: viewModel.losers.contains(where: { loser in
                                    loser.id == user.id
                                }))
                        )
                        .id(UUID())
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))

            Spacer()

            Text(viewModel.resultMessage)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .bold()

            Spacer()

            Button(action: {
                //VoteButtonPressed
            }) {
                Text("Play Again")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(Asset.Colors.mwPink.color))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer()
        }
        .padding()
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(viewModel: ResultViewModel(winnerRole: .crewmate))
    }
}
