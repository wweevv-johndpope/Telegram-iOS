//
//  WEVDiscoverSearchView.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

class WEVDiscoverSearchView: UITableView {
    
    public var presentationData: PresentationData? = nil {
        didSet {
            updateSearchViewThemeColor()
        }
    }
    
    func updateSearchViewThemeColor() {
        guard let presentationData = self.presentationData else {
            return
        }
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    /// 选中某个关键字
    public var didSelected: ((String)->())? = nil
    
    /// 选中某个关键字
    public var deleteRecord: ((String)->())? = nil
    
    /// 是否显示记录列表，否则显示搜索列表
    public var isShowRecordList = true {
        didSet {
            if oldValue != isShowRecordList {
                reloadData()
            }
        }
    }
    
    /// 调用接口匹配的关键字列表
    public var searchNameArray: [String] = [] {
        didSet {
            reloadData()
        }
    }
    
    /// 搜索记录列表
    public var recordArray: [String] = [] {
        didSet {
            reloadData()
        }
    }
    
    /// 该显示的数据
    private var dataArray: [String] {
        get {
            isShowRecordList ? recordArray : searchNameArray
        }
    }
    
    required init() {
        super.init(frame: .zero, style: .plain)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    private func initView() {
        delegate = self
        dataSource = self
        separatorStyle = .none
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = UITableView.automaticDimension
        estimatedSectionHeaderHeight = 0
        estimatedSectionFooterHeight = 0
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    }
}

extension WEVDiscoverSearchView: UITableViewDelegate {
    
}


extension WEVDiscoverSearchView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        let title = dataArray[indexPath.row]
        cell.title = title
        //check theme color
        if let presentationData = self.presentationData  {
            cell.presentationData = presentationData
        }
        cell.style = isShowRecordList ? .record : .keyword
        cell.deleteAction = {[weak self] record in
            guard let self = self else {return}
            self.deleteRecord?(record)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let title = dataArray[indexPath.row]
        didSelected?(title)
    }
}

class TableViewCell: LJBaseTableViewCell {
    
    /// 样式
    enum Style {
        /// 记录
        case record
        /// 关联词
        case keyword
    }
    
    public var presentationData: PresentationData? = nil {
        didSet {
            updateTitleThemeColor()
        }
    }
    
    func updateTitleThemeColor() {
        guard let presentationData = self.presentationData else {
            return
        }
        self.titleLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
    }
    /// 样式
    public var style: Style = .record {
        didSet {
            udpateStyleImageView()
        }
    }
    
    /// 内容
    public var title: String? = nil {
        didSet {
            titleLabel.text = title
        }
    }
    
    /// 删除按键
    public var deleteAction: ((String) -> ())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    
    /// 图片
    private let imgView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    /// 标题
    private let titleLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(14), textColor: LJColor.black)
        return label
    }()
    
    /// 删除按键
    private lazy var deleteButton: UIButton = {
        let view = UIButton.init(type: .custom)
        view.setImage(UIImage.init(named: "discover_search_record_delete"), for: .normal)
        view.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        return view
    }()
    
    private func initView() {
        contentView.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(29)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize.init(width: 30, height: 30))
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(61)
            make.right.equalTo(deleteButton.snp.left).offset(-10)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(48)
        }
        
        udpateStyleImageView()
    }
    
    private func udpateStyleImageView() {
        imgView.image = UIImage.init(named: style == .keyword ? "discover_search" : "discover_search_record")
        deleteButton.isHidden = style == .keyword
    }
    
    @objc private func deleteButtonAction() {
        guard let title = title else { return }
        deleteAction?(title)
    }
}

import TelegramPresentationData
class WEVDiscoverSearchBar: UIView {
    /// 样式
    enum Style {
        /// 正在搜索
        case searching
        /// 搜索完成
        case searchCompleted
        /// 非搜索
        case normal
    }
    
    /// 样式
    var style: Style = .normal {
        didSet {
            updateStyleView()
        }
    }
    
    public var presentationData: PresentationData? = nil {
        didSet {
            updateSearchbarThemeColor()
        }
    }
    
    func updateSearchbarThemeColor() {
        guard let presentationData = self.presentationData else {
            return
        }
        textField.backgroundColor = presentationData.theme.chatList.backgroundColor
        textField.textColor = presentationData.theme.list.itemPrimaryTextColor
        textField.tintColor = presentationData.theme.rootController.tabBar.selectedIconColor
        cancelSearchButton.setTitleColor(presentationData.theme.rootController.tabBar.selectedIconColor, for: .normal)
    }
    /// 筛选按键
    public var filterAction: (()->())? = nil
    
    /// 取消搜索按键
    public var cancelAction: (()->())? = nil
    
    /// 输入内容改变
    public var textDidChange: ((String)->())? = nil
    
    /// 开始编辑
    public var didBeginEditing: (()->())? = nil
    
    /// 结束编辑
    public var didEndEditing: (()->())? = nil
    
    /// 点击了搜索
    public var searchAction: ((String)->())? = nil
    
    /// 输入框的文本
    public var text: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
            lastSendText = newValue
        }
    }
    
    /// 上一次发出去的字符， 用来对比最新的字符串，有变化才触发textDidChange
    private var lastSendText: String?
    
    /// 结合lastSendText使用，有变化才触发textDidChange
    private var lastSendTextDate: Date?
    
    /// 输入文本发送延迟时间
    private let sendTextTimeinterval: TimeInterval = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    
    public lazy var textField: UITextField = {
        let textField = UITextField()
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 40))
        let leftImageView = UIImageView(image: UIImage.init(named: "discover_search"))
        leftImageView.frame = CGRect(x: 14, y: 11, width: 17, height: 17)
        leftView.addSubview(leftImageView)
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.backgroundColor = LJColor.hex(0xF3F3F5)
        textField.attributedPlaceholder = NSAttributedString.init(string: "Search...", attributes: [NSAttributedString.Key.font : LJFont.regular(14), .foregroundColor: LJColor.gray])
        textField.font = LJFont.regular(14)
        textField.textColor = LJColor.black
        textField.addTarget(self, action: #selector(textFieldDidChanged(textField:)), for: .editingChanged)
        textField.delegate = self
        textField.returnKeyType = .search
        //let clearButton = UIButton.init(type: .custom)
        //clearButton.setImage(UIImage.init(named: "discover_search_text_clear"), for: .normal)
        //clearButton.addTarget(self, action: #selector(clearButtonAction), for: .touchUpInside)
        //clearButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        //textField.rightView = clearButton
        //textField.rightViewMode = .whileEditing
        return textField
    }()
    
    /// 筛选按键
    private lazy var filterButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setImage(UIImage.init(named: "discover_search_filter"), for: .normal)
        button.addTarget(self, action: #selector(filterButtonAction), for: .touchUpInside)
        return button
    }()
    
    /// 取消搜索按键
    private lazy var cancelSearchButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = LJFont.regular(14)
        button.setTitleColor(LJColor.black, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        return button
    }()
    
    private func initView() {
        /*addSubview(filterButton)
        filterButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.centerY.equalToSuperview()
        }*/
        
        addSubview(cancelSearchButton)
        cancelSearchButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 60, height: 40))
            make.centerY.equalToSuperview()
        }
        
        addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    
    private func updateThemeColor() {
        //cancelSearchButton
        //textField
    }
    
    private func updateStyleView() {
        switch style {
        case .normal:
            cancelSearchButton.isHidden = true
            filterButton.isHidden = false
            textField.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-10)
            }
        case .searching, .searchCompleted:
            cancelSearchButton.isHidden = false
            filterButton.isHidden = true
            textField.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-75)
            }
        }
    }
    
    //MARK: Action
    
    /// 筛选按键
    @objc private func filterButtonAction() {
        filterAction?()
    }
    
    /// 取消搜索按键
    @objc private func cancelButtonAction() {
        textField.resignFirstResponder()
        cancelAction?()
    }
    
    /// 输入文本变化
    @objc private func textFieldDidChanged(textField: UITextField) {
        var text = textField.text ?? ""
        if text.count > 50 {
            text = String(text.prefix(50))
            textField.text = text
        }
        
        chekText()
        
    }
    
    /// 检查是否该发出文本，根据上一次发出时间与内容判断
    private func chekText() {
        let text = textField.text ?? ""
        
        guard let lastSendTextDate = lastSendTextDate,
              let lastSendText = lastSendText else {
            self.lastSendTextDate = Date()
            self.lastSendText = text
            textDidChange?(text)
            return
        }
        
        if text != lastSendText {
            let time = lastSendTextDate.timeIntervalSinceNow
            if time < -sendTextTimeinterval {
                self.lastSendTextDate = Date()
                self.lastSendText = text
                textDidChange?(text)
            }else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + sendTextTimeinterval + time) {
                    self.chekText()
                }
            }
        }
        
    }
    
}


//MARK: UITextFieldDelegate
extension WEVDiscoverSearchBar: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didEndEditing?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchAction?(textField.text!)
        return false
    }
}
