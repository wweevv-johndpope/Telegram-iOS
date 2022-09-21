//
//  LJDebugLogModel.swift
//  FairfieldUser
//
//  Created by panjinyong on 2021/7/9.
//

import Foundation
struct LJDebugLogModel: Codable {
    /// id
    var logId: String
    /// 创建时间
    var createDate: Date
    /// 日志文件名字
    var fileName: String
    /// 日志文本内容
    var text: String = ""
    /// 是否崩溃
    var isCrash: Bool = false
}
