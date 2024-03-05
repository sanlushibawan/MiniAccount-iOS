//
//  ExportBillView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/3/4.
//

import SwiftUI

struct ExportBillView: View {
    @ObservedObject var dbContext:MiniAccountModel
    @AppStorage("userName") private var userName = ""
    @State var startDate = Date()
    @State var endDate = Date()
    @State private var jsonDocument = JSONDocument(JSONtext: "",userName: "")
    @State var showExport = false
    var body: some View {
        NavigationStack{
            VStack{
                VStack{
                    DatePicker(selection: $startDate, label: {Text("开始")}).padding(.horizontal)
                    DatePicker(selection: $endDate, label: {Text("结束")}).padding(.horizontal)
                    Button{
                        dbContext.findBillsBy(byDate: true, byRemark: false, startDate: startDate, endDate: endDate, keyWord: "")
                        jsonDocument.content = dbContext.exportJSON()
                        jsonDocument.userName = userName
                    }label: {
                        Text("查找账单")
                    }.buttonStyle(.borderedProminent).disabled(startDate >= endDate)
                }
                List{
                    if dbContext.billListBy.isEmpty {
                        Text("一条数据也没找到，请先选择时间段，然后查找账单吧")
                    }
                    ForEach(dbContext.billListBy,id:\.id){ billItem in
                        let billTypeItem = billItem.billType ?? dbContext.billTypeList[0]
                        let accountItem = billItem.account ?? dbContext.accountList[0]
                        VStack{
                            HStack{
                                Text(billItem.orderByDate ?? Date(), style: .date)
                                Spacer()
                                let typeColor = billTypeItem.type ? Color.red : Color.green
                                Text(billTypeItem.typeName ?? "").foregroundColor(typeColor)
                                Image(systemName: billTypeItem.type ?
                                      "square.and.arrow.down":"square.and.arrow.up").foregroundColor(typeColor)
                            }
                            HStack{
                                let accountText = (accountItem.accountName ?? "") + "&" + (accountItem.accountNum ?? "").suffix(4)
                                Text(accountText)
                                Spacer()
                                let amountText = (billTypeItem.type ? "+":"-") + String(format :"%.2f", billItem.amount)
                                Text(amountText)
                            }
                            HStack(){
                                Text("备注").foregroundColor(Color(UIColor.placeholderText)).font(Font.caption)
                                Text(billItem.remark ?? "").lineLimit(1).truncationMode(.tail)
                                Spacer()
                            }
                        }
                    }.onDelete { IndexSet in
                        dbContext.billListBy.remove(at: IndexSet.first!)
                    }
                }
            }
        }.navigationTitle("数据备份").toolbar{
            ShareLink(item: jsonDocument,preview: SharePreview("\(userName)_mini_backup.json",image: Image("JSON"))){
                Text("开始备份")
            }.disabled(dbContext.billListBy.isEmpty)
        }.onAppear{
            dbContext.billListBy.removeAll()
        }
    }
}
