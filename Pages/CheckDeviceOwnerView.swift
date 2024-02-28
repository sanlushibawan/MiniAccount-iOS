//
//  CheckDeviceOwnerView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/26.
//

import SwiftUI
import LocalAuthentication

struct CheckDeviceOwnerView: View {
    @State var isFaceId = false
    //@ObservedObject var unLockApp: UnlocApp
    @Binding var isUnLock:Bool
    @AppStorage("openFaceIdOrTouchId") private var openAuth = false
    var body: some View {
        VStack{
            Button{
                authenticate()
            }label: {
                VStack{
                    Image(systemName: isFaceId ? "faceid":"touchid").font(.system(size: 60))
                    Text("点击验证")
                }
            }
        }.onAppear{
            authenticate()
        }
    }
    
    func authenticate(){
        let context = LAContext()
        // check whether biometric authentication is possible
        if canUseFaceidOrTouchId() {
            isFaceId = (context.biometryType == .faceID)
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    // authenticated successfully
                    isUnLock = true
                } else {
                    // there was a problem, Non-matching face
                    isUnLock = false
                }
            }
        } else {
            // no biometrics
            openAuth = false
            isUnLock = true
        }
    }
    func canUseFaceidOrTouchId()->Bool{
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: .none){
            return true
        }else{
            
        }
        return false
    }
}
