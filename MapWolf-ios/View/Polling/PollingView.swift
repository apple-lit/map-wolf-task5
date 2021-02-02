//
//  PollingView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/27.
//

import SwiftUI

struct PollingUser: Hashable, Identifiable {
    var id: String
    var nickname: String
    var avatar: String
    var color: Color
    var isImposter: Bool
}

struct PollingView: View {
    @ObservedObject var viewModel: PollingViewModel

    @State private var isShowingSkipAlert = false
    @State private var isShowingVoteAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Who is the imposter🦹?")
                .font(.title)
                .bold()

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 48, maximum: 96)),
                    GridItem(.adaptive(minimum: 48, maximum: 96)),
                    GridItem(.adaptive(minimum: 48, maximum: 96)),
                    GridItem(.adaptive(minimum: 48, maximum: 96))
                ],
                spacing: 16, pinnedViews: [] /*@END_MENU_TOKEN@*/
            ) {
                ForEach(viewModel.allUsers) { user in
                    VStack {
                        Button(action: {
                            viewModel.selectedUser = user
                        }) {
                            VStack {
                                Text(user.avatar)
                                    .font(.system(size: 48))
                                    .frame(minWidth: 64, minHeight: 64)
                                    .background(user.color)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            //FIXME: 存在しないであろうid 100を使ってOptionalを回避
                                            .stroke(
                                                Color.gray,
                                                lineWidth: viewModel.selectedUser?.id ?? ""
                                                    == user.id ? 4 : 0)
                                    )
                                    .id(UUID())

                                Text(user.nickname)
                                    .font(.system(size: 16))
                                    .bold()
                                    .foregroundColor(
                                        viewModel.isImpostor && user.isImposter ? .red : .black
                                    )
                                    .id(UUID())
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))

            HStack {
                Text("Remaining: ")
                    .font(.largeTitle)
                    .bold()

                Text("\(viewModel.remainingTime)")
                    .font(.largeTitle)
                    .bold()

                Text("sec")
                    .font(.largeTitle)
                    .bold()
            }

            Button(action: {
                //VoteButtonPressed
                viewModel.vote()
            }) {
                Text("VOTE")
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(Asset.Colors.mwPink.color))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button(action: {
                isShowingSkipAlert.toggle()
            }) {
                Text("SKIP VOTE")
                    .bold()
            }
        }
        .alert(isPresented: $isShowingSkipAlert) {
            Alert(
                title: Text("Skipping Your Vote?"),
                primaryButton: .default(Text("Yes")) {
                    viewModel.skip()
                }, secondaryButton: .cancel())
        }
        .padding()
    }
}

struct PollingView_Previews: PreviewProvider {
    static var previews: some View {
        PollingView(viewModel: PollingViewModel())
    }
}
