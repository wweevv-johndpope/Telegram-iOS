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
        view.layer.cornerRadius = 7.5
        return view
    }()
    
    let point: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 3
        return view
    }()
    
    let wordLabel = UILabel.lj.configure(font: LJFont.regular(9), textColor: .white, text: "LIVE")
    
    public var model: WEVVideoModel? = nil {
        didSet {
            updateView()
        }
    }
    
    public var ytModel: YoutubeVideo? = nil {
        didSet {
            updateYoutubeView()
        }
    }
    
    public var twitchModel: SlimTwitchVideo? = nil {
        didSet {
            updateTwitchView()
        }
    }
    
    public var rumbleModel: RumbleVideo? = nil {
        didSet {
            updateRumbleView()
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
            make.top.equalToSuperview().offset(10)
            make.centerY.equalTo(channelImageView)
            make.right.equalTo(liveLabel.snp.left).offset(-5)
        }
        
        
        liveLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalTo(channelNameLabel)
            make.size.equalTo(CGSize(width: 55, height: 15))
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
        guard let model = model else { return }
        channelImageView.image = model.channel?.smallImage
        channelNameLabel.text = model.channel?.title
        liveLabel.isHidden = false
        var numberStr = "\(model.views)"
        var unit = "viewers"
        if model.views == 1 {
            unit = "viewer"
        }
        if model.views >= 1000 {
            numberStr = String.init(format: "%.1fk", Double(model.views) / 1000.0)
        }
        amountLabel.text = "  \(numberStr) \(unit)  "
        
        imageView.kf.setImage(with: URL.init(string: model.videoThumbnailsUrl), placeholder: nil)
    }
    
    private func updateYoutubeView() {
        guard let model = ytModel else { return }
        channelImageView.image = WEVChannel.youtube.smallImage
        channelNameLabel.text = model.title
        liveLabel.isHidden = false
        var numberStr = "\(model.viewCount ?? 0)"
        var unit = "viewers"
        if model.viewCount == 1 {
            unit = "viewer"
        }
        if model.viewCount ?? 0 >= 1000 {
            numberStr = String.init(format: "%.1fk", Double(model.viewCount ?? 0) / 1000.0)
        }
        amountLabel.text = "  \(numberStr) \(unit)  "
        if model.thumbnails.count > 0 {
            imageView.kf.setImage(with: URL.init(string: model.thumbnails[0]?.url ?? ""), placeholder: nil)
        }
    }
    
    private func updateTwitchView() {
        guard let model = twitchModel else { return }
        channelImageView.image = WEVChannel.twitch.smallImage
        channelNameLabel.text = model.clipTitle
        liveLabel.isHidden = false
        var numberStr = "\(model.clipViewCount)"
        var unit = "viewers"
        if model.clipViewCount == 1 {
            unit = "viewer"
        }
        if model.clipViewCount >= 1000 {
            numberStr = String.init(format: "%.1fk", Double(model.clipViewCount) / 1000.0)
        }
        amountLabel.text = "  \(numberStr) \(unit)  "
        
        imageView.kf.setImage(with: URL.init(string: model.clipThumbnailUrl), placeholder: nil)
    }
    
    private func updateRumbleView() {
        guard let model = rumbleModel else { return }
        channelImageView.image = WEVChannel.rumble.smallImage
        channelNameLabel.text = model.title
        liveLabel.isHidden = false
        var numberStr = "\(model.viewerCount)"
        var unit = "viewers"
        if model.viewerCount == 1 {
            unit = "viewer"
        }
        if model.viewerCount >= 1000 {
            numberStr = String.init(format: "%.1fk", Double(model.viewerCount) / 1000.0)
        }
        amountLabel.text = "  \(numberStr) \(unit)  "
        
        imageView.kf.setImage(with: URL.init(string: model.thumbnailUrl), placeholder: nil)
    }
}
