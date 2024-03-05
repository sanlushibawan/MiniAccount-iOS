//
//  AccountListView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/22.
//

import SwiftUI
import CoreData


struct AccountListView: View {
    @ObservedObject var miniAccountModel:MiniAccountModel
    @State var showAddAccountSheet = false
    @State var addNewAccount = true
    @State var editAccountIndex = 0
    let colorList = [Color("BlackWhiteColor"),.orange,.yellow,.mint,.teal,.cyan,.blue,.purple,.pink,.brown]
    var body: some View {
        NavigationStack{
                ZStack(alignment: .bottomTrailing){
                    ScrollView{
                        LazyVStack(spacing:30 ){
                            ForEach(miniAccountModel.accountList){account in
                                VStack{
                                    VStack{
                                        HStack{
                                            Text(account.accountName ?? "error")
                                            Spacer()
                                            Text((account.accountType == 1 ? "储蓄" : "信用"))
                                        }
                                        Divider()
                                        HStack{
                                            Text(account.accountNum ?? "")
                                            Spacer()
                                        }
                                        HStack{
                                            let colorMark = colorList[Int(account.bgColor)]
                                            RoundedRectangle(cornerRadius: 8).frame(width:40, height:30).foregroundStyle(colorMark)
                                            Spacer()
                                            Text(String(format: "%.2f",account.balance))
                                        }
                                    }.frame(maxWidth:.infinity).padding().background(Color(UIColor.tertiarySystemBackground)).cornerRadius(8)
                                        .contextMenu{
                                            Button{
                                                UIPasteboard.general.string = account.accountNum ?? ""
                                            }label: {
                                                Label("复制账号",systemImage: "doc.on.doc")
                                            }
                                            Button{
                                                showAddAccountSheet = true
                                                addNewAccount = false
                                                editAccountIndex = miniAccountModel.accountList.firstIndex(of: account) ?? 0
                                            }label:{
                                                Label("修改信息", systemImage:"rectangle.and.pencil.and.ellipsis")
                                            }
                                            Button(role: .destructive){
                                                miniAccountModel.deleteAccount(account:account)
                                            }label:{
                                                Label("删除", systemImage:"delete.left")
                                            }
                                        }
                                }.frame(maxWidth:.infinity)
                            }
                        }.padding(.horizontal)
                    }.background(Color(UIColor.systemGroupedBackground))
                    Button(action: {
                        showAddAccountSheet = true
                        addNewAccount = true
                    }){
                        Image(systemName: "rectangle.stack.fill.badge.plus").resizable().frame(width: 50,height: 50)
                    }.padding(36)
                }
            }.navigationTitle("账户列表").sheet(isPresented: $showAddAccountSheet){
                EditAccountSheetView(showType: $addNewAccount,dbvm: miniAccountModel,editIndex:$editAccountIndex)
        }
    }
}