//
//  LJExtension+Double.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/29.
//

import Foundation

extension Double: LJExtensionCompatible {}

extension LJExtension where Base == Double {
    /// 四舍五入
    /// - Parameter count: 默认保留2位小数
    func roundString(_ count: Int = 2) -> String {
        let value = pow(10, Double(count))
        return String.init(format: "%.\(count)f", round(base * value) / value)
    }
    
    /// 价格字符串
    var priceString: String {
        get {
            var prefix = "$"
            var number = base
            if base < 0 {
                prefix = "-$"
                number = -number
            }
            return prefix + number.lj.priceFormatString
        }
    }
    
    /// 价格字符串
    var priceFormatString: String {
        get {
            let numberFormatter = NumberFormatter()
            numberFormatter.positiveFormat = "###,##0.00;"
            let number = base
            return (numberFormatter.string(from: NSNumber.init(value: number)) ?? "")
        }
    }
    
    /// 积分(显示整数或一位小数)
    var pointFormatString: String {
        get {
            let numberFormatter = NumberFormatter()
            numberFormatter.positiveFormat = "###,###.#;"
            let number = base
            return (numberFormatter.string(from: NSNumber.init(value: number)) ?? "")
        }
    }

    
}
