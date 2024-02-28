//
//  MiniAccount_iOSApp.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/22.
//

import SwiftUI

@main
struct MiniAccount_iOSApp: App {
    @ObservedObject var miniAccountModel = MiniAccountModel()
    @AppStorage("openFaceIdOrTouchId") private var openAuth = false
    @State var isUnlocked:Bool = false
    @State var blurRadius = 0.0
    @Environment(\.scenePhase) var senePhase
    var isOpenFaceId:Bool = false
    init(){
        isOpenFaceId = openAuth
    }
    var body: some Scene {
        WindowGroup {
            ZStack{
                if isOpenFaceId{
                    if isUnlocked {ContentView(miniAccountModel: miniAccountModel)}
                    else {CheckDeviceOwnerView(isUnLock: $isUnlocked)}
                }else{
                    ContentView(miniAccountModel: miniAccountModel)
                }
            }.blur(radius: blurRadius)
                .onChange(of: senePhase){value in
                    switch(value){
                    case .active: withAnimation{blurRadius = 0}
                    case .inactive: withAnimation{blurRadius = 10}
                    case .background: blurRadius = 20
                    @unknown default: blurRadius = 0
                    }
                }.alert("Oops!", isPresented: $miniAccountModel.databaseError){
                    Button("Colse APP",role: .destructive) {
                        // Handle the retry action.
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    }
                }message: {
                    Text("An error loading the database, and the application needs to be reinstalled.").foregroundStyle(Color.red)
                }
        }
    }
}
