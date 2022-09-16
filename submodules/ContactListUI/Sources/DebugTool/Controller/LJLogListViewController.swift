//
//  LJLogListViewController.swift
//  FairfieldUser
//
//  Created by panjinyong on 2021/7/9.
//

import UIKit

class LJLogListViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    /// 选中某日志回调
    public var didSelectedLog: ((LJDebugLogModel) -> ())?
    
    /// 日志列表
    private var logArray: [LJDebugLogModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        logArray = LJDebugTool.share.historyLogArray
        initView()
    }
    
    private func initView() {
        view.addSubview(tableView)
        tableView.frame = CGRect(x: 0, y: LJScreen.navigationBarHeight, width: LJScreen.width, height: LJScreen.height - LJScreen.navigationBarHeight - LJScreen.safeAreaBottomHeight)
        let removeItem = UIBarButtonItem.init(title: "删除所有", style: .done, target: self, action: #selector(removeAction))
        let shareItem = UIBarButtonItem.init(title: "分享", style: .plain, target: self, action: #selector(shareAction))
        navigationItem.setRightBarButtonItems([shareItem, removeItem], animated: true)
    }
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.rowHeight = 60
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        return view
    }()
    
    //MARK: - Action

    @objc private func removeAction() {
        guard !self.logArray.isEmpty else {return}
        let alert = UIAlertController.init(title: "确定删除吗？", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "确定", style: .destructive, handler: { (_) in
            LJDebugTool.share.clearAllLog()
            self.logArray.removeAll()
            self.tableView.reloadData()
        }))
        alert.addAction(.init(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func shareAction() {
        guard LJDebugTool.share.historyLogArray.isEmpty else {return}
        let allLog = LJDebugTool.share.historyLogArray.map{"\n\n\($0.createDate)+++++++++++++++++++++++++++++++++++++\n\($0.text)"}.joined(separator: "\n\n\n")
        
        let url = URL.init(fileURLWithPath: "\(NSTemporaryDirectory())/LJAllLog.txt")
        do {
            try allLog.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
        let activity = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
        present(activity, animated: true, completion: nil)
    }

    
}

//MARK: - TableViewDelegate
extension LJLogListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        cell.log = logArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectedLog?(logArray[indexPath.row])
    }
}


//MARK: - Cell

extension LJLogListViewController {
    class TableViewCell: UITableViewCell {
        var log: LJDebugLogModel? {
            didSet {
                updateView()
            }
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initView()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        /// 标题
        private lazy var titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = .black
            return view
        }()
        
        private func initView() {
            contentView.addSubview(titleLabel)
        }
        override func layoutSubviews() {
            self.titleLabel.frame = CGRect(x: 20, y: 0, width: frame.width - 40, height: frame.height)
            super.layoutSubviews()
        }
        
        private func updateView() {
            guard let log = log else {
                titleLabel.text = nil
                return
            }
            titleLabel.text = "\(log.createDate)"
            titleLabel.textColor = log.isCrash ? .red : .black
        }
    }
}

