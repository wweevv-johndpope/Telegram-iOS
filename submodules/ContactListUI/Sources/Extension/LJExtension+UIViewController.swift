//
//  LJExtension+UIViewController.swift
//  Peach
//
//  Created by panjinyong on 2021/6/16.
//  Copyright © 2021 techne. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController: LJExtensionCompatible {}

extension LJExtension where Base: UIViewController {
    
    /// 当前显示的视图控制器
    static var currentVC: UIViewController? {
        get {
            //guard let window = UIWindow.key else {return nil}
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
            return nil
        }
    }
}
extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
