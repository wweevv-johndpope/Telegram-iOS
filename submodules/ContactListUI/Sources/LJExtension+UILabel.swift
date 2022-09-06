//
//  LJExtension+UILabel.swift
//  FairfieldUser
//
//  Created by panjinyong on 2020/12/23.
//

import UIKit

//extension UILabel: LJExtensionCompatible {}

extension LJExtension where Base == UILabel {
  
    //MARK: 此项目的便捷Label

    @discardableResult
    func configure(font: UIFont? = nil,
                   textColor: UIColor? = nil,
                   text: String? = nil) -> UILabel {
        if let text = text {
            base.text = text
        }
        if let font = font {
            base.font = font
        }
        if let textColor = textColor {
            base.textColor = textColor
        }
        return base
    }
    
    static func configure(font: UIFont = LJFont.regular(14),
                          textColor: UIColor = LJColor.black,
                          text: String? = nil) -> Base {
       
        Base().lj.configure(font: font, textColor: textColor, text: text)

    }
    
    static func configure(fontSize: CGFloat = 14,
                          textColor: UIColor = LJColor.black,
                          text: String? = nil) -> Base {
        Self.configure(font: LJFont.regular(fontSize), textColor: textColor, text: text)
    }
    
    /// 设置带行间距文本
    /// - Parameters:
    ///   - text: 文本
    ///   - lineSpacing: 行间距
    func setLineSpacingText(_ text: String, lineSpacing: CGFloat = 5) {
        base.text = text
        setLineSpacing(lineSpacing)
    }
    
    /// 设置行间距，需要在设置文本之后调用
    /// - Parameter lineSpacing: 行间距
    func setLineSpacing(_ lineSpacing: CGFloat = 5) {
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = base.textAlignment
        paragraphStyle.lineBreakMode = .byTruncatingTail
        var attributedText: NSMutableAttributedString
        
        if let oldAttributedText = base.attributedText {
            attributedText = NSMutableAttributedString.init(attributedString: oldAttributedText)
        }else if let text = base.text {
            attributedText = NSMutableAttributedString.init(string: text)
        }else {
            return
        }
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: attributedText.string.count))
        base.attributedText = attributedText
    }

}


