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
import SnapKit
import HandyJSON
import Alamofire
import Kingfisher // this has  a collision with swift influx operator 


class WEVDiscoverCollectionViewCell: UICollectionViewCell {
    
    let liveLabel = UIView()
    let point = UIView()
    let wordLabel = UILabel.lj.configure(font: LJFont.regular(11), textColor: .white, text: "LIVE")
    
    public var model: WEVVideoModel? = nil {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        updateView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
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

    public func fixConstraints(){
        
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        channelImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        point.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(9)
            make.size.equalTo(CGSize(width: 6, height: 6))
            make.centerY.equalToSuperview()
        }
        
        wordLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.left.equalTo(point.snp.right).offset(7)
        }
        channelNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(channelImageView.snp.right).offset(5)
            make.top.equalToSuperview().offset(9)
            make.centerY.equalTo(channelImageView)
            make.right.equalTo(liveLabel.snp.left).offset(-5)
        }
        
        liveLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 55, height: 20))
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
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        imageView.snp.makeConstraints { (make) in
//            make.edges.equalToSuperview()
//        }
        
        addSubview(channelImageView)
//        channelImageView.snp.makeConstraints { (make) in
//            make.left.equalToSuperview().offset(8)
//            make.size.equalTo(CGSize(width: 15, height: 15))
//        }
        
      
        addSubview(liveLabel)
        liveLabel.backgroundColor = LJColor.hex(0xE84646)
        liveLabel.layer.cornerRadius = 10
       
        point.backgroundColor = .white
        point.layer.cornerRadius = 3
        liveLabel.addSubview(point)
//        point.snp.makeConstraints { (make) in
//            make.left.equalToSuperview().offset(9)
//            make.size.equalTo(CGSize(width: 6, height: 6))
//            make.centerY.equalToSuperview()
//        }
        liveLabel.addSubview(wordLabel)
//        label.snp.makeConstraints { (make) in
//            make.right.equalToSuperview().offset(-10)
//            make.centerY.equalToSuperview()
//            make.left.equalTo(point.snp.right).offset(7)
//        }
        
//        liveLabel.snp.makeConstraints { (make) in
//            make.right.equalToSuperview().offset(-8)
//            make.top.equalToSuperview().offset(8)
//            make.size.equalTo(CGSize(width: 55, height: 20))
//        }
        
        addSubview(channelNameLabel)
//        channelNameLabel.snp.makeConstraints { (make) in
//            make.left.equalTo(channelImageView.snp.right).offset(5)
//            make.top.equalToSuperview().offset(9)
//            make.centerY.equalTo(channelImageView)
//            make.right.equalTo(liveLabel.snp.left).offset(-5)
//        }
//
//
        addSubview(amountLabel)
//        amountLabel.snp.makeConstraints { (make) in
//            make.left.equalToSuperview().offset(8)
//            make.bottom.equalToSuperview().offset(-8)
//            make.height.equalTo(18)
//        }
    }
    
    private func updateView() {
        guard let model = model else { return }
//        channelImageView.image = model.channel?.smallImage
        channelNameLabel.text = "test"// model.channel?.title
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
    
}


enum WEVChannel: String, HandyJSONEnum, CaseIterable {
    
    case youtube = "YouTube"
    
    case twitch = "Twitch"
    
    case facebook = "Facebook"

//    Facebook Twitch YouTube LinkedIn Periscope
    public var title: String {
        get {
            switch self {
            case .youtube:
                return "YouTube"
            case .twitch:
                return "Twitch"
            case .facebook:
                return "Facebook"
            }
        }
    }
    
    public var image: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube"
            case .twitch:
                name = "channel_twitch"
            case .facebook:
                name = "channel_facebook"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }
    
    public var smallImage: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube_small"
            case .twitch:
                name = "channel_twitch_small"
            case .facebook:
                name = "channel_facebook_small"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }

    public var unselectedImage: UIImage {
        get {
            var name = ""
            switch self {
            case .youtube:
                name = "channel_youtube_unselected"
            case .twitch:
                name = "channel_twitch_unselected"
            case .facebook:
                name = "channel_facebook_unselected"
            }
            return UIImage.init(named: name) ?? UIImage()
        }
    }


    
}

struct WEVResponse :Decodable{
    var code = 0
    var data:WEVResponseData?
    var message = "";
    var time = 0;
  
}

struct WEVResponseData:Decodable{
    var keyWord = "";
    var nextPageToken = ""
    var liveVideoPojoList:[WEVVideoModel]
    var offset:Int?
}

struct LivePojo:Decodable{
    var id :String?
    var channelId:String?
    var liveId:String?
    var liveHeadUrl:String?
    var liveName:String?
    var liveDescription:String?
    var regionCode:String?
    var viewCount:Int?
    var substrFlag:Bool?
    
}

// TODO - move this

//Swift.DecodingError.keyNotFound(CodingKeys(stringValue: "isSponsored", intValue: nil), Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "data", intValue: nil), CodingKeys(stringValue: "liveVideoPojoList", intValue: nil), _JSONKey(stringValue: "Index 0", intValue: 0)], debugDescription: "No value associated with key CodingKeys(stringValue: \"isSponsored\", intValue: nil) (\"isSponsored\").", underlyingError: nil)))))

struct WEVVideoModel :Decodable{

    

    var id = ""
    var channelId = ""
    var liveId = ""
    var videoDescription = ""
    var videoId = ""
    var videoPublishedAt = ""
    var videoThumbnailsUrl = ""
    var videoTitle = ""
    var videoUrl = ""
    var wweevvVideoUrl = ""
    var views = 0
    var isSponsored:String?
    var livePojo:LivePojo

    
    enum CodingKeys: String, CodingKey {

        case liveId
        case id
        case videoDescription
        case videoId
        case videoPublishedAt
        case videoThumbnailsUrl
        case videoTitle
        case videoUrl
        case wweevvVideoUrl
        case views
        case isSponsored = "sponsorFlag"
        case livePojo
    }

}




struct LJColor {
    
    static let main = Self.hex(0x128A84)
    
    static let black = Self.hex(0x353535)
   
    static let gray = Self.hex(0x868686)
    
    /// 分割线的灰色
    static let lineGray = Self.hex(0xE6E6E6)

    /// 灰色背景
    static let grayBg = Self.hex(0xE6E6E6)

    static func hex(_ hex: UInt, _ alpha: CGFloat = 1) -> UIColor {
        UIColor.lj.hex(hex, alpha)
    }
}



struct LJScreen {
    //屏幕大小
    static let height: CGFloat = UIScreen.main.bounds.size.height
    static let width: CGFloat = UIScreen.main.bounds.size.width
    
    //iPhoneX的比例
    static let scaleWidthOfIX = UIScreen.main.bounds.size.width / 375.0
    static let scaleHeightOfIX = UIScreen.main.bounds.size.height / 812.0
    static let scaleHeightLessOfIX = scaleHeightOfIX > 1 ? 1 : scaleHeightOfIX
    static let scaleWidthLessOfIX = scaleWidthOfIX > 1 ? 1 : scaleWidthOfIX


    // iphoneX
    static let navigationBarHeight: CGFloat =  isiPhoneXMore() ? 88.0 : 64.0
    static let safeAreaBottomHeight: CGFloat =  isiPhoneXMore() ? 34.0 : 0
    static let statusBarHeight: CGFloat = isiPhoneXMore() ? 44.0 : 20.0
    static let tabBarHeight: CGFloat = isiPhoneXMore() ? 83.0 : 49.0

    // iphoneX
    static func isiPhoneXMore() -> Bool {
        let isMore:Bool = true
//        if #available(iOS 11.0, *) {
//            isMore = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > CGFloat(0)
//        }
        return isMore
    }

}

