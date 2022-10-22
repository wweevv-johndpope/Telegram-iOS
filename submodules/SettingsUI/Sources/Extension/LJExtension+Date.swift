//
//  LJExtension+Date.swift
//  FairfieldUser
//
//  Created by panjinyong on 2021/2/20.
//

import Foundation
import CommonCrypto

extension Date: LJExtensionCompatible {}

extension LJExtension where Base == Date {
        
    /// 时间戳转字符串
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - format: 格式
    ///   - isMillisecond: 时间戳个位数是否表示毫秒
    /// - Returns: 时间字符串
    static func string(timestamp: String, format: String, isMillisecond: Bool = false) -> String {
        var time = Double(timestamp) ?? 0
        if isMillisecond {
            time = time / 1000
        }
        let date = Date.init(timeIntervalSince1970: time)
        let matter = DateFormatter.init()
        matter.dateFormat = format
        matter.amSymbol = "AM"
        matter.pmSymbol = "PM"
        return matter.string(from: date)
    }
    
    func string(format: String) -> String {
        let matter = DateFormatter.init()
        matter.dateFormat = format
        matter.amSymbol = "AM"
        matter.pmSymbol = "PM"
        return matter.string(from: base)
    }
    
    init?(dateString: String, format: String) {
        let matter = DateFormatter.init()
        matter.dateFormat = format
        guard let date = matter.date(from: dateString) else { return nil }
        self.base = date
    }

    /// 年龄，作为某个出生日期距离现在的年龄
    var age: Double {
        get {
            let current = Date()
            let birthday = base
            
            let currentDateComponents = Calendar.current.dateComponents(in: .current, from: current)
            let birthdayDateComponents = Calendar.current.dateComponents(in: .current, from: birthday)
            guard let currentYear = currentDateComponents.year,
                  let currentMonth = currentDateComponents.month,
                  let currentDay = currentDateComponents.day,
                  let birthdayYear = birthdayDateComponents.year,
                  let birthdayMonth = birthdayDateComponents.month,
                  let birthdayDay = birthdayDateComponents.day
            else { return current.timeIntervalSince(birthday) / (365 * 24 * 3600)}
            
            var age: Double = 0
            
            /// 是否已过今年生日
            var isPassCurrentYearBirthday = false
            
            if currentMonth == birthdayMonth { // 同月
                if currentDay == birthdayDay { // 刚好生日
                    isPassCurrentYearBirthday = true
                }else if currentDay < birthdayDay { // 没过生日
                    isPassCurrentYearBirthday = false
                }else if currentDay > birthdayDay { // 已过生日
                    isPassCurrentYearBirthday = true
                }
            }else if currentMonth < birthdayMonth { // 没过生日
                isPassCurrentYearBirthday = false
            }else if currentMonth > birthdayMonth { // 已过生日
                isPassCurrentYearBirthday = true
            }
            
            /// 上一个生日的年份
            var lastBirthdayYear = 0
            
            if isPassCurrentYearBirthday {
                // 已过今年生日
                age += Double(currentYear - birthdayYear)
                lastBirthdayYear = currentYear
            }else {
                // 未过今年生日
                age += Double(currentYear - birthdayYear - 1)
                lastBirthdayYear = currentYear - 1
            }
            
            guard
                let lastBirthdayDate = DateComponents.init(calendar: .current, year: lastBirthdayYear, month: birthdayMonth, day: birthdayDay).date,
                  let nextBirthdayDate = DateComponents.init(calendar: .current, year: lastBirthdayYear + 1, month: birthdayMonth, day: birthdayDay).date
            else {return current.timeIntervalSince(birthday) / (365 * 24 * 3600)}
            age += current.timeIntervalSince(lastBirthdayDate) / nextBirthdayDate.timeIntervalSince(lastBirthdayDate)
            return age
        }
    }
  
}
