//
//  LJLogViewController.swift
//  FairfieldUser
//
//  Created by panjinyong on 2021/7/9.
//

import UIKit

class LJLogViewController: UIViewController {
    
    /// 当前显示的日志
    private var log: LJDebugLogModel?
    
    deinit {
        LJDebugTool.share.removeCurrentLogListener(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log = LJDebugTool.share.currentLog
        initView()
        updateLogView()
        LJDebugTool.share.addCurrentLogListener(self) { (log) in
            guard self.log?.logId == log.logId else {return}
            self.log = log
            self.updateLogView()
        }
    }
    
    private func initView() {
        view.addSubview(logTextView)
        logTextView.frame = CGRect(x: 0, y: LJScreen.statusBarHeight, width: LJScreen.width, height: LJScreen.height - LJScreen.statusBarHeight)
                
        view.addSubview(currentButton)
        currentButton.frame = CGRect(x: LJScreen.width - 200, y: LJScreen.statusBarHeight, width: 80, height: 30)
       
        view.addSubview(historyButton)
        historyButton.frame = CGRect(x: LJScreen.width - 100, y: LJScreen.statusBarHeight, width: 80, height: 30)

    }
    
    private func updateLogView() {
        logTextView.text = log?.text
    }
    
    /// 日志文本
    private lazy var logTextView: UITextView = {
        let view = UITextView()
//        view.isEditable = false
        return view
    }()

    /// 历史记录
    private lazy var historyButton: UIButton = {
        let view = UIButton.init(type: .custom)
        view.setTitle("历史记录", for: .normal)
        view.setTitleColor(.cyan, for: .normal)
        view.addTarget(self, action: #selector(historyButtonAction), for: .touchUpInside)
        return view
    }()
    
    /// 当前日志
    private lazy var currentButton: UIButton = {
        let view = UIButton.init(type: .custom)
        view.setTitle("当前日志", for: .normal)
        view.setTitleColor(.cyan, for: .normal)
        view.addTarget(self, action: #selector(currentButtonAction), for: .touchUpInside)
        return view
    }()
    
    @objc private func historyButtonAction() {
        let vc = LJLogListViewController()
        vc.didSelectedLog = {[weak self] log in
            guard let self = self else {return}
            self.log = log
            self.updateLogView()
            self.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func currentButtonAction() {
        self.log = LJDebugTool.share.currentLog
        updateLogView()
    }
    


}
