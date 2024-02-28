//
//  SettingView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/23.
//

import SwiftUI
import LocalAuthentication

struct SettingView: View {
    @ObservedObject var dbContext:MiniAccountModel
    @FocusState var editTypeNameFocus:Bool
    @State var billTypeName = ""
    @State var inComeType = false
    @State var showEditBillTypeSheet = false
    @State var editIndex = 0
    @State var showAlert = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("openFaceIdOrTouchId") private var useFaceId = false
    var body: some View {
        NavigationStack{
            VStack{
                Form{
                    Section("修改用户信息"){
                        TextField("怎么称呼你", text: $userName)
                    }
                    Section("隐私"){
                        Toggle(isOn: $useFaceId, label: {
                            if LAContext().biometryType == .touchID {
                                Label("TouchId", systemImage: "touchid")}else{
                                    Label("FaceId", systemImage: "faceid")
                                }
                        }).onChange(of: useFaceId){value in
                            canUseFaceidOrTouchId()
                        }
                    }
                    Section("添加消费类型"){
                        Toggle(isOn: $inComeType, label: {inComeType ? Label("收入",systemImage:"square.and.arrow.down"):Label("支出",systemImage:"square.and.arrow.up")})
                        HStack{
                            TextField("消费类型",text: $billTypeName).focused($editTypeNameFocus)
                                .submitLabel(.done)
                                .onSubmit {
                                dbContext.addBillType(typeName: billTypeName, isIncome: inComeType)
                                billTypeName = ""
                                inComeType = false
                            }
                            Button{
                                editTypeNameFocus = false
                                dbContext.addBillType(typeName: billTypeName, isIncome: inComeType)
                                billTypeName = ""
                                inComeType = false
                            }label: {
                                Image(systemName: "text.badge.plus")
                            }.buttonStyle(.borderedProminent).disabled(billTypeName=="")
                        }
                    }
                    List{
                        ForEach(dbContext.billTypeList,id:\.id){ typeItem in
                            HStack{
                                if !typeItem.type {Image(systemName: "square.and.arrow.up").foregroundColor(.green).foregroundStyle(.secondary)}else{Image(systemName: "square.and.arrow.down").foregroundColor(.red).foregroundStyle(.secondary)}
                                Text(typeItem.typeName ?? "")
                                Spacer()
                                Text(typeItem.type ? "收入":"支出")
                            }.onTapGesture {
                                showEditBillTypeSheet = true
                                editIndex = dbContext.billTypeList.firstIndex(of: typeItem) ?? 0
                            }
                        }.onDelete(perform:dbContext.removeBillType).onMove(perform: dbContext.moveBillType)
                    }
                }
            }.navigationTitle("个人&类型设置")
        }.sheet(isPresented: $showEditBillTypeSheet){
            EditBillTypeSheet(miniDB: dbContext,updateIndex: $editIndex)
        }.alert("No Permission",isPresented: $showAlert){
            Button(role: .cancel) {
                // Handle the deletion.
            } label: {
                Text("取消")
            }
            Button("去开启") {
                // Handle the retry action.
                guard let url = URL(string: UIApplication.openSettingsURLString) else{
                    return
                }
                UIApplication.shared.open(url)
            }
        }message: {
            Text("开启面容 ID 权限才能使用锁定功能")
        }
    }
    
    func canUseFaceidOrTouchId(){
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: .none){
        }else{
            showAlert = true
            useFaceId = false
        }
    }
}
