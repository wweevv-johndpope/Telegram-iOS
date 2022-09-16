//
//  WEVResponse.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

struct WEVResponse: Decodable{
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
