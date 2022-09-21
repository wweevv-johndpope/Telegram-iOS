//
//  LJExtension+UIColor.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//


import UIKit

extension UIColor: LJExtensionCompatible {}

extension LJExtension where Base == UIColor {

    static func hex(_ hex: UInt, _ alpha: CGFloat = 1) -> UIColor {
        Base.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0, green: CGFloat((hex & 0xFF00) >> 8) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: alpha)
    }
    
    /// 根据颜色生成图片
    var image: UIImage {
        get {
            let rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
            UIGraphicsBeginImageContext(rect.size)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(base.cgColor)
            context?.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
    }    

}

