//
//  WEVWatchLaterTableViewCell.swift
//  _idx_SettingsUI_2FC3AEFB_ios_min13.0
//
//  Created by Apple on 01/11/22.
//

import UIKit
import TelegramPresentationData
import Kingfisher

class WEVWatchLaterTableViewCell: UITableViewCell {

    /// 图片
    let imgView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    let imgTypeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    /// 标题
    let titleLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(14), textColor: LJColor.black)
        label.numberOfLines = 2
        return label
    }()
    
    /// 标题
    let videoTypeLabel: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12), textColor: LJColor.black)
        label.numberOfLines = 1
        return label
    }()
    
    /// 标题
    let lblViews: UILabel = {
        let label = UILabel.lj.configure(font: LJFont.regular(12), textColor: LJColor.black)
        label.numberOfLines = 1
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

    func configureCell(watchLater: WatchLaterVideo, presentationData: PresentationData) {
        switch watchLater.videoType {
        case 1:
            titleLabel.text = watchLater.youTubeTitle ?? ""
            if let imageURL = watchLater.youTubeThumbnail {
                imgView.kf.setImage(with: URL(string: imageURL))
            }
            imgTypeView.image = UIImage(named: "segment_youtube")
            videoTypeLabel.text = "Youtube"
            self.setViews(count: watchLater.youTubeViewCounts)
        case 2:
            titleLabel.text = watchLater.clipTitle ?? ""
            if let imageURL = watchLater.clipThumbnailUrl {
                imgView.kf.setImage(with: URL(string: imageURL))
            }
            imgTypeView.image = UIImage(named: "segemnt_twitch")
            videoTypeLabel.text = "Twitch"
            self.setViews(count: watchLater.clipViewCount)
        case 3:
            titleLabel.text = watchLater.rumbleTitle ?? ""
            if let imageURL = watchLater.rumbleThumbnailUrl {
                imgView.kf.setImage(with: URL(string: imageURL))
            }
            imgTypeView.image = UIImage(named: "segment-rumble")
            videoTypeLabel.text = "Rumble"
            self.setViews(count: watchLater.rumbleViewerCount)
        default:
            titleLabel.text = ""
        }
        imgView.layer.cornerRadius = 5
        imgView.layer.masksToBounds = true
        titleLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
        videoTypeLabel.textColor = presentationData.theme.list.itemSecondaryTextColor
        lblViews.textColor = presentationData.theme.list.itemSecondaryTextColor
    }
    
    func configureCell(video: Item, presentationData: PresentationData) {
        //switch watchLater.videoType {
        //case 1:
            titleLabel.text = video.snippet.title
            //if let imageURL = video.snippet.thumbnails.maxres {
        imgView.kf.setImage(with: URL(string: video.snippet.thumbnails.maxres?.url ?? video.snippet.thumbnails.standard?.url ?? video.snippet.thumbnails.high.url))
            //}
            imgTypeView.image = UIImage(named: "segment_youtube")
            videoTypeLabel.text = "Youtube"
            //self.setViews(count: watchLater.youTubeViewCounts)
        /*case 2:
            titleLabel.text = watchLater.clipTitle ?? ""
            if let imageURL = watchLater.clipThumbnailUrl {
                imgView.kf.setImage(with: URL(string: imageURL))
            }
            imgTypeView.image = UIImage(named: "segemnt_twitch")
            videoTypeLabel.text = "Twitch"
            self.setViews(count: watchLater.clipViewCount)
        case 3:
            titleLabel.text = watchLater.rumbleTitle ?? ""
            if let imageURL = watchLater.rumbleThumbnailUrl {
                imgView.kf.setImage(with: URL(string: imageURL))
            }
            imgTypeView.image = UIImage(named: "segment-rumble")
            videoTypeLabel.text = "Rumble"
            self.setViews(count: watchLater.rumbleViewerCount)
        default:
            titleLabel.text = ""
        }*/
        imgView.layer.cornerRadius = 5
        imgView.layer.masksToBounds = true
        titleLabel.textColor = presentationData.theme.list.itemPrimaryTextColor
        videoTypeLabel.textColor = presentationData.theme.list.itemSecondaryTextColor
        lblViews.textColor = presentationData.theme.list.itemSecondaryTextColor
    }
    
    func setViews(count: Int64?) {
        var numberStr = "\(count ?? 0)"
        var unit = "views"
        if count == 1 {
            unit = "view"
        }
        if count ?? 0 >= 1000 {
            numberStr = String.init(format: "%.1fk", Double(count ?? 0) / 1000.0)
        }
        lblViews.text = "\(numberStr) \(unit)"
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
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(imgView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(imgView.snp.top)
        }
        
        contentView.addSubview(imgTypeView)
        imgTypeView.snp.makeConstraints { make in
            make.left.equalTo(imgView.snp.right).offset(15)
            make.width.height.equalTo(15)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        
        contentView.addSubview(videoTypeLabel)
        videoTypeLabel.snp.makeConstraints { make in
            make.left.equalTo(imgTypeView.snp.right).offset(5)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(imgTypeView.snp.top)
            make.bottom.equalTo(imgTypeView.snp.bottom)
        }
        
        contentView.addSubview(lblViews)
        lblViews.snp.makeConstraints { make in
            make.left.equalTo(imgView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(videoTypeLabel.snp.bottom).offset(2)
        }
    }
}
