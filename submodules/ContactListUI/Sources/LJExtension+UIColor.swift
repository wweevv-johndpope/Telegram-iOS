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



extension LJExtension where Base == UIButton {
  
    //MARK: 此项目的便捷UIButton

    @discardableResult
    func configure(font: UIFont? = nil,
                   titleColor: UIColor? = nil,
                   backgroundColor: UIColor? = nil,
                   title: String? = nil) -> UIButton {
        if let title = title {
            base.setTitle(title, for: .normal)
        }
        if let font = font {
            base.titleLabel?.font = font
        }
        if let titleColor = titleColor {
            base.setTitleColor(titleColor, for: .normal)
        }
        if let backgroundColor = backgroundColor {
            base.backgroundColor = backgroundColor
        }
        base.layer.cornerRadius = 4
        return base
    }
    
    static func configure(font: UIFont? = nil,
                          titleColor: UIColor? = nil,
                          backgroundColor: UIColor? = nil,
                          title: String? = nil) -> Base {
        let button = UIButton.init(type: .custom)
        button.lj.configure(font: font, titleColor: titleColor, backgroundColor: backgroundColor, title: title)
        
        return button
        
    }
    
    static func configure(title: String?,
                          fontSize: CGFloat = 14) -> Base {
        Self.configure(font: LJFont.medium(fontSize), titleColor: .white, backgroundColor: LJColor.main, title: title)
    }


}
