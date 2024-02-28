//
//  BillListView.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/2/22.
//

import SwiftUI

struct BillListView: View {
    @ObservedObject var miniDB:MiniAccountModel
    @State var startDate = Date()
    @State var endDate = Date()
    @State var showDatePicker = false
    @State var showKeyWordSearch = false
    @State var keyWordInput = ""
    @State var showDetailSheet = false
    @State var showCleanText = false
    @State var showCountSheet = false
    @State var showDetail:BillEntity
    var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    VStack{
                        if showDatePicker {
                            VStack{
                                DatePicker(selection: $startDate ,displayedComponents: [.date], label: { Text("开始") })
                                DatePicker(selection: $endDate ,displayedComponents: [.date], label: { Text("结束") })
                            }
                        }
                        if showKeyWordSearch {
                            HStack{
                                TextField("检索关键字", text: $keyWordInput)
                            }
                        }
                    }
                    if showDatePicker || showKeyWordSearch {
                        Button{
                            refresh()
                            showCleanText = true
                        }label: {
                            Image(systemName: "magnifyingglass")
                        }.buttonStyle(.borderedProminent).disabled((showDatePicker ? startDate >= endDate : false)||(showKeyWordSearch ? keyWordInput == "" : false))
                    }
                }.padding(.horizontal).animation(.easeInOut,value: true)
                if showCleanText {
                    HStack(alignment: .center){
                        Text("条件检索结果").foregroundColor(Color(UIColor.placeholderText))
                        Spacer()
                        Button{
                            showDatePicker = false
                            showKeyWordSearch = false
                            startDate = Date()
                            endDate = Date()
                            keyWordInput = ""
                            showCleanText = false
                            refresh()
                        }label: {
                            Image(systemName: "x.circle.fill")
                        }.buttonStyle(.plain)
                    }.padding(.horizontal)
                }
                List{
                    ForEach(miniDB.billListBy,id:\.id){ billItem in
                        let billTypeItem = billItem.billType ?? miniDB.billTypeList[0]
                        let accountItem = billItem.account ?? miniDB.accountList[0]
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
                        }.onTapGesture{
                            showDetail = billItem
                            showDetailSheet = true
                        }
                    }.onDelete(perform: miniDB.removeBill)
                }
            }
        }.navigationTitle("全部账单").toolbar{
            Menu{
                Button{showDatePicker = !showDatePicker}label: {
                    Label("日期",systemImage: "calendar")
                }
                Button{showKeyWordSearch = !showKeyWordSearch}label: {
                    Label("备注关键词",systemImage: "doc.text.magnifyingglass")
                }
                Button{showCountSheet = !showCountSheet}label:{
                    Label("统计",systemImage: "chart.pie")
                }
            }label: {
                Image(systemName: "line.3.horizontal").foregroundColor(.accentColor)
            }
        }.sheet(isPresented: $showDetailSheet, content: {
            BillDetailSheetView(miniDB: miniDB,showBill: $showDetail)
        }).sheet(isPresented: $showCountSheet, content: {
            CountBillSheetview(miniDB: miniDB)
        }).onAppear(){
            refresh()
        }
    }
    
    func refresh(){
        miniDB.findBillsBy(byDate: showDatePicker, byRemark: showKeyWordSearch, startDate: startDate, endDate: endDate, keyWord: keyWordInput)
    }
}
