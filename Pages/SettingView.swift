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
    @AppStorage("userName") private var userName = ""
    @State var showAbout = false
    var body: some View {
        NavigationStack{
            VStack{
                Form{
                    Section("修改用户信息"){
                        TextField("怎么称呼你", text: $userName)
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
            }.navigationTitle("个人&类型设置").toolbar(content: {
                Button{showAbout = true}label: {
                    Text("About")
                }
            })
        }.sheet(isPresented: $showEditBillTypeSheet){
            EditBillTypeSheet(miniDB: dbContext,updateIndex: $editIndex)
        }.sheet(isPresented: $showAbout){
            NavigationStack{
                List{
                    Section("Application Version"){
                        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
                        let versionCode = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
                        let buildCode = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
                        Text("Application Name:\(displayName)")
                        Text("version code:\(versionCode)")
                        Text("Build:\(buildCode)")
                    }
                    Section("Open source info"){
                        Image("github").resizable().frame(width:30,height:30)
                        Text("sanlushibawan")
                        Text("LICENSE:GPL-3.0 license")
                        Button{
                            UIPasteboard.general.string = "https://github.com/sanlushibawan/MiniAccount-iOS"
                        }label: {
                            Text("Copy repository address")
                        }
                    }
                }.navigationTitle("About Application")
            }
        }
    }
}
