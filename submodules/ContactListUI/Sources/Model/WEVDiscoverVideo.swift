//
//  WEVDiscoverVideo.swift
//  _idx_AccountContext_8C6B681C_ios_min13.0
//
//  Created by Apple on 14/09/22.
//

import Foundation
import UIKit

struct LiveVideos: Codable {
    let id: String
    let channelId: String
    let liveId : String
    let videoId: String
    let videoPublishedAt: String?
    let videoTitle: String
    let videoDescription: String
    let videoThumbnailsUrl: String?
    let createtime: Int?
    let updatetime: Int?
    let openflag: Int?
    let refreshtime: Int?
    let opentime: String?
    let viewerCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case liveId = "live_id"
        case videoId = "video_id"
        case videoPublishedAt = "video_published_at"
        case videoTitle = "video_title"
        case videoDescription = "video_description"
        case videoThumbnailsUrl = "video_thumbnails_url"
        case createtime = "create_time"
        case updatetime = "update_time"
        case openflag = "open_flag"
        case refreshtime = "refresh_time"
        case opentime = "open_time"
        case viewerCount = "viewer_count"
    }
}

extension WEVVideoModel {
    public var videlLiveUrl: String? {
        get {
            var url:String? = nil
            switch channel {
            case .youtube:
                url = "https://www.youtube.com/watch?v=\(videoId)"
            case .twitch:
                url = "https://www.twitch.tv/\(videoId)"
            case .facebook:
                //url = "https://www.youtube.com/watch?v=\(videoId)"
                url = nil
            default:
                return nil
            }
            return url
        }
    }

}
enum channelType: String, CaseIterable {
    case youtube = "YouTube"
    case twitch = "Twitch"
    case facebook = "Facebook"
}
struct Columns {
    static let liveVideos = "id,channel_id,live_id,video_id,video_published_at,video_title,video_description,video_thumbnails_url,create_time,update_time,open_flag,refresh_time,open_time,viewer_count"
}
