//
//  LJExtension+UIView.swift
//  FairfieldUser
//
//  Created by panjinyong on 2020/12/25.
//

import Foundation
import UIKit

extension UIView: LJExtensionCompatible {}

extension LJExtension where Base: UIView {
    
    /// 添加阴影
    func addShadow(opacity: Float = 1,
                   radius: CGFloat = 5,
                   offset: CGSize = CGSize(width: 0, height: 1),
                   color: UIColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.15)) {
//        if let rect = base.layer.shadowPath?.boundingBox, rect == base.bounds {
//            return
//        }
        base.layoutIfNeeded()
        base.layer.shadowOffset = offset
        base.layer.shadowColor = color.cgColor
        base.layer.shadowOpacity = opacity
        base.layer.shadowRadius = radius
        let path = UIBezierPath.init(rect: base.bounds)
        base.layer.shadowPath = path.cgPath
    }
    
    func addBgViewShadow() {
        base.lj.addShadow(opacity: 1, radius: 18, offset: .init(width: 0, height: 6), color: LJColor.hex(0xDEE2E5, 0.32))
    }
    
    /// 切任意圆角
    func clipsTopCornerRadius(roundedRect rect: CGRect? = nil, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        let maskPath = UIBezierPath.init(roundedRect: rect ?? base.bounds, byRoundingCorners: corners, cornerRadii: cornerRadii)
        let maskLayer = CAShapeLayer.init()
        maskLayer.frame = base.bounds
        maskLayer.path = maskPath.cgPath
        base.layer.mask = maskLayer
    }

    
}
