//
//  LJExtension+UIViewController.swift
//  Peach
//
//  Created by panjinyong on 2021/6/16.
//  Copyright © 2021 techne. All rights reserved.
//

import Foundation
extension UIViewController: LJExtensionCompatible {}

extension LJExtension where Base: UIViewController {
    
    /// 当前显示的视图控制器
    static var currentVC: UIViewController? {
        get {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {return nil}
            func topVC(of rootVC: UIViewController) -> UIViewController {
                if let presentedViewController = rootVC.presentedViewController, !presentedViewController.isBeingDismissed {
                    return topVC(of: presentedViewController)
                }else if let vc = (rootVC as? UITabBarController)?.selectedViewController {
                    return topVC(of: vc)
                }else if let vc = (rootVC as? UINavigationController)?.viewControllers.last {
                    return topVC(of: vc)
                }
                return rootVC
            }
            return topVC(of: rootVC)
        }
    }
}
