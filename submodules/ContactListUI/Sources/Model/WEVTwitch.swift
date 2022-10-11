//
//  WEVChannel.swift
//  _idx_ContactListUI_1D7887AF_ios_min13.0
//
//  Created by Apple on 15/09/22.
//

import Foundation
import UIKit

// MARK: - Crew
struct SlimTwitchVideo: Codable {
    let id: Int64
    let userId: String
    let userName: String
    let profileiImageUrl: String?
    let clipId: String?
    let clipEmbedUrl: String
    let clipTitle: String
    let clipViewCount: Int64
    let clipThumbnailUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case profileiImageUrl = "profile_image_url"
        case clipId = "clip_id"
        case clipEmbedUrl = "clip_embed_url"
        case clipTitle = "clip_title"
        case clipViewCount = "clip_view_count"
        case clipThumbnailUrl = "clip_thumbnail_url"
    }
}
