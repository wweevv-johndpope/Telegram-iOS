//
//  WEVResponse.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit
import HandyJSON

struct WEVVideoModel: HandyJSON {
    
    var channel: WEVChannel?
    var liveId = ""
    var id = ""
    var videoDescription = ""
    var videoId = ""
    var videoPublishedAt = ""
    var videoThumbnailsUrl = ""
    var videoTitle = ""
    var videoUrl = ""
    var wweevvVideoUrl = ""
    var views = 0
    var anchor: Anchor?
    var isSponsored = false
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.channel <-- "channelId"
        mapper <<< self.anchor <-- "livePojo"
        mapper <<< self.isSponsored <-- "sponsorFlag"
    }


    /// 主播
    struct Anchor: HandyJSON {
        var channel: WEVChannel?
        var liveDescription = ""
        var id = ""
        var liveHeadUrl = ""
        var liveId = ""
        var liveName = ""
        var regionCode = ""
        /// 是否已订阅
        var isSubscribed = false
        
        mutating func mapping(mapper: HelpingMapper) {
            mapper <<<
                self.channel <-- "channelId"
            
            mapper <<<
                self.isSubscribed <-- "substrFlag"
        }
        
    }
    
    
}
