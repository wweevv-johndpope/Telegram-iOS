//
//  WEVSearchRecordManager.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/20.
//

import Foundation
struct WEVSearchRecordManager {
    
    /// 最大保存数量
    private static let maxCount = 10
    
    /// 记录列表
    static private(set) var recordArray: [String] = {
        var recordArray: [String] = []
        if let data = LJUserDefaults.liveSearchRecord,
           let array = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String] {
            recordArray = array
        }
        return recordArray
    }()
    
    /// 添加记录
    public static func add(record: String) {
        if let index = recordArray.firstIndex(where: {$0 == record}) {
            recordArray.remove(at: index)
        }
        recordArray.insert(record, at: 0)
        if recordArray.count > maxCount {
            recordArray = Array(recordArray[0..<maxCount])
        }
        save()
    }
    
    /// 删除记录
    public static func remove(record: String) {
        recordArray.removeAll(where: {$0 == record})
        save()
    }

    /// 保存在沙盒
    private static func save() {
        if let data = try? JSONSerialization.data(withJSONObject: recordArray, options: JSONSerialization.WritingOptions.fragmentsAllowed) {
            LJUserDefaults.liveSearchRecord = data
        }
    }
}

struct LJUserDefaults {

    private static let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    
    /// 用户信息
    static var userString: String? {
        get {
            UserDefaults.standard.value(forKey: userStringKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userStringKey)
        }
    }
    private static let userStringKey = "\(bundleId).userString"

    /// 直播搜索记录
    static var liveSearchRecord: Data? {
        get {
            UserDefaults.standard.value(forKey: liveSearchRecordKey) as? Data
        }
        set {
            UserDefaults.standard.set(newValue, forKey: liveSearchRecordKey)
        }
    }
    private static let liveSearchRecordKey = "\(bundleId).liveSearchRecord"





}
