//
//  LJExtension+Notification.swift
//  Wweevv
//
//  Created by panjinyong on 2020/12/22.
//

import Foundation
extension Notification.Name: LJExtensionCompatible {}
extension LJExtension where Base == Notification.Name {
    /// 包名
    private static let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    
    /// 用户信息更新
    static let didUpdatedUserInfo = Notification.Name.init("\(bundleId).didUpdatedUserInfo")
    
    /// 关联了新账号
    static let didConnectedAccount = Notification.Name.init("\(bundleId).didConnectedAccount")

    /// 取消关联了某账号
    static let didDisconnectedAccount = Notification.Name.init("\(bundleId).didDisconnectedAccount")

    /// 订阅了某主播
    static let didSubscribeAnchor = Notification.Name.init("\(bundleId).didSubscribeAnchor")

    /// 取消订阅某主播
    static let didUnsubscribeAnchor = Notification.Name.init("\(bundleId).didUnsubscribeAnchor")

    
}
