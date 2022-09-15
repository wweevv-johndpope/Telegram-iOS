//
//  LJBaseViewController.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

class LJBaseViewController: UIViewController {
    
    /// 是否第一个控制器，用于控制返回手势
    public var isNavRootVC = false
    
    /// 左边导航按键
    public var leftButton: UIButton? = nil
    
    /// 右边导航按键
    public var rightButton: UIButton? = nil
    
    public var leftBlock: (() -> ())? = nil
    
    public var rightBlock: (() -> ())? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isNavRootVC {
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        // Do any additional setup after loading the view.
    }
    
    //MARK: UI
    private func initView() {
        view.backgroundColor = .white
        setBackItem(isHidden: false)
        if #available(iOS 11.0, *) {
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        leftBlock = {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    /// 返回按键
    public func setBackItem(isHidden: Bool) {
        if isHidden {
            leftButton?.isHidden = true
        }else {
            setNavBarButtonItem(isLeft: true, image: UIImage.init(named: "nav_item_back"), title: nil)
        }
    }
    
    /// 左右导航按键
    public func setNavBarButtonItem(isLeft: Bool, image: UIImage? = nil, title: String? = nil) {
        let button = UIButton.init(type: UIButton.ButtonType.custom)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        button.setImage(image, for: UIControl.State.normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(LJColor.black, for: .normal)
        button.titleLabel?.font = LJFont.regular(16)
        if let title = title {
            let width = (title as NSString).boundingRect(with: CGSize(width: 1000, height: 30), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : LJFont.regular(16)], context: nil).width
            button.frame.size.width = width + 30
        }
        let buttonItem = UIBarButtonItem.init(customView: button)
        if isLeft {
            button.addTarget(self, action: #selector(leftButtonAction), for: .touchUpInside)
            navigationItem.leftBarButtonItem = buttonItem
            leftButton = button
        }else {
            button.addTarget(self, action: #selector(rightButtonAction), for: .touchUpInside)
            navigationItem.rightBarButtonItem = buttonItem
            rightButton = button
        }
    }
    
    
    /// 左边按键事件
    @objc private func leftButtonAction() {
        if let leftBlock = leftBlock {
            leftBlock()
        }else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    /// 右边边按键事件
    @objc private func rightButtonAction() {
        rightBlock?()
    }
}

//MARK: 返回手势
extension LJBaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            if (self.navigationController?.viewControllers.count == 1){
                return false
            }else{
                return true
            }
        }
        return true
    }
}
