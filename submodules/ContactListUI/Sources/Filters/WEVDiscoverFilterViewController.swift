//
//  WEVDiscoverFilterViewController.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

class WEVDiscoverFilterViewController: LJBaseViewController {
    var didSelected: (([WEVChannel])->())? = nil
    
    /// 频道列表
    private let channelArray: [WEVChannel]
    
    /// 选中的频道数组
    public var selectedArray: [WEVChannel] = []
    
    required init(allChannel: [WEVChannel], selectedArray: [WEVChannel]) {
        self.channelArray = allChannel
        self.selectedArray = selectedArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.channelArray = []
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    /// collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = (LJScreen.width - 30 * 2 - 15) / 2
        layout.itemSize = CGSize(width: width, height: 79 * width / 150)
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        view.register(WEVDiscoverFilterCollectionViewCell.self, forCellWithReuseIdentifier: "WEVDiscoverFilterCollectionViewCell")
        return view
    }()
    
    /// 确认按键
    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton.lj.configure(title: "Confirm")
        confirmButton.addTarget(self, action: #selector(confirmButtonAction), for: .touchUpInside)
        return confirmButton
    }()
    
    private func initView() {
        
        /// 关闭按键
        let closeButton = UIButton.init(type: .custom)
        closeButton.setImage(UIImage.init(named: "discover_channel_filter_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 25, height: 25))
        }
        
        /// 标题
        let titleLabel = UILabel.lj.configure(font: LJFont.medium(20), textColor: LJColor.main, text: "Watch from")
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.top.equalToSuperview().offset(126)
        }
        
        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-10 - LJScreen.safeAreaBottomHeight)
        }
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
    }
    
    //MARK: Action

    @objc private func closeButtonAction() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func confirmButtonAction() {
        guard !selectedArray.isEmpty else {return}
        dismiss(animated: true) {
            self.didSelected?(self.selectedArray)
        }
    }
}

//MARK: UICollectionViewDelegateFlowLayout
extension WEVDiscoverFilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top: 0, left: 30, bottom: 0, right: 30)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        15
    }
}

extension WEVDiscoverFilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WEVDiscoverFilterCollectionViewCell", for: indexPath) as! WEVDiscoverFilterCollectionViewCell
        if indexPath.row == 0 {
            cell.data = .init(style: .all, isSelected: selectedArray.count == channelArray.count)
        }else {
            let channel = channelArray[indexPath.row - 1]
            cell.data = .init(style: .channel(channel), isSelected: selectedArray.contains(channel))
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if selectedArray.count != channelArray.count {
                selectedArray = channelArray
            }else {
                selectedArray = []
            }
        }else {
            let channel = channelArray[indexPath.row - 1]
            if let index = selectedArray.firstIndex(where: {$0 == channel}) {
                selectedArray.remove(at: index)
            }else {
                selectedArray.append(channel)
            }
        }
        collectionView.reloadData()
        confirmButton.alpha = selectedArray.isEmpty ? 0.5 : 1
    }
    
}

//MARK:-Filter collectionView cell
class WEVDiscoverFilterCollectionViewCell: UICollectionViewCell {
    struct Data {
        var style: Style
        var isSelected: Bool
        /// 样式
        enum Style {
            /// 所有频道
            case all
            /// 某个频道
            case channel(WEVChannel)
        }
    }

    var data: Data? {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    /// 全部
    private let allLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12), textColor: LJColor.gray, text: "ALL")
        return label
    }()
    
    /// 频道
    private let channelLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12))
        label.textAlignment = .center
        return label
    }()
    
    /// 频道图片
    private let channelImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private func initView() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderColor = LJColor.main.cgColor

        contentView.addSubview(allLabel)
        allLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        contentView.addSubview(channelLabel)
        channelLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.centerY).offset(12)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        
        contentView.addSubview(channelImageView)
        channelImageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(channelLabel.snp.top).offset(-6)
            make.size.equalTo(CGSize(width: 33, height: 33))
            make.centerX.equalToSuperview()
        }
    }
    
    private func updateView() {
        guard let data = data else { return }
        
        switch data.style {
        case .all:
            allLabel.isHidden = false
            channelLabel.isHidden = true
            channelImageView.isHidden = true
        case .channel(let channel):
            allLabel.isHidden = true
            channelLabel.isHidden = false
            channelImageView.isHidden = false
           
            channelLabel.text = channel.title
            channelImageView.image = data.isSelected ? channel.image : channel.unselectedImage
        }
        
        if data.isSelected {
            contentView.backgroundColor = .white
            contentView.layer.borderWidth = 1.5
            allLabel.textColor = LJColor.black
            channelLabel.textColor = LJColor.black
        }else {
            contentView.backgroundColor = LJColor.hex(0xEFF0F2)
            contentView.layer.borderWidth = 0
            allLabel.textColor = LJColor.gray
            channelLabel.textColor = LJColor.gray
        }
    }
}






