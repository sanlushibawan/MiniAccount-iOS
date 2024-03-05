//
//  ExportJSONFile.swift
//  MiniAccount-iOS
//
//  Created by suanlushibawan on 2024/3/4.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

struct MiniAccountJSON:Codable{
    var accountList:[AccountJSON] = []
    var billTypeList:[BillTypeJSON] = []
    var billList:[BillJSON] = []
}
struct AccountJSON:Codable,Identifiable{
    var id = UUID()
    var accountName:String?
    var accountNum:String?
    var accountType:Int64?
    var balance:Double?
    var showHomePage:Bool?
    var bgColor:Int64?
}
struct BillTypeJSON:Codable,Identifiable{
    var id = UUID()
    var order:Int64?
    var type:Bool?
    var typeName:String?
}
struct BillJSON:Codable,Identifiable{
    var id = UUID()
    var amount:Double?
    var remark:String?
    var orderByDate:Date?
    var billType:BillTypeJSON?
    var account:AccountJSON?
}

struct JSONDocument:FileDocument, Transferable{
    static var readableContentTypes: [UTType] = [.json]
    var userName = ""
    var content = ""
    init(JSONtext: String,userName:String) {
        self.content = JSONtext
        self.userName = userName
    }
    init(configuration: ReadConfiguration) throws {
            if let data = configuration.file.regularFileContents {
                content = String(decoding: data, as: UTF8.self)
            } else {
                content = ""
            }
        }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: Data(content.utf8))
        }
    
    static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(exportedContentType: .json) { log in
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(log.userName)_mini_backup").appendingPathExtension(".json")
                try Data(log.content.utf8).write(to: fileURL)
                return SentTransferredFile(fileURL)
            }
        }
}
