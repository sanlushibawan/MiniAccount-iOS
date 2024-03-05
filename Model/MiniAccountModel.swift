//
//  MiniAccountModel.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/23.
//

import CoreData

final class MiniAccountModel:ObservableObject{
    @Published var accountList:[AccountEntity] = []
    @Published var billTypeList:[BillTypeEntity] = []
    @Published var billList: [BillEntity] = []
    @Published var billListBy: [BillEntity] = []
    @Published var searchingBills:Bool = true
    @Published var databaseError:Bool = false
    @Published var miniJSON:MiniAccountJSON = MiniAccountJSON()
    let container:NSPersistentContainer
    init(){
        container = NSPersistentContainer(name: "MiniAccountModel")
        container.loadPersistentStores{ _, error in if error != nil{
            //database load error
            self.databaseError = true}
        }
        fetchAccountReuqest()
        fetchBillType()
        fetchBills()
    }
    func fetchAccountReuqest(){
        let sort = NSSortDescriptor(key: "defaultAccount", ascending: false)
        let request = NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
        request.sortDescriptors = [sort]
        do{
            try? accountList = container.viewContext.fetch(request)
        }
    }
    
    func deleteAccount(account:AccountEntity){
        container.viewContext.delete(account)
        fetchBills()
        saveAccountData()
    }
    func saveAccountData(){
        do{
            try? container.viewContext.save()
            fetchAccountReuqest()
        }
    }
    func saveFirstAccount(){
        let newBillType = BillTypeEntity(context: container.viewContext)
        newBillType.typeName = String(localized: "Payout")
        newBillType.type = false
        let newBillType2 = BillTypeEntity(context: container.viewContext)
        newBillType2.typeName = String(localized: "Income")
        newBillType2.type = true
        do{
            try? container.viewContext.save()
            fetchAccountReuqest()
            fetchBillType()
        }
    }
    
    //billType func
    func fetchBillType(){
        let request = NSFetchRequest<BillTypeEntity>(entityName: "BillTypeEntity")
        let sort = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sort]
        do {try? billTypeList = container.viewContext.fetch(request)}
    }
    func addBillType(typeName:String,isIncome:Bool){
        let newBillType = BillTypeEntity(context: container.viewContext)
        newBillType.typeName = typeName
        newBillType.type = isIncome
        newBillType.order = Int64(billTypeList.count)
        do{ try? container.viewContext.save()
            billTypeList.append(newBillType)
        }
    }
    func saveBillType(){
        do{ try? container.viewContext.save()
            fetchBillType()
        }
    }
    func removeBillType(at offset:IndexSet){
        guard let index = offset.first else {return}
        let deleteBillType = billTypeList[index]
        container.viewContext.delete(deleteBillType)
        fetchBills()
        saveBillType()
    }
    func moveBillType(at source:IndexSet, destination:Int){
        billTypeList.move(fromOffsets: source, toOffset: destination)
        var newOrder:Int64 = 0
        for typeIndex in billTypeList{
            typeIndex.order = newOrder
            newOrder += 1
        }
        do{ try? container.viewContext.save() }
    }
    
    //bills func
    func fetchBills(){
        let request = NSFetchRequest<BillEntity>(entityName: "BillEntity")
        let sort = NSSortDescriptor(key: "orderByDate", ascending: false)
        request.sortDescriptors = [sort]
        do {try? billList = container.viewContext.fetch(request)}
    }
    func addBill(selecetAccount:AccountEntity,selecetType:BillTypeEntity,amountInput:Double,remarkInput:String, pickDate:Date){
        let newBill = BillEntity(context: container.viewContext)
        newBill.account = selecetAccount
        newBill.billType = selecetType
        newBill.amount = amountInput
        newBill.remark = remarkInput
        newBill.orderByDate = pickDate
        if selecetType.type { selecetAccount.balance += amountInput}
        else {selecetAccount.balance -= amountInput }
        saveBills()
    }
    func findBillsBy(byDate:Bool,byRemark:Bool,startDate:Date,endDate:Date,keyWord:String){
        let request = NSFetchRequest<BillEntity>(entityName: "BillEntity")
        if(byDate && byRemark){
            request.predicate = NSPredicate(format: "orderByDate between {%@ , %@} AND remark CONTAINS %@", startDate as CVarArg,endDate as CVarArg, keyWord)
        }else {
            if byDate {
                request.predicate = NSPredicate(format: "orderByDate between {%@ , %@}", startDate as CVarArg,endDate as CVarArg)
            }
            if byRemark{
                request.predicate = NSPredicate(format: "remark CONTAINS %@", keyWord)
            }
        }
        
        let sort = NSSortDescriptor(key: "orderByDate", ascending: false)
        request.sortDescriptors = [sort]
        do{
            try? billListBy = container.viewContext.fetch(request)
        }
    }
    //只在billList页面使用
    func removeBill(at offset:IndexSet){
        guard let index = offset.first else {return}
        let deleteBill = billListBy[index]
        container.viewContext.delete(deleteBill)
        do{ try? container.viewContext.save()
            billListBy.remove(at: index)
            fetchBills()
        }
    }
    
    func saveBills(){
        do{ try? container.viewContext.save()
            fetchBills()
        }
    }
    
    func findBillsByType(billType:BillTypeEntity)->[BillEntity]{
        let request = NSFetchRequest<BillEntity>(entityName: "BillEntity")
        request.predicate = NSPredicate(format: "billType.id = %@", billType.id as! CVarArg)
        
        let sort = NSSortDescriptor(key: "orderByDate", ascending: false)
        request.sortDescriptors = [sort]
        var billList:[BillEntity] = []
        do{
            try? billList = container.viewContext.fetch(request)
            return billList
        }
    }
    
    
    func exportJSON()->String{
        var miniAccountJSON = MiniAccountJSON()
        for accountItem in accountList{
            var accountJson = AccountJSON()
            accountJson.accountName = accountItem.accountName
            accountJson.accountNum = accountItem.accountNum
            accountJson.accountType = accountItem.accountType
            accountJson.balance = accountItem.balance
            accountJson.showHomePage = accountItem.showHomePage
            accountJson.bgColor = accountItem.bgColor
            miniAccountJSON.accountList.append(accountJson)
        }
        for billTypeItem in billTypeList{
            let billTypeJSON = BillTypeJSON(order: billTypeItem.order,type:billTypeItem.type,typeName: billTypeItem.typeName)
            miniAccountJSON.billTypeList.append(billTypeJSON)
        }
        for billItem in billListBy{
            var billJSON = BillJSON()
            billJSON.remark = billItem.remark
            billJSON.orderByDate = billItem.orderByDate
            billJSON.amount = billItem.amount
            let billAccount = billItem.account ?? accountList[0]
            billJSON.account = AccountJSON(accountName: billAccount.accountName,accountNum: billAccount.accountNum,
                                          accountType: billAccount.accountType,balance: billAccount.balance,showHomePage: billAccount.showHomePage, bgColor: billAccount.bgColor)
            let billsBillType = billItem.billType ?? billTypeList[0]
            billJSON.billType = BillTypeJSON(order: billsBillType.order,type: billsBillType.type,typeName: billsBillType.typeName)
            miniAccountJSON.billList.append(billJSON)
        }
        do{
            let jsonData = try JSONEncoder().encode(miniAccountJSON)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            return jsonString
        }catch{
            return ""
        }
    }
    @Published var finishImport = false
    func getFileToJSON(url:URL){
        let data = try? Data(contentsOf: url)
        miniJSON = try! JSONDecoder().decode(MiniAccountJSON.self, from: data ?? Data())
    }
    
    @Published var loadingProgress = 0.0
    func importJSONToDB(){
        var start:Double = 0.0
        let total:Double = Double(miniJSON.accountList.count + miniJSON.billList.count + miniJSON.billTypeList.count)
        for accountIndex in miniJSON.accountList{
            let resAccount = accountList.filter { accountF in
                accountF.accountNum == accountIndex.accountNum && accountF.accountName == accountIndex.accountName
            }
            if resAccount.isEmpty{
                let newAccount = AccountEntity(context: container.viewContext)
                newAccount.accountName = accountIndex.accountName
                newAccount.accountNum = accountIndex.accountNum
                newAccount.accountType = accountIndex.accountType ?? 0
                newAccount.balance = accountIndex.balance ?? 0.0
                newAccount.bgColor = accountIndex.bgColor ?? 0
                newAccount.defaultAccount = false
                newAccount.showHomePage = accountIndex.showHomePage ?? false
                accountList.append(newAccount)
            }
            start += 1.0
            loadingProgress = start/total
        }
        for typeIndex in miniJSON.billTypeList{
            let resType = billTypeList.filter { billTypeI in
                billTypeI.typeName == typeIndex.typeName && billTypeI.type == typeIndex.type
            }
            if resType.isEmpty{
                let newType = BillTypeEntity(context: container.viewContext)
                newType.type = typeIndex.type ?? false
                newType.typeName = typeIndex.typeName
                newType.order = typeIndex.order ?? 0
                billTypeList.append(newType)
            }
            start += 1.0
            loadingProgress = start/total
        }
        for billIndex in miniJSON.billList{
            let resBill = billList.filter{billI in
                billI.amount == billIndex.amount && billI.remark == billIndex.remark &&
                billI.orderByDate == billIndex.orderByDate
            }
            if resBill.isEmpty{
                let newBill = BillEntity(context: container.viewContext)
                newBill.amount = billIndex.amount ?? 0.0
                newBill.orderByDate = billIndex.orderByDate
                newBill.remark = billIndex.remark
                let accountImport = billIndex.account ?? AccountJSON()
                let resAccount = accountList.filter { accountF in
                    accountF.accountNum == accountImport.accountNum && accountF.accountName == accountImport.accountName
                }
                if resAccount.isEmpty{
                    let accountN = AccountEntity(context: container.viewContext)
                    accountN.accountName = accountImport.accountName
                    accountN.accountNum = accountImport.accountNum
                    accountN.accountType = accountImport.accountType ?? 0
                    accountN.balance = accountImport.balance ?? 0.0
                    accountN.bgColor = accountImport.bgColor ?? 0
                    accountN.defaultAccount = false
                    accountN.showHomePage = accountImport.showHomePage ?? false
                    newBill.account = accountN
                }else{
                    newBill.account =  resAccount.first
                }
                let typeImport = billIndex.billType ?? BillTypeJSON()
                let resType = billTypeList.filter { billTypeI in
                    billTypeI.typeName == typeImport.typeName && billTypeI.type == typeImport.type
                }
                if resType.isEmpty{
                    let billTypeN = BillTypeEntity(context: container.viewContext)
                    billTypeN.type = typeImport.type ?? false
                    billTypeN.typeName = typeImport.typeName
                    billTypeN.order = typeImport.order ?? 0
                    newBill.billType = billTypeN
                }else{
                    newBill.billType = resType.first
                }
                billList.append(newBill)
            }
            start += 1.0
            loadingProgress = start/total
        }
        do{
            try? container.viewContext.save()
            finishImport = true
        }
    }
}