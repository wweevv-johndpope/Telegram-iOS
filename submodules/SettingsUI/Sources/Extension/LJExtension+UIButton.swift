//
//  LJExtension+UIButton.swift
//  FairfieldUser
//
//  Created by panjinyong on 2020/12/23.
//

import UIKit

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

