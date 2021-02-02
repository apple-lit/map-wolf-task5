//
//  ImpostorMapView.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import CoreLocation
import SwiftUI

struct ImpostorMapView: View {
    @ObservedObject var viewModel: ImpostorMapViewModel

    @State var menuViewIsOpened = false
    @State var alertIsPresented = false

    var body: some View {
        ZStack {
            MapView(
                spotTasks: .constant([]), avatar: viewModel.avatar,
                center: CLLocationCoordinate2D(
                    latitude: Constant.center.latitude, longitude: Constant.center.longitude),
                emergencyPoint: Constant.emergencyPoint
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer().frame(width: 48)
                    Spacer()

                    if viewModel.isKilled {
                        Text("👻")
                            .font(.system(size: 64))
                    } else {
                        Text(viewModel.avatar.resourceName)
                            .font(.system(size: 64))
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button(action: {
                            viewModel.didTapShowMyQRCode()
                        }) {
                            Image(systemSymbol: .qrcode)
                                .font(Font.title.weight(.bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 48, minHeight: 48)
                                .background(Color(Asset.Colors.mwPink.color))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .shadow(
                            color: Color(Asset.Colors.mwPink.color), radius: 3,
                            x: 0.0,
                            y: 0.0)

                        Button(action: {
                            alertIsPresented = true
                        }) {
                            Text("📢")
                                .frame(minWidth: 48, minHeight: 48)
                                .background(Color(Asset.Colors.mwPink.color))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .alert(
                            isPresented: $alertIsPresented,
                            content: {
                                Alert(
                                    title: Text("Report?"),
                                    primaryButton: .cancel(Text("キャンセル")),
                                    secondaryButton: .destructive(
                                        Text("Report"),
                                        action: {
                                            viewModel.didReport()
                                        }))
                            })
                    }
                }
                .padding()

                Spacer()
            }

            VStack {
                Spacer()
                ImpostorMenuView(isOpened: $menuViewIsOpened, viewModel: viewModel)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                    .shadow(
                        color: Color(Asset.Colors.mwPink.color), radius: 3,
                        x: 0.0,
                        y: 0.0)
            }

            if viewModel.canEmergency {
                Button("Emergency") {
                    viewModel.didTapEmergencyButton()
                }
                .foregroundColor(.white)
                .font(.title)
                .frame(width: 200, height: 200, alignment: .center)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 50))
            }
        }
    }
}

struct ImpostorMapView_Previews: PreviewProvider {
    static var previews: some View {
        ImpostorMapView(viewModel: ImpostorMapViewModel(model: ImpostorModel()))
    }
}
