import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import AccountContext
import AlertUI
import PresentationDataUtils
import TelegramPermissions
import TelegramNotices
import ContactsPeerItem
import SearchUI
import TelegramPermissionsUI
import AppBundle
import StickerResources
import ContextUI
import QrCodeUI
import ContactsUI
//import SnapKit
import HandyJSON
import Alamofire
import Kingfisher // this has  a collision with swift influx operator


class WEVDiscoverCollectionViewCell: UICollectionViewCell {
    
    let liveLabel: UIView = {
        let view = UIView()
        view.backgroundColor = LJColor.hex(0xE84646)
        view.layer.cornerRadius = 10
        return view
    }()
    
    let point: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 3
        return view
    }()
    
    let wordLabel = UILabel.lj.configure(font: LJFont.regular(11), textColor: .white, text: "LIVE")
    
    public var model: WEVVideoModel? = nil {
        didSet {
            updateView()
        }
    }
    
    public var liveVideo: LiveVideos? = nil {
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
    }
    
    //MARK: UI
    
    /// 图片
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = LJColor.main
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        return view
    }()
    
    /// 频道图片
    public let channelImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    /// 频道名字
    public let channelNameLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.medium(12), textColor: .white)
        return label
    }()
    

    
    /// 观众数量
    public let amountLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(11), textColor: .white)
        label.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    public func fixConstraints() {
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        channelImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.width.height.equalTo(15)
        }
        
        channelNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(channelImageView.snp.right).offset(5)
            make.top.equalToSuperview().offset(9)
            make.centerY.equalTo(channelImageView)
            make.right.equalTo(liveLabel.snp.left).offset(-5)
        }
        
        
        liveLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalTo(channelNameLabel)
            make.size.equalTo(CGSize(width: 55, height: 20))
        }
        
        point.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(5)
            make.size.equalTo(CGSize(width: 6, height: 6))
            make.centerY.equalToSuperview()
        }
        
        wordLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.left.equalTo(point.snp.right).offset(7)
        }
        
        
        amountLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(18)
        }
        
    }
    
    /// 初始视图
    public func initView() {
        addSubview(imageView)
        let width = (LJScreen.width - 1 * 2 - 1) / 2
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: 97 * width / 186)
        
        addSubview(channelImageView)
        addSubview(channelNameLabel)
        
        addSubview(liveLabel)
        liveLabel.addSubview(point)
        liveLabel.addSubview(wordLabel)
        
        addSubview(amountLabel)
        
        //Apply autolayout constraint
        self.fixConstraints()
    }
    
    private func updateView() {
        guard let video = liveVideo else {return }
        
        //For Time being only youTube Video //slim_video have only youtube videos
        channelImageView.image = video.smallImage
        channelNameLabel.text = video.channelId

        
        if let n = video.viewerCount{
            var numberStr = "\(n)"
            var unit = "viewers"
            if n == 1 {
                unit = "viewer"
            }
            if n >= 1000 {
                numberStr = String.init(format: "%.1fk", Double(n) / 1000.0)
            }
            amountLabel.text = "  \(numberStr) \(unit)  "
            amountLabel.isHidden = false
        }else{
            amountLabel.isHidden = true
        }
      
        if let thumbnailUrl = video.videoThumbnailsUrl {
            imageView.kf.setImage(with: URL.init(string: thumbnailUrl), placeholder: nil)
        }
    }
}
