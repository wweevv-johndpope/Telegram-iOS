//
//  LJHelper.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit


struct API {
    static let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ7XCJ1c2VySWRcIjpcInVzX2M1TTN6MER4OHZcIixcImVtYWlsXCI6XCJ3d2VldnYxQGdtYWlsLmNvbVwifSIsImlhdCI6MTY2MzI0MTQ2N30.GEYCOKk5xbsMX0lk0q0EE6nRl4KiHRaFzYS2i2M3PSuATx82i_giIu-UE3wJq3owPTxCQD47q67V92SL1Q3q5A"
}
/// 字体
struct LJFont {
    
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Rubik-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }

}

struct LJColor {
    
    static let main = Self.hex(0x128A84)
    
    static let black = Self.hex(0x353535)
   
    static let gray = Self.hex(0x868686)
    
    /// 分割线的灰色
    static let lineGray = Self.hex(0xE6E6E6)

    /// 灰色背景
    static let grayBg = Self.hex(0xE6E6E6)

    static func hex(_ hex: UInt, _ alpha: CGFloat = 1) -> UIColor {
        UIColor.lj.hex(hex, alpha)
    }
}

struct LJScreen {
    //屏幕大小
    static let height: CGFloat = UIScreen.main.bounds.size.height
    static let width: CGFloat = UIScreen.main.bounds.size.width
    
    //iPhoneX的比例
    static let scaleWidthOfIX = UIScreen.main.bounds.size.width / 375.0
    static let scaleHeightOfIX = UIScreen.main.bounds.size.height / 812.0
    static let scaleHeightLessOfIX = scaleHeightOfIX > 1 ? 1 : scaleHeightOfIX
    static let scaleWidthLessOfIX = scaleWidthOfIX > 1 ? 1 : scaleWidthOfIX


    // iphoneX
    static let navigationBarHeight: CGFloat =  isiPhoneXMore() ? 88.0 : 64.0
    static let safeAreaBottomHeight: CGFloat =  isiPhoneXMore() ? 34.0 : 0
    static let statusBarHeight: CGFloat = isiPhoneXMore() ? 44.0 : 20.0
    static let tabBarHeight: CGFloat = isiPhoneXMore() ? 83.0 : 49.0

    // iphoneX
    static func isiPhoneXMore() -> Bool {
        let isMore:Bool = true
//        if #available(iOS 11.0, *) {
//            isMore = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > CGFloat(0)
//        }
        return isMore
    }

}

