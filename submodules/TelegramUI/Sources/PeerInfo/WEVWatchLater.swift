//
//  WEVWatchLater.swift
//  _idx_TelegramUI_Lib_001C0785_ios_min13.0
//
//  Created by Apple on 01/11/22.
//

import Foundation
struct NewWatchLaterVideo: Codable, Hashable {
  
    let videoType: Int
    let userId: Int64
    let twitchId: Int64?
    let youtubeId: String?
    let rumbleId: Int64?

    enum CodingKeys: String, CodingKey {
        case videoType = "video_type"
        case userId = "user_id"
        case twitchId = "twitch_id"
        case youtubeId = "youtube_id"
        case rumbleId = "rumble_id"
    }
}
// MARK: - Watach Later codeable
struct WatchLaterVideo: Codable {
    let id: Int64
    let userId: Int64
    let youtubeId: String?
    let rumbleId: Int64?
    let videoType: Int
    let twitchId: Int64?
    let clipId: String?
    let clipEmbedUrl: String?
    let clipTitle: String?
    let clipViewCount: Int64?
    let clipThumbnailUrl: String?
    let clipsUsername: String?
    let blob: String?
    var youTubeTitle: String?
    var youTubeDescription: String?
    var youTubeThumbnail: String?
    var youTubeViewCounts: Int64?
    let rumbleTitle: String?
    let rumbleThumbnailUrl: String?
    let rumbleEmbedUrl: String?
    let rumblem3u8: String?
    let rumbleViewerCount: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case blob
        case youTubeTitle
        case youTubeDescription
        case youTubeThumbnail
        case youTubeViewCounts
        case userId = "user_id"
        case youtubeId = "youtube_id"
        case rumbleId = "rumble_id"
        case videoType = "video_type"
        case twitchId = "twitch_id"
        case clipId = "clip_id"
        case clipEmbedUrl = "clip_embed_url"
        case clipTitle = "clip_title"
        case clipViewCount = "clip_view_count"
        case clipThumbnailUrl = "clip_thumbnail_url"
        case clipsUsername = "clips_username"
        case rumbleTitle = "rumble_title"
        case rumbleThumbnailUrl = "rumble_thumbnail_url"
        case rumbleEmbedUrl = "rumble_embed_url"
        case rumblem3u8 = "rumble_m3u8"
        case rumbleViewerCount = "rumble_viewer_count"
    }
        
}
let KeyForUserDefaults = "watchLaterList"

func saveWatchList(_ videowatchList: [WatchLaterVideo]) {
    let data = videowatchList.map { try? JSONEncoder().encode($0) }
    UserDefaults.standard.set(data, forKey: KeyForUserDefaults)
}

func fetchWatchList() -> [WatchLaterVideo] {
    guard let encodedData = UserDefaults.standard.array(forKey: KeyForUserDefaults) as? [Data] else {
        return []
    }
    return encodedData.map { try! JSONDecoder().decode(WatchLaterVideo.self, from: $0) }
}

