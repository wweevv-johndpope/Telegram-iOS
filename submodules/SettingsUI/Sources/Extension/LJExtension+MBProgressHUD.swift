//
//  LJExtension+MBProgressHUD.swift
//  Wweevv
//
//  Created by panjinyong on 2021/1/15.
//

import Foundation
import MBProgressHUD
import UIKit

extension LJExtension where Base == MBProgressHUD {
    @discardableResult
    static func showHint(_ message: String) -> MBProgressHUD? {
        guard let view = UIWindow.key else {return nil}
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.detailsLabel.text = message
        hud.detailsLabel.font = UIFont.systemFont(ofSize: 15)
        hud.margin = 10
        hud.isUserInteractionEnabled = false
        hud.mode = .customView
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 2.0)
        return hud
    }

}
