//
//  WEVWatchLaterTableViewCell.swift
//  _idx_SettingsUI_2FC3AEFB_ios_min13.0
//
//  Created by Apple on 01/11/22.
//

import UIKit

class WEVWatchLaterTableViewCell: UITableViewCell {

    /// 图片
    let imgView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    /// 标题
    let titleLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(14), textColor: LJColor.black)
        label.numberOfLines = 2
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initStyleView()
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initStyleView()
        initView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func initStyleView() {
        selectionStyle = .none
        backgroundColor = .clear
    }


    private func initView() {
        contentView.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(80)
            make.width.equalTo(120)
        }
                
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(imgView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(imgView.snp.top)
        }
        
    }
}
