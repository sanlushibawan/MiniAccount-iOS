//
//  SheetViews.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/22.
//

import SwiftUI
import PhotosUI
import Charts

struct AddBillSheetView: View {
    @ObservedObject var miniDB: MiniAccountModel
    
    @State var selecetedAccount: AccountEntity
    @State var selecetedBillType: BillTypeEntity
    @State var remarkInput = ""
    @State var amountInput = 0.0
    @Environment(\.dismiss) private var close
    @State var dateTime = Date()
    @State private var numberFormatter: NumberFormatter = {
        var nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf
    }()
    var body: some View {
        NavigationStack{
            VStack{
                Form{
                    DatePicker(selection: $dateTime, displayedComponents: [.date], label: { Text("Trading date") })
                    Section("账户&类型"){
                        Picker("账户选择",selection: $selecetedAccount){
                            ForEach(miniDB.accountList){accountItem in
                                let accountNameAndNum = (accountItem.accountName ?? "") + "&" + (accountItem.accountNum ?? "").suffix(4)
                                Text(accountNameAndNum).tag(accountItem)
                            }
                        }
                        Picker("类型选择",selection: $selecetedBillType){
                            ForEach(miniDB.billTypeList){billTypeItem in
                                Label(billTypeItem.typeName ?? "",
                                      systemImage: billTypeItem.type ? "square.and.arrow.down":"square.and.arrow.up")
                                .tag(billTypeItem)
                            }
                        }
                    }
                    Section("金额&备注"){
                        HStack{
                            Text("金额")
                            TextField("收/支 金额", value: $amountInput, formatter: numberFormatter).keyboardType(.decimalPad)
                        }
                        ZStack{
                            if remarkInput.isEmpty  {Text("备注信息(选填)").foregroundColor(Color(UIColor.placeholderText))}
                            TextEditor(text: $remarkInput).lineSpacing(5)
                        }
                    }
                }
            }.toolbar{
                Button{
                    miniDB.addBill(selecetAccount: selecetedAccount, selecetType: selecetedBillType, amountInput: amountInput, remarkInput: remarkInput, pickDate: dateTime)
                    close()
                }label: {
                    Image(systemName: "paperplane.fill")
                }.disabled(amountInput == 0.0)
            }.navigationTitle("添加账单")
        }
    }
}

struct BillDetailSheetView: View {
    @ObservedObject var miniDB:MiniAccountModel
    @Binding var showBill:BillEntity
    @State var selectedDate = Date()
    @State var remarkInput = ""
    @State var editBill = false
    @FocusState var remarkFocuse:Bool
    @Environment(\.dismiss) var closeSheet
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    let type = showBill.billType ?? BillTypeEntity()
                    let account = showBill.account ?? AccountEntity()
                    if editBill{DatePicker("Trading date",selection: $selectedDate,displayedComponents: [.date])}
                    else{Text(showBill.orderByDate ?? Date(), style: .date)}
                    Text("\(account.accountName ?? "")(\(account.accountNum ?? ""))")
                    HStack{
                        Text(type.typeName ?? "")
                        Spacer()
                        Image(systemName: type.type ?  "square.and.arrow.down":"square.and.arrow.up")
                    }
                    HStack{
                        Text(type.type ? "+" : "-")
                        Text(String(format: "%.2F", showBill.amount))
                    }
                    if editBill{
                        ZStack{
                            if remarkInput.isEmpty  {Text("备注信息(选填)").foregroundColor(Color(UIColor.placeholderText))}
                            TextEditor(text: $remarkInput).lineSpacing(5).focused($remarkFocuse)
                        }
                        Button{
                            showBill.orderByDate = selectedDate
                            showBill.remark = remarkInput
                            miniDB.saveBills()
                            closeSheet()
                        }label: {
                            Text("提交修改")
                        }
                    }else{
                        VStack(alignment: .leading,spacing: 12){
                            Text("备注").foregroundColor(Color(UIColor.placeholderText)).font(Font.caption)
                            Text(showBill.remark ?? "")
                        }
                    }
                }
                
            }.navigationTitle("账单详情").toolbar{
                Button{
                    editBill = !editBill
                    remarkFocuse = editBill
                }label: {
                    if editBill {Image(systemName: "xmark.circle.fill")}
                    else {Image(systemName: "square.and.pencil.circle.fill")}
                }
            }
        }.onAppear{
            selectedDate = showBill.orderByDate ?? Date()
            remarkInput = showBill.remark ?? ""
        }
    }
}


struct EditAccountSheetView: View{
    @Binding var showType:Bool //true 为添加新账户 false 为编辑账户
    @ObservedObject var dbvm:MiniAccountModel
    @Binding var editIndex:Int
    @Environment(\.dismiss) private var dismiss
    //临时保存数据
    @State var accountName:String = ""
    @State var accountNum:String = ""
    @State var accountType:Int64 = 0
    @State var balance:Double = 0.0
    @State var showHomePage:Bool = true
    @State var defaultAccount:Bool = false
    @State var accountTypeStr:String = "储蓄"
    @State var selectedColor = Color("BlackWhiteColor")
    @State var showColorPanel = false
    let colorList = [Color("BlackWhiteColor"),.orange,.yellow,.mint,.teal,.cyan,.blue,.purple,.pink,.brown]
    var body: some View{
            NavigationStack{
                VStack{
                    List{
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
                    
                }.navigationTitle(showType ? "添加账户" : "编辑账户").toolbar{
                Button(action:{
                    if defaultAccount{
                        dbvm.accountList.forEach { account in
                            account.defaultAccount = false
                        }
                    }
                    if accountTypeStr=="储蓄" {accountType = 1} else {accountType = 2}
                    let newAccount = showType ? AccountEntity(context: dbvm.container.viewContext):dbvm.accountList[editIndex]
                    newAccount.accountName = accountName
                    newAccount.accountNum = accountNum
                    newAccount.accountType = accountType
                    newAccount.balance = balance
                    newAccount.showHomePage = showHomePage
                    newAccount.defaultAccount = defaultAccount
                    newAccount.bgColor = Int64(colorList.firstIndex(of: selectedColor) ?? 0)
                    dbvm.saveAccountData()
                    dismiss()
                }){
                    Image(systemName: "arrow.up.circle.fill")
                }.disabled((accountNum == "" || accountName==""))
            }
            }.onAppear(){
                if showType == false {
                    let editAccount = dbvm.accountList[editIndex]
                    accountName = (editAccount.accountName ?? "")
                    accountNum = editAccount.accountNum ?? ""
                    accountType = editAccount.accountType
                    balance = editAccount.balance
                    showHomePage = editAccount.showHomePage
                    defaultAccount = editAccount.defaultAccount
                    selectedColor = colorList[Int(editAccount.bgColor)]
                }
            }
    }
}


struct EditBillTypeSheet:View{
    @ObservedObject var miniDB:MiniAccountModel
    @Binding var updateIndex:Int
    @State var billTypeName = ""
    @State var inComeType = false
    @FocusState var editTypeName:Bool
    @Environment(\.dismiss) private var close
    var body: some View{
        VStack{
            Form{
                Section("修改消费类型"){
                    Toggle(isOn: $inComeType, label: {Text(inComeType ? "收入":"支出")})
                    HStack{
                        TextField("消费类型",text: $billTypeName).focused($editTypeName)
                            .submitLabel(.done)
                            .onSubmit {
                                let newBillType = miniDB.billTypeList[updateIndex]
                                newBillType.type = inComeType
                                newBillType.typeName = billTypeName
                                miniDB.saveBillType()
                                close()
                            }
                        Button{
                            editTypeName = false
                            let newBillType = miniDB.billTypeList[updateIndex]
                            newBillType.type = inComeType
                            newBillType.typeName = billTypeName
                            miniDB.saveBillType()
                            close()
                        }label: {
                            Image(systemName: "pencil.line")
                        }.buttonStyle(.borderedProminent).disabled(billTypeName=="")
                    }
                }
            }
        }.onAppear(){
            let updateBillType = miniDB.billTypeList[updateIndex]
            billTypeName = updateBillType.typeName ?? ""
            inComeType = updateBillType.type
        }
    }
}

struct CountBillSheetview:View {
    @ObservedObject var miniDB:MiniAccountModel
    @State var chartValue:[ChartValue] = []
    @State var accountChartV:[ChartValue] = []
    var body: some View {
        NavigationStack{
            VStack{
                if #available(iOS 17.0, *){
                    Form{
                        Section("类型统计"){
                            Chart(chartValue,id: \.name){ valueItem in
                                if valueItem.money != 0.0{
                                    SectorMark(angle: .value("Money", valueItem.money),innerRadius: .ratio(0.3),angularInset: 1.0)
                                        .foregroundStyle(by: .value("Name", valueItem.name)).cornerRadius(8).annotation(position:.overlay,content: {
                                            Text(String(format: "%.2F", valueItem.money)).font(.headline).foregroundStyle(.white)
                                        })
                                }
                            }.frame(height:300)
                            ForEach(chartValue,id: \.id) { value in
                                HStack{
                                    Text("\(value.name):")
                                    Text("¥\(String(format: "%.2F", value.money))")
                                }
                            }
                        }
                        Section("账户统计"){
                            Chart(accountChartV,id: \.name){ valueItem in
                                if valueItem.money != 0.0{
                                    SectorMark(angle: .value("Money", valueItem.money),innerRadius: .ratio(0.3),angularInset: 1.0)
                                        .foregroundStyle(by: .value("Name", valueItem.name)).cornerRadius(8).annotation(position:.overlay,content: {
                                            Text(String(format: "%.2F", valueItem.money)).font(.headline).foregroundStyle(.white)
                                        })
                                }
                            }.frame(height:300)
                            ForEach(accountChartV,id: \.id) { value in
                                HStack{
                                    Text("\(value.name):")
                                    Text("¥\(String(format: "%.2F", value.money))")
                                }
                            }
                        }
                    }
                }else{
                    Form{
                        Section("类型统计"){
                            Chart(chartValue,id: \.name){ valueItem in
                                if valueItem.money != 0.0{
                                    BarMark(
                                        x: .value("Category", valueItem.name),
                                        y: .value("Value", valueItem.money)
                                    ).foregroundStyle(by: .value("name", valueItem.name))
                                }
                            }.frame(height:300)
                            ForEach(chartValue,id: \.id) { value in
                                HStack{
                                    Text("\(value.name):")
                                    Text("¥\(String(format: "%.2F", value.money))")
                                }
                            }
                        }
                        Section("账户统计"){
                            Chart(accountChartV,id: \.name){ valueItem in
                                if valueItem.money != 0.0{
                                    BarMark(
                                        x: .value("Category", valueItem.name),
                                        y: .value("Value", valueItem.money)
                                    ).foregroundStyle(by: .value("name", valueItem.name))
                                }
                            }.frame(height:300)
                            ForEach(accountChartV,id: \.id) { value in
                                HStack{
                                    Text("\(value.name):")
                                    Text("¥\(String(format: "%.2F", value.money))")
                                }
                            }
                        }
                    }
                }
            }.onAppear{
                getChartValue()
            }.navigationTitle("数据统计")
        }
    }
    
    func getChartValue(){
        let typeList:[BillTypeEntity] = miniDB.billTypeList
        let billList:[BillEntity] = miniDB.billListBy
        let accountList = miniDB.accountList
        for typeIndex in typeList{
            var moneyTotal = 0.0
            for billIndex in billList {
                if typeIndex == billIndex.billType {
                    moneyTotal += billIndex.amount
                }
            }
            if typeIndex.type{
                chartValue.append(ChartValue(name:(typeIndex.typeName ?? "") + String(localized: "Income"),money: moneyTotal))
            }else{
                chartValue.append(ChartValue(name:(typeIndex.typeName ?? "") + String(localized: "Payout"),money: moneyTotal))
            }
        }
        for accountIndex in accountList{
            var moneyTotal = 0.0
            var payMoneyTotal = 0.0
            for billIndex in billList {
                if accountIndex == billIndex.account {
                    let type = billIndex.billType ?? typeList[0]
                    if type.type {moneyTotal += billIndex.amount}
                    else {payMoneyTotal += billIndex.amount}
                }
            }
            accountChartV.append(ChartValue(name:(accountIndex.accountName ?? "") + String(localized: "Income"),money: moneyTotal))
            accountChartV.append(ChartValue(name:(accountIndex.accountName ?? "") + String(localized: "Payout"),money: payMoneyTotal))
        }
    }
}

struct ImportDataSheetView:View {
    @ObservedObject var miniDB:MiniAccountModel
    @State private var showLoading = false
    var body: some View {
        NavigationStack{
            ZStack{
                if !miniDB.miniJSON.billList.isEmpty{
                    List{
                        Section("导入账户"){
                            ForEach(miniDB.miniJSON.accountList,id:\.id){ accountItem in
                                VStack{
                                    HStack{
                                        Text(accountItem.accountName ?? "")
                                        Spacer()
                                        if accountItem.accountType == 1{
                                            Text("储蓄")
                                            Image(systemName: "creditcard.fill")
                                        }else{
                                            Text("信用")
                                            Image(systemName: "creditcard")
                                        }
                                        Spacer()
                                        Text(String(format:"%.2F", accountItem.balance ?? 0.0))
                                    }
                                    Text(accountItem.accountNum ?? "")
                                }
                            }.onDelete(perform: { indexSet in
                                miniDB.miniJSON.accountList.remove(at: indexSet.first!)
                            })
                        }
                        Section("导入类型"){
                            ForEach(miniDB.miniJSON.billTypeList,id:\.id){typeItem in
                                HStack{
                                    if !(typeItem.type ?? false) {Image(systemName: "square.and.arrow.up").foregroundColor(.green).foregroundStyle(.secondary)}else{Image(systemName: "square.and.arrow.down").foregroundColor(.red).foregroundStyle(.secondary)}
                                    Text(typeItem.typeName ?? "")
                                    Spacer()
                                    Text((typeItem.type ?? false) ? "收入":"支出")
                                }
                            }.onDelete { indexSet in
                                miniDB.miniJSON.billTypeList.remove(at: indexSet.first!)
                            }
                        }
                        Section("导入账单"){
                            ForEach(miniDB.miniJSON.billList,id:\.id){billItem in
                                let billTypeItem = billItem.billType ?? BillTypeJSON()
                                let accountItem = billItem.account ?? AccountJSON()
                                VStack{
                                    HStack{
                                        Text(billItem.orderByDate ?? Date(), style: .date)
                                        Spacer()
                                        let typeColor = (billTypeItem.type ?? false) ? Color.red : Color.green
                                        Text(billTypeItem.typeName ?? "").foregroundColor(typeColor)
                                        Image(systemName: (billTypeItem.type ?? false) ?
                                              "square.and.arrow.down":"square.and.arrow.up").foregroundColor(typeColor)
                                    }
                                    HStack{
                                        let accountText = (accountItem.accountName ?? "") + "&" + (accountItem.accountNum ?? "").suffix(4)
                                        Text(accountText)
                                        Spacer()
                                        let amountText = ((billTypeItem.type ?? false) ? "+":"-") + String(format :"%.2f", billItem.amount ?? 0.0)
                                        Text(amountText)
                                    }
                                    HStack(){
                                        Text("备注").foregroundColor(Color(UIColor.placeholderText)).font(Font.caption)
                                        Text(billItem.remark ?? "").lineLimit(1).truncationMode(.tail)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                if showLoading{
                    withAnimation{
                        ProgressView()
                    }
                }
                if miniDB.finishImport{
                    withAnimation{
                        VStack{
                            Image(systemName: "checkmark.rectangle.stack.fill").resizable().frame(width: 200, height: 200).foregroundStyle(Color.green)
                            Text("导入数据成功，请从顶部下拉关闭弹窗").foregroundStyle(Color.green)
                        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Color.black.opacity(0.7))
                    }
                }
            }.navigationTitle("数据导入").toolbar{
                Button{
                    miniDB.importJSONToDB()
                    showLoading = true
                }label: {
                    Image(systemName: "arrow.down.left.square.fill")
                }.disabled(miniDB.finishImport)
            }
        }
    }
}
