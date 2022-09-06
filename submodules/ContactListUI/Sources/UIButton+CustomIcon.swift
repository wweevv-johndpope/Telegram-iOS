//
//  UIButton+CustomIcon.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/13.
//

import Foundation

extension LJExtension where Base == UIButton {
    
    /// 图片在左边
    /// - Parameter spacing: 标题与图片的间隔
    func setIconInLeft(_ spacing: CGFloat) {
        base.titleEdgeInsets = .init(top: 0, left: spacing, bottom: 0, right: 0)
        base.imageEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: spacing)
    }
    
    /// 图片在右边
    /// - Parameter spacing: 标题与图片的间隔
    func setIconInRight(_ spacing: CGFloat) {
        let imageWidth = base.imageView?.frame.width ?? 0
        let titleWidth = base.titleLabel?.frame.width ?? 0
        base.titleEdgeInsets =
            .init(top: 0,
                  left: -(imageWidth + spacing / 2),
                  bottom: 0,
                  right: (imageWidth + spacing / 2))
        
        base.imageEdgeInsets =
            .init(top: 0,
                  left: (titleWidth + spacing / 2),
                  bottom: 0,
                  right: -(titleWidth + spacing / 2))
    }
    
    /// 图片在上面
    /// - Parameter spacing: 标题与图片的间隔
    func setIconInTop(_ spacing: CGFloat) {
        let imageWidth = base.imageView?.frame.width ?? 0
        let imageHeight = base.imageView?.frame.height ?? 0
        let titleWidth = base.titleLabel?.frame.width ?? 0
        let titleHeight = base.titleLabel?.frame.height ?? 0
        let totalHeight = (imageHeight + titleHeight) / 2
        
        base.titleEdgeInsets =
            .init(top: (totalHeight - titleHeight / 2 + spacing / 2),
                  left: -(imageWidth / 2),
                  bottom: -(totalHeight - titleHeight / 2  + spacing / 2),
                  right: (imageWidth / 2))
        base.imageEdgeInsets =
            .init(top: -(totalHeight - imageHeight / 2 + spacing / 2),
                  left: (titleWidth / 2),
                  bottom: (totalHeight - imageHeight / 2 + spacing / 2),
                  right: -(titleWidth / 2))
    }

    
    /// 图片在下面
    /// - Parameter spacing: 标题与图片的间隔
    func setIconInBottom(_ spacing: CGFloat) {
        let imageWidth = base.imageView?.frame.width ?? 0
        let imageHeight = base.imageView?.frame.height ?? 0
        let titleWidth = base.titleLabel?.frame.width ?? 0
        let titleHeight = base.titleLabel?.frame.height ?? 0
        let totalHeight = (imageHeight + titleHeight) / 2
        
        base.titleEdgeInsets =
            .init(top: (totalHeight - titleHeight / 2 + spacing / 2),
                  left: -(imageWidth / 2),
                  bottom: (totalHeight / 2  + spacing / 2),
                  right: (imageWidth / 2))
        base.imageEdgeInsets =
            .init(top: (totalHeight - imageHeight / 2 + spacing / 2),
                  left: (titleWidth / 2),
                  bottom: -(imageHeight / 2 + spacing / 2),
                  right: -(titleWidth / 2))
    }

}


