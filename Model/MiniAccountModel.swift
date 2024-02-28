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
        let onMoveType = source.first!
        if onMoveType < destination{
            var startIndex = onMoveType + 1
            let endIndex = destination + 1
            var startType = billTypeList[onMoveType].order
            while startIndex <= endIndex{
                billTypeList[startIndex].order = startType
                startType += 1
                startIndex += 1
            }
            billTypeList[onMoveType].order = startType
        }else{
            var startIndex = destination
            let endIndex = onMoveType - 1
            var startType = billTypeList[destination].order + 1
            let newType = billTypeList[destination].order
            while startIndex <= endIndex {
                billTypeList[startIndex].order = startType
                startIndex += 1
                startType += 1
            }
            billTypeList[onMoveType].order = newType
        }
        billTypeList.move(fromOffsets: source, toOffset: destination)
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
    
}
