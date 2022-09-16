//
//  WEVEmptyHintView.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

class WEVEmptyHintView: UIView {
    
    struct Model {
        var title: String
        var image: String
        var desc: String?
        var descAttributedString: NSAttributedString?
    }
    
    public var model: Model? = nil {
        didSet {
            updateView()
        }
    }
    
    init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        initView()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    //MARK: UI
    private func initView() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview().offset(20)
        }
        
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(titleLabel.snp.top).offset(-30)
            make.centerX.equalToSuperview()
        }
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        updateView()
    }
    
    private func updateView() {
        guard let model = model else { return }
        titleLabel.text = model.title
        imageView.image = UIImage.init(named: model.image)
        if let descAttributedString = model.descAttributedString {
            descLabel.attributedText = descAttributedString
        }else {
            descLabel.text = model.desc
        }
    }
    

    /// 图片
    public let imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    /// 标题
    public let titleLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.medium(20))
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    /// 描述
    public let descLabel: UILabel = {
        let view = UILabel.lj.configure(font: LJFont.regular(16), textColor: LJColor.gray)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

}
