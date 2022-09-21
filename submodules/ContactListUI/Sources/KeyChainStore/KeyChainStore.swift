//
//  KeyChainStore.swift
//  ReceiptKeeper
//
//  Created by panjinyong on 2020/11/27.
//

import Foundation

struct KeyChainStore {
    
    /// 保存数据
    public static func save(service: String, data: Any) {
        //Get search dictionary
        var keychainQuery = getKeychainQuery(service: service)
        //Delete old item before add new item
        SecItemDelete(keychainQuery as CFDictionary)
        //Add new object to searchdictionary(Attention:the data format)
        do {
            let archived = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false)
            keychainQuery.updateValue(archived, forKey: kSecValueData as String)
            //Add item to keychain with the searchdictionary
            SecItemAdd(keychainQuery as CFDictionary, nil)
        } catch {
            print(error)
        }
    }
    
    /// 读取数据
    public static func load(service: String) -> Any? {
        var keychainQuery = getKeychainQuery(service: service)
        //Configure the search setting
        //Since in our simple case we areexpecting only a single attribute to be returned (the password) wecan set the attribute kSecReturnData to kCFBooleanTrue
        keychainQuery.updateValue(kCFBooleanTrue as Any, forKey: kSecReturnData as String)
        keychainQuery.updateValue(kSecMatchLimitOne as Any, forKey: kSecMatchLimit as String)
        
        var item: CFTypeRef?

        guard SecItemCopyMatching(keychainQuery as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        
        do {
            let record = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data)
            return record
        } catch {
            return nil
        }
    }
    
    /// 删除数据
    public static func delete(service: String) {
        let keychainQuery = getKeychainQuery(service: service)
        SecItemDelete(keychainQuery as CFDictionary)
    }
    
    private static func getKeychainQuery(service: String) -> Dictionary<String, Any> {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: service,
         kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

}



extension KeyChainStore {
    
    private static let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    
    /// 设备号
    static var uuid: String {
        get {
            let uuidKey = "\(bundleId).uuid"
            if let uuid = load(service: uuidKey) as? String {
                return uuid
            }else {
                let uuid = UUID.init().uuidString
                save(service: uuidKey, data: uuid)
                return uuid
            }
        }
    }
    
    
    /// apple 登录信息
    /*static var appleSignUserInfo: WEVThirdAccountManager.AccountInfo? {
        get {
            if let dic = load(service: appleSignUserInfoKey) as? [String: Any] {
                return WEVThirdAccountManager.AccountInfo.deserialize(from: dic)
            }else {
                return nil
            }
        }
        set {
            if let appleSignUserInfo = newValue?.toJSON() {
                save(service: appleSignUserInfoKey, data: appleSignUserInfo)
            }else {
                delete(service: appleSignUserInfoKey)
            }
        }
    }
    private static let appleSignUserInfoKey = "\(bundleId).appleSignUserInfo"*/


}
