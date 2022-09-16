//
//  LJExtension+String.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/15.
//

import Foundation
import CommonCrypto

extension String: LJExtensionCompatible {}

extension LJExtension where Base == String {
   
    /// 是否有效的email
    var isValidEmail: Bool {
        get {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            return NSPredicate.init(format: "SELF MATCHES %@", emailRegex).evaluate(with: base)
        }
    }
    
    
    /// 密码有效性（8~16位字母+数字）
    var passwordValidity: PasswordValidity {
        get {
            if base.count < 8 {
                return .invalid(.length)
            }else {
                return .valid
            }
            
//            let pred = NSPredicate.init(format: "SELF MATCHES %@", "^(?![0-9]+$)(?![a-zA-Z]+$)[a-zA-Z0-9]{8,16}")
//            if pred.evaluate(with: base) {
//                return .valid
//            }else {
//                return .invalid(.content)
//            }
        }
    }
    
    /// 密码有效性
    enum PasswordValidity: Equatable {
       
        /// 有效
        case valid
      
        /// 无效
        case invalid(PasswordError)
        
        /// 密码错误类型
        enum PasswordError {
            /// 长度不对（8--16位）
            case length
            /// 内容不符合（包含数字、字母）
//            case content
        }
    }
    
    /// MD5
    /*var toMd5String: String {
        get {
            let cStrl = base.cString(using: String.Encoding.utf8)
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            CC_MD5(cStrl, CC_LONG(strlen(cStrl!)), buffer)
            var md5String = ""
            for idx in 0...15 {
                let obcStrl = String.init(format: "%02x", buffer[idx]);
                md5String.append(obcStrl);
            }
            free(buffer)
            return md5String
        }
    }*/
    
    
}
