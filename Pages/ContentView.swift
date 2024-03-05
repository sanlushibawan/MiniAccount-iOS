//
//  ContentView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var miniAccountModel:MiniAccountModel
    @State var showBillDetailView = false
    @State var showAddNewBill = false
    @State var showBill = 0
    @State var navigationToAccountList = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("firstTimeOpen") private var firstTimeOpen = true

    @State var showColorPanel = false
    let colorList = [Color("BlackWhiteColor"),.orange,.yellow,.mint,.teal,.cyan,.blue,.purple,.pink,.brown]
    @State var selectedColor = Color("BlackWhiteColor")
    
    @State var accountName:String = ""
    @State var accountNum:String = ""
    @State var accountType:Int64 = 0
    @State var balance:Double = 0.0
    @State var showHomePage:Bool = true
    @State var defaultAccount:Bool = true
    @State var accountTypeStr:String = "储蓄"
    @State var disableButton = true
    
    var body: some View {
        NavigationStack{
            ZStack(alignment:.bottomTrailing){
                ScrollView{
                    HStack{
                        VStack(alignment: .leading){
                            Text("Hello \(userName)").font(Font.largeTitle)
                            Text(Date(),style: .date)
                        }
                        Spacer()
                        NavigationLink(destination: SettingView(dbContext: miniAccountModel), label: {Image(systemName: "person.text.rectangle").imageScale(.large)})
                    }.padding()
                    VStack{
                        NavigationLink(destination:AccountListView(miniAccountModel: miniAccountModel)){
                            VStack{
                                HStack{
                                    Text("Account&Balance")
                                    Spacer()
                                    Text("管理").foregroundStyle(Color.accentColor)
                                }
                                Divider()
                                VStack(spacing:8){
                                    if miniAccountModel.accountList.isEmpty {
                                        Text("Don't have an account yet?  Click Me to add one.")
                                    }
                                    ForEach(miniAccountModel.accountList){indexAccount in
                                        if indexAccount.showHomePage{
                                            HStack{
                                                let nameAndNum = (indexAccount.accountName ?? "")+" "+(indexAccount.accountNum ?? "").suffix(4)
                                                Text(nameAndNum).foregroundColor(colorList[Int(indexAccount.bgColor)])
                                                Spacer()
                                                Text(String(format:"%.2F", indexAccount.balance))
                                            }.padding(.horizontal)
                                        }
                                    }
                                }
                            }.frame(maxWidth:.infinity).padding().background(Color(UIColor.tertiarySystemBackground)).cornerRadius(8)
                        }.buttonStyle(PlainButtonStyle())
                    }.frame(maxWidth:.infinity).padding()
                    LazyVStack{
                        Section("最新20条账单"){
                            ForEach(miniAccountModel.billList.prefix(20)){ itemIndex in
                                let itemType = itemIndex.billType ?? miniAccountModel.billTypeList[0]
                                let itemAccount = itemIndex.account ?? miniAccountModel.accountList[0]
                                VStack{
                                    VStack{
                                        HStack{
                                            VStack(alignment: .leading){
                                                let typeColor = itemType.type ? Color.red:Color.green
                                                Text(itemType.typeName ?? "").foregroundColor(typeColor)
                                                Text(itemIndex.remark ?? "").lineLimit(1).truncationMode(.tail)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing){
                                                let amountText = (itemType.type ? "+":"-") + String(format :"%.2f", itemIndex.amount)
                                                Text(itemAccount.accountName ?? "")
                                                Text(amountText)
                                            }
                                        }.contentShape(Rectangle())
                                        .onTapGesture {
                                            showBillDetailView = true
                                            showBill = miniAccountModel.billList.firstIndex(of: itemIndex) ?? 0
                                        }
                                    }.frame(maxWidth: .infinity).padding(.horizontal)
                                        .background(Color(UIColor.tertiarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 8.0))
                                }.padding(.horizontal)
                            }
                        }
                        if !miniAccountModel.billList.isEmpty {
                            NavigationLink(destination: BillListView(miniDB:miniAccountModel,showDetail: miniAccountModel.billList[0]), label: {Text("全部账单")}).padding()
                        }else{
                            Text("没有更多数据啦～").padding()
                        }
                    }
                }.background(Color(UIColor.systemGroupedBackground))
                Button(action:{
                    showAddNewBill = true
                }){
                    Image(systemName: "plus.circle.fill").resizable().frame(width: 50,height: 50).background().cornerRadius(25)
                }.padding(36)
            }.sheet(isPresented: $showBillDetailView){
                BillDetailSheetView(miniDB:miniAccountModel,showBill: $miniAccountModel.billList[showBill])
            }.sheet(isPresented: $showAddNewBill){
                if !miniAccountModel.accountList.isEmpty && !miniAccountModel.billTypeList.isEmpty{
                    AddBillSheetView(miniDB:miniAccountModel, selecetedAccount: miniAccountModel.accountList[0], selecetedBillType: miniAccountModel.billTypeList[0])
                }else{
                    VStack{
                        Image(systemName: "questionmark.bubble").resizable().frame(width: 100, height: 100).foregroundStyle(.tertiary).foregroundColor(.red)
                        Text("没有找到账户或类型？")
                    }
                }
            }.sheet(isPresented: $firstTimeOpen){
                NavigationStack{
                    VStack{
                        Text("The first time you use MiniAccount, you can enter some basic information in this page")
                        Form{
                            Section("User Name"){
                                TextField("怎么称呼你", text: $userName)
                            }
                            Section("First Account"){
                                TextField("账户名称",text: $accountName)
                                TextField("账号",text: $accountNum)
                                HStack{
                                    Text("当前余额：")
                                    let numberFormatter: NumberFormatter = {
                                        let nf = NumberFormatter()
                                        nf.numberStyle = .decimal
                                        nf.maximumFractionDigits = 2
                                        return nf
                                    }()
                                    TextField("输入余额",value: $balance, formatter: numberFormatter ).keyboardType(.decimalPad)
                                }
                                Picker("账户类型",selection: $accountTypeStr){
                                    Text("储蓄").tag("储蓄")
                                    Text("信用").tag("信用")
                                }
                                Toggle(isOn: $showHomePage) {
                                    Text("首页展示")
                                }
                                Toggle(isOn: $defaultAccount){
                                    Text("默认使用账户")
                                }
                                HStack{
                                    Text("标记颜色")
                                    Spacer()
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 16).frame(width:50).foregroundStyle(selectedColor)
                                        Image(systemName: showColorPanel ? "chevron.compact.up":"chevron.compact.down").foregroundColor(Color("WhiteBlackColor"))
                                    }.onTapGesture {
                                        showColorPanel = !showColorPanel
                                    }
                                }
                                if showColorPanel {
                                    withAnimation(.easeInOut){
                                        LazyVGrid(columns: Array(repeating: GridItem(), count: 5)) {
                                            ForEach(colorList,id:\.self){color in
                                                Circle().frame(width: 40,height: 40)
                                                    .foregroundStyle(color)
                                                    .opacity(0.8)
                                                    .scaleEffect(color == selectedColor ? 0.7 : 1)
                                                    .onTapGesture{
                                                        withAnimation{
                                                            selectedColor = color
                                                        }
                                                    }
                                                    .overlay{
                                                        Circle().stroke(lineWidth: 3).foregroundStyle(color == selectedColor ? .gray : .clear)
                                                    }
                                            }
                                        }.frame(height:100)
                                    }
                                }
                            }
                        }
                    }.navigationTitle("Welcome").toolbar{
                        Button{
                            if accountTypeStr=="储蓄" {accountType = 1} else {accountType = 2}
                            let newAccount = AccountEntity(context: miniAccountModel.container.viewContext)
                            newAccount.accountName = accountName
                            newAccount.accountNum = accountNum
                            newAccount.accountType = accountType
                            newAccount.balance = balance
                            newAccount.showHomePage = showHomePage
                            newAccount.defaultAccount = defaultAccount
                            newAccount.bgColor = Int64(colorList.firstIndex(of: selectedColor) ?? 0)
                            miniAccountModel.saveFirstAccount()
                            firstTimeOpen = false
                        }label:{
                            Image(systemName: "arrow.up.circle.fill")
                        }.disabled((accountNum == "" || accountName==""))
                    }
                }
            }
        }
    }
}
