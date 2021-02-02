//
//  CrewmateTaskListView.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/26.
//

import SwiftUI

struct UserSpotTask: Hashable, Identifiable {
    var id: Int

    var isCompleted: Bool
    var color: Color
}

struct CooperateTaskUser: Hashable, Identifiable {
    var id: Int

    var avatarText: String
    var color: Color
}

struct CrewmateTaskListView: View {
    @Binding var isOpend: Bool

    @ObservedObject var viewModel: CrewmateMapViewModel

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            isOpend.toggle()
                        }
                    }) {
                        Image(systemSymbol: isOpend ? .chevronDownCircleFill : .chevronUpCircleFill)
                            .font(.system(size: 24))
                            .foregroundColor(Color(Asset.Colors.mwPink.color))
                    }

                    Spacer()
                }

                Text("CREWMATE TASKS")
                    .bold()
                    .font(.title)
                    .foregroundColor(.gray)
            }

            if isOpend {
                HStack {
                    Text("COMMON TASKS🧑‍💻")
                        .bold()
                        .foregroundColor(.gray)
                    Spacer()
                }

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.userSpotTasks, id: \.self) { userTask in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(userTask.color)
                                        .frame(width: 48, height: 48)
                                        .id(UUID())

                                    if userTask.isCompleted {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 40, height: 40)
                                            .opacity(0.4)
                                            .id(UUID())
                                        Image(systemSymbol: .checkmark)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .opacity(0.4)
                                            .id(UUID())
                                    }
                                }

                                Image(systemSymbol: .chevronForward2)
                                    .font(Font.body.weight(.bold))
                                    .foregroundColor(.gray)
                                    .id(UUID())
                            }
                        }
                    }
                }

                HStack {
                    Text("COOPERATE TASKS🤯")
                        .bold()
                        .foregroundColor(.gray)
                    Spacer()
                }

                ScrollView(.horizontal) {
                    LazyHGrid(
                        rows: [
                            GridItem(.flexible(minimum: 120, maximum: 300)),
                            GridItem(.flexible(minimum: 120, maximum: 300))
                        ], spacing: 12, pinnedViews: []
                    ) {
                        ForEach(viewModel.cooperateTasks) { task in
                            Button(action: {
                                viewModel.didTapShowScanView()
                            }) {
                                if viewModel.completedCooperateTasks.contains(task) {
                                    Text(task.avatarText)
                                        .font(.system(size: 48))
                                        .frame(minWidth: 120, minHeight: 120)
                                        .background(task.color)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        )
                                        .id(UUID())
                                } else {
                                    Text("")
                                        .font(.system(size: 48))
                                        .frame(minWidth: 120, minHeight: 120)
                                        .background(Color.gray)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        )
                                        .id(UUID())
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct CrewmateTaskListView_Previews: PreviewProvider {
    static var previews: some View {
        CrewmateTaskListView(isOpend: .constant(true), viewModel: CrewmateMapViewModel())
    }
}
